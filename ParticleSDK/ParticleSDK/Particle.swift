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
    
    static let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return dateFormatter
    }()
    
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
    
    // MARK: Events
    
    public typealias ParticleEventHandler = (event: ParticleEvent?, error: ErrorType?) -> Void

    public func subscribeToEvent(withURL: NSURL, eventHandler:ParticleEventHandler) -> AnyObject? {
        guard OAuthToken != nil else { eventHandler(event: nil, error: ParticleErrors.NoAccessToken()); return nil }
        let source = EventSource.eventSource(withURL,
            timeoutInterval:30,
            queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
            accessToken:OAuthToken!)
        
        let handler = EventSourceEventHandler { (event) -> Void in
            guard event.error == nil else { eventHandler(event: nil, error: event.error); return }
            
            var handlerError: NSError?
            var eventDict = [String: AnyObject?]()
            if let data = event.data {
                do {
                    eventDict = try NSJSONSerialization.JSONObjectWithData(data, options:[NSJSONReadingOptions.MutableContainers]) as! Dictionary<String,AnyObject?>
                } catch {
                    handlerError = NSError(domain: ParticleErrorDomain, code: 5, userInfo: nil)
                }
            }
            
            guard handlerError == nil && eventDict.isEmpty == false else { eventHandler(event: nil, error: handlerError); return }
            if let name = event.name {
                eventDict["event"] = name
            }
            
            let particleEvent = ParticleEvent(eventDictionary: eventDict)
            eventHandler(event: particleEvent, error: nil)
        }
        
        source.onMessage(handler)
        return handler.UUID
    }
    
//    -(id)subscribeToAllEventsWithPrefix:(NSString *)eventNamePrefix handler:(SparkEventHandler)eventHandler;
//    /**
//    *  Subscribe to all events, public and private, published by devices one owns
//    *
//    *  @param eventHandler     Event handler function that accepts the event payload dictionary and an NSError object in case of an error
//    *  @param eventNamePrefix  Filter only events that match name eventNamePrefix, for exact match pass whole string, if nil/empty string is passed any event will trigger eventHandler
//    *  @return eventListenerID function will return an id type object as the eventListener registration unique ID - keep and pass this object to the unsubscribe method in order to remove this event listener
//    */
//    -(id)subscribeToMyDevicesEventsWithPrefix:(NSString *)eventNamePrefix handler:(SparkEventHandler)eventHandler;
//    
//    /**
//    *  Subscribe to events from one specific device. If the API user has the device claimed, then she will receive all events, public and private, published by that device.
//    *  If the API user does not own the device she will only receive public events.
//    *
//    *  @param eventNamePrefix  Filter only events that match name eventNamePrefix, for exact match pass whole string, if nil/empty string is passed any event will trigger eventHandler
//    *  @param deviceID         Specific device ID. If user has this device claimed the private & public events will be received, otherwise public events only are received.
//    *  @param eventHandler     Event handler function that accepts the event payload dictionary and an NSError object in case of an error
//    *  @return eventListenerID function will return an id type object as the eventListener registration unique ID - keep and pass this object to the unsubscribe method in order to remove this event listener
//    */
//    -(id)subscribeToDeviceEventsWithPrefix:(NSString *)eventNamePrefix deviceID:(NSString *)deviceID handler:(SparkEventHandler)eventHandler;
//    
//    /**
//    *  Unsubscribe from event/events.
//    *
//    *  @param eventListenerID The eventListener registration unique ID returned by the subscribe method which you want to cancel
//    */
//    -(void)unsubscribeFromEventWithID:(id)eventListenerID;

}