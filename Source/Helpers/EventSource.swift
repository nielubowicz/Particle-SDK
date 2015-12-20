//
//  EventSource.swift
//  ParticleSDK
//
//  Created by Chris Nielubowicz on 12/17/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//  
//  **********************************************************************
//  Original Header:
//
//  EventSource.m
//  EventSource
//
//  Created by Neil on 25/07/2013.
//  Copyright (c) 2013 Neil Cowburn. All rights reserved,
//  Heavily modified to match Spark event structure by Ido Kleinman, 2015
//  Original codebase:
//  https://github.com/neilco/EventSource
//  **********************************************************************

import Foundation

enum EventState: Int {
    case Connecting = 0,
    Open,
    Closed
}

class Event: NSObject, NSCopying {
    
    public static let MessageEvent = "message"
    public static let ErrorEvent = "error"
    public static let OpenEvent = "open"
    
    var name: String?
    var data: NSData?
    var readyState: EventState = .Connecting
    var error: NSError
    
    override init() {
        
    }

    
    override func description() -> String {
        let state: String
        switch self.readyState {
        case .Connecting:
            state = "CONNECTING"
            break
        case .Open:
            state = "OPEN"
            break
        case .Closed:
            state = "CLOSED"
            break
        }
        
        return "<Event: readyState: \(state), event: \(event), data: \(data)>"
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = self.dynamicType.initialize() as! Event
        copy.name = self.name
        copy.data = self.data
        copy.readyState = self.readyState
        copy.error = self.error
        return copy
    }
}

typealias EventSourceEventHandler = (event:Event) -> Void

class EventSource: NSObject {

    static let ES_RETRY_INTERVAL = 1.0

    static let ESKeyValueDelimiter = ": "
    static let ESEventSeparatorLFLF = "\n\n"
    static let ESEventSeparatorCRCR = "\r\r"
    static let ESEventSeparatorCRLFCRLF = "\r\n\r\n"
    static let ESEventKeyValuePairSeparator = "\n"
    static let ESEventDataKey = "data"
    static let ESEventEventKey = "event"
    
    private var wasClosed = false

    var eventURL: NSURL
    var eventSource: NSURLConnection?
    lazy var listeners: NSMutableDictionary = NSMutableDictionary()
    var timeoutInterval: NSTimeInterval
    var retryInterval: NSTimeInterval
    var lastEventID: AnyObject?
    var queue: dispatch_queue_t?
    var accessToken: String
    lazy var event: Event = Event()

    class func eventSource(withURL: NSURL, timeoutInterval: NSTimeInterval, queue:dispatch_queue_t, accessToken: String)->EventSource{
        return EventSource(withURL: withURL, timeoutInterval: timeoutInterval, queue: queue, accessToken: accessToken)
    }


    init(withURL:NSURL, timeoutInterval: NSTimeInterval, queue:dispatch_queue_t, accessToken: String) {
        eventURL = withURL
        self.timeoutInterval = timeoutInterval
        retryInterval = EventSource.ES_RETRY_INTERVAL
        self.queue = queue
        self.accessToken = accessToken
        let popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryInterval * NSEC_PER_SEC))
        dispatch_after(popTime, queue, { () -> Void in self.open() })
    }

    func addEventListener(eventName:String, handler:EventSourceEventHandler) {
        guard self.listeners[eventName] != nil else { self.listeners[eventName] = () }
        
        if let listeners = self.listeners[eventName] {
            listeners.addObject(handler)
        }
    }

    func removeEventListener(eventName:String, handler:EventSourceEventHandler) {
        guard self.listeners[eventName] != nil else { return }
        
        if let listeners = self.listeners[eventName] {
            listeners.removeObject(handler)
        }
    }
    
    func onMessage(handler:EventSourceEventHandler) {
        addEventListener(Event.MessageEvent, handler: handler)
    }
    
    func onError(handler:EventSourceEventHandler) {
        addEventListener(Event.ErrorEvent, handler: handler)
    }
    
    func onOpen(handler:EventSourceEventHandler) {
        addEventListener(Event.OpenEvent, handler: handler)
    }
    
    func open() {
        wasClosed = false
        let request = NSMutableURLRequest(URL: eventURL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: timeoutInterval)
        if let lastEventID = lastEventID {
            request.setValue(lastEventID, forHTTPHeaderField: "Last-Event-ID")
        }
        
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.HTTPMethod = "GET"
        
        eventSource = NSURLConnection(request: request, delegate: self, startImmediately: true)
        
        if NSThread.isMainThread() == false {
            CFRunLoopRun()
        }
    }

    func close() {
        wasClosed = true
        eventSource?.cancel()
        queue = nil
    }
}

extension EventSource: NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        let httpResponse = response as NSHTTPURLResponse
        guard httpResponse.statusCode == 200
            else { print("Error opening event stream, code \(httpResponse.statusCode)"); return }
        
        let e = Event()
        e.readyState = EventState.Open
        
        listeners[Event.OpenEvent].forEach({ dispatch_async(queue, { (handler) -> Void in
            handler(e)
        })})
        
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        let e = Event()
        e.readyState = EventState.Closed
        e.error = error
        
        listeners[Event.ErrorEvent].forEach({ dispatch_async(queue, { (handler) -> Void in
            handler(e)
        })})
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryInterval * NSEC_PER_SEC))
        dispatch_after(popTime, queue, { () -> Void in self.open() })
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        let eventString = NSString(data: data, encoding: NSUTF8StringEncoding)?
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        let components = eventString?.componentsSeparatedByString(EventSource.ESEventKeyValuePairSeparator)
        event.readyState = EventState.Open
        
        components?.forEach({ (component) -> () in
            guard component.characters.isEmpty == false else { continue }
            
            let index = component.rangeOfString(EventSource.ESKeyValueDelimiter)?.location
            guard index != NSNotFound && index != component.characters.count - 2 else { continue }
            
            let key = component.substringToIndex(index)
            let value = component.substringFromIndex(index + EventSource.ESKeyValueDelimiter.characters.count)
            
            if key == EventSource.ESEventEventKey {
                event.name = value
            } else if key == EventSource.ESEventDataKey {
                event.data = value.dataUsingEncoding(NSUTF8StringEncoding)
            }
            
            guard let name = event.name, data = event.data else { continue }
            
            let sendEvent = event.copy()
            listeners[Event.MessageEvent].forEach({ (handler) -> () in
                handler(sendEvent)
            })
            event = Event()
        })
    }

    func connectionDidFinishLoading(connection: NSURLConnection) {
        guard wasClosed == false else { return }
        
        e = Event()
        e.readyState = EventState.Closed
        e.error = NSError(domain: "", code: e.readyState, userInfo: [NSLocalizedDescriptionKey: "Connection with the event source was closed" ])
        
        listeners[Event.ErrorEvent].forEach({ (handler) -> () in
            handler(e)
        })
        
        open()
    }
}