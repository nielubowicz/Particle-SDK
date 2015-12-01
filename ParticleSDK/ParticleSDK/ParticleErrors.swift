//
//  ParticleErrors.swift
//  Particle-SDK
//
//  Created by Chris Nielubowicz on 11/20/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

import Foundation

let ParticleErrorDomain = "ParticleSDKErrorDomain"
let MAX_SPARK_FUNCTION_ARG_LENGTH = 63

protocol Description {
    var localizedDescription: String { get }
}

protocol ErrorCode {
    var errorCode: Int { get }
    var error: NSError { get }
}

enum ParticleErrors {
    case DeviceResponse(deviceID: String)
    case VariableResponse(deviceName: String, variableName: String)
    case FunctionResponse(deviceName: String, functionName: String)
    case DeviceNotConnected(deviceName: String)
    case DeviceFailedToRefresh(deviceName: String)
    case MaximumArgLengthExceeded()
}


extension ParticleErrors : Description, ErrorCode {
    
    var localizedDescription: String {
        switch self {
        case .DeviceResponse(let deviceID):
            return "Could not parse JSON data for device: \(deviceID)"
        case .VariableResponse(let deviceName, let variableName):
            return "Could not parse JSON data from device: \(deviceName) with variable named: \(variableName)"
        case .FunctionResponse(let deviceName, let functionName):
            return "Could not parse JSON data from device: \(deviceName) with function named: \(functionName)"
        case .DeviceNotConnected(let deviceName):
            return "Device \(deviceName) is not connected"
        case .DeviceFailedToRefresh(let deviceName):
            return "Device \(deviceName) failed to refresh"
        case .MaximumArgLengthExceeded():
            return "Maximum argument length cannot exceed \(MAX_SPARK_FUNCTION_ARG_LENGTH)"
        }
        
    }
    
    var errorCode: Int {
        switch self {
        case .DeviceResponse(_):
            return 1
        case .VariableResponse(_, _):
            return 2
        case .FunctionResponse(_, _):
            return 3
        case .DeviceNotConnected(_):
            return 1001
        case .DeviceFailedToRefresh(_):
            return 1009
        case .MaximumArgLengthExceeded():
            return 1000
        }
    }
    
    var error: NSError {
        return NSError(domain: ParticleErrorDomain, code: self.errorCode, userInfo: [ NSLocalizedDescriptionKey: self.localizedDescription])
    }
}