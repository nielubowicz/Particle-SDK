//
//  Event.swift
//  ParticleSDK
//
//  Created by Chris Nielubowicz on 12/17/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

import Foundation


enum EventState: Int {
    case Connecting = 0,
    Open,
    Closed
}

public class Event: NSObject, NSCopying {
    
    public static let MessageEvent = "message"
    public static let ErrorEvent = "error"
    public static let OpenEvent = "open"
    
    var name: String?
    var data: NSData?
    var readyState: EventState = .Connecting
    var error: NSError?
    
    override init() {
        
    }
    
    override public var description: String {
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
        
        return "<Event: event: \(name), readyState: \(state), data: \(data)>"
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = Event()
        copy.name = self.name
        copy.data = self.data
        copy.readyState = self.readyState
        copy.error = self.error
        return copy
    }
}


typealias EventHandler = (event:Event) -> Void

public func ==(lhs: EventSourceEventHandler, rhs: EventSourceEventHandler) -> Bool {
    return lhs.UUID == rhs.UUID
}

public func !=(lhs: EventSourceEventHandler, rhs: EventSourceEventHandler) -> Bool {
    return lhs.UUID != rhs.UUID
}

public class EventSourceEventHandler: Equatable {
    
    var eventHandler: EventHandler
    var UUID: NSUUID = NSUUID()
    
    init(eventHandler: EventHandler) {
        self.eventHandler = eventHandler
    }
    
}