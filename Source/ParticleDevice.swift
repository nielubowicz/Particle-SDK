//
//  ParticleDevice.swift
//  Particle-SDK
//
//  Created by Chris Nielubowicz on 11/17/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

import Foundation
import Alamofire

enum DeviceParameterNames : String {
    case id
    case name
    case last_app
    case connected
    case last_ip_address
    case last_heard
}

public class ParticleDevice : NSObject {

    public var id : String = ""
    public var deviceName : String = ""
    public var last_app: String = ""
    public var connected: Bool = false
    public var last_ip_address: String = ""
    public var last_heard: String = ""
    
    init(deviceJSON: Dictionary<String,AnyObject>) {
        if let id = deviceJSON[DeviceParameterNames.id.rawValue] as? String {
            self.id = id
        }
        if let deviceName = deviceJSON[DeviceParameterNames.name.rawValue] as? String {
            self.deviceName = deviceName
        }
        if let last_app = deviceJSON[DeviceParameterNames.last_app.rawValue] as? String {
            self.last_app = last_app
        }
        if let connected = deviceJSON[DeviceParameterNames.connected.rawValue] as? NSNumber {
            self.connected = connected.boolValue
        }
        if let last_ip_address = deviceJSON[DeviceParameterNames.last_ip_address.rawValue] as? String {
            self.last_ip_address = last_ip_address
        }
        if let last_heard = deviceJSON[DeviceParameterNames.last_heard.rawValue] as? String {
            self.last_heard = last_heard
        }
    }

    override public var description : String {
        return "(\(id)): \(deviceName)"
    }
}

// MARK: Variable / Function Access
extension ParticleDevice {
    
    func getVariable(withName: String, completion:( (AnyObject?, NSError?) -> Void)) {
        guard Particle.sharedInstance.OAuthToken != nil else { return }
        
        let variableURL = url(ParticleEndpoints.Variable(deviceName: deviceName, authToken: Particle.sharedInstance.OAuthToken!, variableName: withName))
        Alamofire.request(.GET, variableURL)
            .responseJSON { response in
                if (response.result.error != nil) {
                    completion(nil, response.result.error)
                    return;
                }
                if let JSON = response.result.value as? Dictionary<String, AnyObject> {
                    completion(JSON[ResponseParameterNames.result.rawValue], nil)
                } else {
                    let particleError = ParticleErrors.VariableResponse(deviceName: self.deviceName, variableName: withName)
                    completion(nil, particleError.error)
                }
        }
    }
    
    func callFunction(named: String, arguments: Array<AnyObject>?, completion:( (NSNumber?, NSError?) -> Void)) {
        guard Particle.sharedInstance.OAuthToken != nil else { return }
        
        var arguments: Dictionary<String,AnyObject>?
        if let args = arguments {
            let argsValue = args.map({ "\($0)"}).joinWithSeparator(",")

            if argsValue.characters.count > 63 {
                let particleError = ParticleErrors.MaximumArgLengthExceeded()
                completion(nil, particleError.error)
                return
            }
            
            arguments = ["args": argsValue]
        }
        
        let variableURL = url(ParticleEndpoints.Function(deviceName: deviceName, authToken: Particle.sharedInstance.OAuthToken!, functionName: named))
        Alamofire.request(.POST, variableURL, parameters: arguments)
            .authenticate(user: Particle.sharedInstance.OAuthToken!, password: "")
            .responseJSON { response in
                if (response.result.error != nil) {
                    completion(nil, response.result.error)
                    return
                }
                if let JSON = response.result.value as? Dictionary<String, AnyObject> {
                    if let connected = JSON[ResponseParameterNames.connected.rawValue] as? NSNumber {
                        if (connected == false) {
                            let particleError = ParticleErrors.DeviceNotConnected(deviceName: self.deviceName)
                            completion(nil, particleError.error)
                            return
                        }
                    }
                    completion(JSON[ResponseParameterNames.return_value.rawValue] as? NSNumber, nil)
                } else {
                    let particleError = ParticleErrors.FunctionResponse(deviceName: self.deviceName, functionName: named)
                    completion(nil, particleError.error)
                }
        }
    }
}

// MARK: Housekeeping
extension ParticleDevice {

    func refresh(completion:( (NSError?) -> Void)) {
        Particle.sharedInstance.getDevice(self.id) { (device, error) -> Void in
            if let error = error  {
                completion(error)
            }
            
            guard let device = device else {
                completion(ParticleErrors.DeviceFailedToRefresh(deviceName: self.deviceName).error)
                return
            }
            
            var propertyNames = Set<NSString>()
            var outCount: UInt32 = 0
            
            let properties = class_copyPropertyList(NSClassFromString("Particle-SDK.ParticleDevice"), &outCount)
            
            for i in 0...Int(outCount) {
                let property = properties[i]
                if let propertyName = NSString(CString: property_getName(property), encoding:NSStringEncodingConversionOptions.AllowLossy.rawValue) {
                    propertyNames.insert(propertyName)
                }
            }
            free(properties)
            
            for property in propertyNames {
                let p = String(property)
                let value = device.valueForKey(p)
                self.setValue(value, forKey: p)
            }
        }
    }
//
//    /**
//    *  Remove device from current logged in user account
//    *
//    *  @param completion Completion block called when function completes with NSError object in case of an error or nil if success.
//    */
//    -(void)unclaim:(void(^)(NSError* error))completion;
//    
//
//    /**
//    *  Rename device
//    *
//    *  @param newName      New device name
//    *  @param completion   Completion block called when function completes with NSError object in case of an error or nil if success.
//    */
//    -(void)rename:(NSString *)newName completion:(void(^)(NSError* error))completion;
//    
}

// MARK: Event Handling
//    /*
//    -(void)addEventHandler:(NSString *)eventName handler:(void(^)(void))handler;
//    -(void)removeEventHandler:(NSString *)eventName;
//    */
//
//


// MARK: Compilation / Flashing
//    /**
//    *  Flash files to device
//    *
//    *  @param filesDict    files dictionary in the following format: @{@"filename.bin" : <NSData>, ...} - that is a NSString filename as key and NSData blob as value. More than one file can be flashed. Data is alway binary.
//    *  @param completion   Completion block called when function completes with NSError object in case of an error or nil if success. NSError.localized descripion will contain a detailed error report in case of a
//    */
//    -(void)flashFiles:(NSDictionary *)filesDict completion:(void(^)(NSError* error))completion; //@{@"<filename>" : NSData, ...}
//    /*
//    -(void)compileAndFlash:(NSString *)sourceCode completion:(void(^)(NSError* error))completion;
//    -(void)flash:(NSData *)binary completion:(void(^)(NSError* error))completion;
//    */
//
//    /**
//    *  Flash known firmware images to device
//    *
//    *  @param knownAppName    NSString of known app name. Currently @"tinker" is supported.
//    *  @param completion      Completion block called when function completes with NSError object in case of an error or nil if success. NSError.localized descripion will contain a detailed error report in case of a
//    */
//    -(void)flashKnownApp:(NSString *)knownAppName completion:(void (^)(NSError *))completion; // knownAppName = @"tinker", @"blinky", ... see http://docs.
//    
//    //-(void)compileAndFlashFiles:(NSDictionary *)filesDict completion:(void(^)(NSError* error))completion; //@{@"<filename>" : @"<file contents>"}
//    //-(void)complileFiles:(NSDictionary *)filesDict completion:(void(^)(NSData *resultBinary, NSError* error))completion; //@{@"<filename>" : @"<file contents>"}
//