//
//  Particle.swift
//  IPMenuletExample
//
//  Created by Chris Nielubowicz on 11/10/15.
//
//

import Foundation
import Alamofire

enum ParameterNames: String {
    case grant_type
    case username
    case password
    case client_id
    case client_secret
}

enum ResponseParameterNames: String {
    case access_token
    case result
    case return_value
    case connected
}

public class Particle {
    
    public static let sharedInstance = Particle()
    
    public var OAuthToken : String?
    private var user : ParticleUser?
    public var OAuthClientId : String?
    public var OAuthClientSecret : String?

    // MARK : Onboarding
    public func login(withUser: String, password: String, completion: (error: NSError?) -> Void) {
        
        if (self.OAuthClientId == nil) {
            self.OAuthClientId = "particle"
        }
        if (self.OAuthClientSecret == nil) {
            self.OAuthClientSecret = "particle"
        }
        
        let loginURL = url(ParticleEndpoints.Login())
        let parameters = [ParameterNames.grant_type.rawValue: "password",
            ParameterNames.username.rawValue: withUser,
            ParameterNames.password.rawValue: password,
            ParameterNames.client_id.rawValue: self.OAuthClientId!, ParameterNames.client_secret.rawValue: self.OAuthClientSecret!]

        Alamofire.request(.POST, loginURL, parameters: parameters)
            .authenticate(user: self.OAuthClientId!, password: self.OAuthClientSecret!)
            .responseJSON { response in
                if let JSON = response.result.value as? Dictionary<String,AnyObject> {
                    self.OAuthToken = JSON[ResponseParameterNames.access_token.rawValue] as? String
                    self.user = ParticleUser(email: withUser, password: password)
                }
                completion(error: response.result.error)
        }
    }
    
    //-(void)signupWithUser:(NSString *)user password:(NSString *)password completion:(void (^)(NSError *error))completion;
    //-(void)signupWithCustomer:(NSString *)email password:(NSString *)password orgSlug:(NSString *)orgSlug completion:(void (^)(NSError *))completion;
    public func logout() {
        self.OAuthToken = nil
        self.user = nil
    }

    // MARK : Devices
    public func getDevices(completion:([ParticleDevice], error: NSError?) -> Void) {
        guard self.OAuthToken != nil else { return }
        
        let devicesURL = url(ParticleEndpoints.Devices(authToken: self.OAuthToken!))
        Alamofire.request(.GET, devicesURL)
            .responseJSON { (response) -> Void in
                if let JSON = response.result.value as? Array<Dictionary<String, AnyObject>> {
                    var devices = [ParticleDevice]()
                    for deviceJSON in JSON {
                        devices.append(ParticleDevice(deviceJSON: deviceJSON))
                    }
                    completion(devices, error: response.result.error)
                }
        }
    }
    
    public func getDevice(deviceID: String, completion: (ParticleDevice?, NSError?) -> Void) {
        guard self.OAuthToken != nil else { return }
        
        let deviceURL = url(ParticleEndpoints.Device(authToken: self.OAuthToken!, deviceID: deviceID))
        Alamofire.request(.GET, deviceURL)
            .responseJSON { response in
                if (response.result.error != nil) {
                    completion(nil, response.result.error)
                }
                if let JSON = response.result.value as? Dictionary<String, AnyObject> {
                    let device = ParticleDevice(deviceJSON: JSON)
                    completion(device, nil)
                } else {
                    let error = ParticleErrors.DeviceResponse(deviceID: deviceID)
                    completion(nil, NSError(domain: ParticleErrorDomain, code: error.errorCode, userInfo: [ NSLocalizedDescriptionKey : error.localizedDescription ]))
                }
        }
    }
    //// Not available yet
    ////-(void)publishEvent:(NSString *)eventName data:(NSData *)data;
    //-(void)claimDevice:(NSString *)deviceID completion:(void(^)(NSError *))completion;
    //-(void)generateClaimCode:(void(^)(NSString *claimCode, NSArray *userClaimedDeviceIDs, NSError *error))completion;
    //-(void)generateClaimCodeForOrganization:(NSString *)orgSlug andProduct:(NSString *)productSlug withActivationCode:(NSString *)activationCode completion:(void(^)(NSString *claimCode, NSArray *userClaimedDeviceIDs, NSError *error))completion;
}