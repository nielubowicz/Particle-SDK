//
//  ParticleURLs.swift
//  IPMenuletExample
//
//  Created by Chris Nielubowicz on 11/10/15.
//
//

import Foundation

enum ParticleEndpoints {
    case Login()
    case Devices(authToken:String)
    case Device(authToken:String, deviceID:String)
    case Variable(deviceName:String, authToken:String, variableName:String)
    case Function(deviceName:String, authToken:String, functionName:String)
    case SubscribeToEvents(authToken:String)
}

extension ParticleEndpoints : Path {
    var path: String {
        switch self {
        case .Login():
            return "/oauth/token"
        case .Devices(_):
            return "/v1/devices/"
        case .Device(_, let deviceID):
            return "/v1/devices/\(deviceID)"
        case .Variable(let deviceName, _, let variableName):
            return "/v1/devices/\(deviceName)/\(variableName)"
        case .Function(let deviceName, _, let functionName):
            return "/v1/devices/\(deviceName)/\(functionName)"
        case .SubscribeToEvents(_):
            return "/v1/events/occupancy-change"
        }
    }
    
    var query: String? {
        switch self {
        case .Login():
            return nil
        case .Devices(let authToken):
            return "access_token=\(authToken)"
        case .Device(let authToken,_):
            return "access_token=\(authToken)"
        case .Variable(_, let authToken, _):
            return "access_token=\(authToken)"
        case .Function(_, let authToken, _):
            return "access_token=\(authToken)"
        case .SubscribeToEvents(let authToken):
            return "access_token=\(authToken)"
        }
    }
}

extension ParticleEndpoints : BaseURL {
    var baseURL: NSURL { return (NSURL(string:"https://api.particle.io"))! }
}

