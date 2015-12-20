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
    lazy var listeners: [String:Array<EventSourceEventHandler>] = [String:Array<EventSourceEventHandler>]()
    var timeoutInterval: NSTimeInterval
    var retryInterval: NSTimeInterval = EventSource.ES_RETRY_INTERVAL
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
        self.queue = queue
        self.accessToken = accessToken
        super.init()
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, (Int64)(retryInterval * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, queue, { () -> Void in self.open() })
    }

    func addEventListener(eventName:String, handler:EventSourceEventHandler) {
        if self.listeners[eventName] == nil {
            self.listeners[eventName] = Array<EventSourceEventHandler>()
        }
        
        if var listeners = self.listeners[eventName] {
            listeners.append(handler)
        }
    }

    func removeEventListener(eventName:String, handler:EventSourceEventHandler) {
        guard self.listeners[eventName] != nil else { return }
        
        if let listeners = self.listeners[eventName] {
            self.listeners[eventName] = listeners.filter({ $0 != handler })
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
            request.setValue(lastEventID as? String, forHTTPHeaderField: "Last-Event-ID")
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
        let httpResponse = response as! NSHTTPURLResponse
        guard httpResponse.statusCode == 200
            else { print("Error opening event stream, code \(httpResponse.statusCode)"); return }
        
        let e = Event()
        e.readyState = EventState.Open
        
        listeners[Event.OpenEvent]?.forEach({ handler in
            dispatch_async(queue!, { () -> Void in
                handler.eventHandler(event: e)
            })})
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        let e = Event()
        e.readyState = EventState.Closed
        e.error = error

        listeners[Event.ErrorEvent]?.forEach({ handler in
            dispatch_async(queue!, { () -> Void in
                handler.eventHandler(event: e)
            })})
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, (Int64)(retryInterval * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, queue!, { () -> Void in self.open() })
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        let eventString = NSString(data: data, encoding: NSUTF8StringEncoding)?
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        let components = eventString?.componentsSeparatedByString(EventSource.ESEventKeyValuePairSeparator)
        event.readyState = EventState.Open
        
        for component in components! {
            if component.characters.isEmpty == true { break }
            
            let range = component.rangeOfString(EventSource.ESKeyValueDelimiter)!
            let index = range.startIndex.distanceTo(range.endIndex)
            guard index != NSNotFound && index != component.characters.count - 2 else { continue }
            
            let key = component.substringToIndex(range.endIndex)
            let value = component.substringFromIndex(range.endIndex.advancedBy(EventSource.ESKeyValueDelimiter.characters.count))
            
            if key == EventSource.ESEventEventKey {
                event.name = value
            } else if key == EventSource.ESEventDataKey {
                event.data = value.dataUsingEncoding(NSUTF8StringEncoding)
            }
            
            guard event.name != nil && event.data != nil else { continue }
            
            if let sendEvent = event.copy() as? Event {
                listeners[Event.MessageEvent]?.forEach({ handler in
                    handler.eventHandler(event:sendEvent)
                })
            }
            event = Event()
        }
    }

    func connectionDidFinishLoading(connection: NSURLConnection) {
        guard wasClosed == false else { return }
        
        let e = Event()
        e.readyState = EventState.Closed
        e.error = NSError(domain: "", code: e.readyState.rawValue, userInfo: [NSLocalizedDescriptionKey: "Connection with the event source was closed" ])
        
        listeners[Event.ErrorEvent]?.forEach({ handler in
            handler.eventHandler(event:e)
        })
        
        open()
    }
}