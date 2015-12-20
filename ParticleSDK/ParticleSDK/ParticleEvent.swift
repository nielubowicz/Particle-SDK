//
//  ParticleEvent.swift
//  ParticleSDK
//
//  Created by Chris Nielubowicz on 12/17/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

import Foundation

public class ParticleEvent: NSObject {
    var deviceID: String
    var data: String
    var event: String
    var ttl: Int
    var time: NSDate
    
    init(eventDictionary: [String: AnyObject?]) {
        deviceID = eventDictionary["coreid"] as! String
        data = eventDictionary["data"] as! String
        event = eventDictionary["event"] as! String
        ttl =  eventDictionary["ttl"] as! Int
        let dateString = eventDictionary["published_at"] as! String
        time = Particle.dateFormatter.dateFromString(dateString)!
    }
    
    override public var description: String {
        return "<Event: \(event), DeviceID: \(deviceID), Data: \(data), Time: \(time), TTL: \(ttl)"
    }
}