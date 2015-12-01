//
//  ParticleDeviceTests.swift
//  Particle-SDK
//
//  Created by Chris Nielubowicz on 11/20/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

import XCTest

class ParticleDeviceTests: XCTestCase {

    let deviceName = "TestDevice"
    let deviceID = "1234"
    let lastApp = "Particle-SDK"
    let connected = NSNumber(bool: true)
    let ipAddress = "127.0.0.1"
    let lastHeard = ""
    
    func testFullDeviceData() {
        let deviceDictionary = [
            DeviceParameterNames.id.rawValue: deviceID,
            DeviceParameterNames.name.rawValue: deviceName,
            DeviceParameterNames.last_app.rawValue: lastApp,
            DeviceParameterNames.connected.rawValue: connected,
            DeviceParameterNames.last_ip_address.rawValue: ipAddress,
            DeviceParameterNames.last_heard.rawValue: lastHeard
        ]
        let device = ParticleDevice(deviceJSON: deviceDictionary)
        XCTAssertEqual(device.deviceName, deviceName)
        XCTAssertEqual(device.id, deviceID)
        XCTAssertEqual(device.last_app, lastApp)
        XCTAssertEqual(device.last_heard, lastHeard)
        XCTAssertEqual(device.last_ip_address, ipAddress)
        XCTAssertEqual(device.connected, connected.boolValue)
    }
    
    func testPartialDeviceData() {
        let deviceDictionary = [
            DeviceParameterNames.id.rawValue: deviceID,
            DeviceParameterNames.name.rawValue: deviceName,
            DeviceParameterNames.connected.rawValue: connected,
            DeviceParameterNames.last_ip_address.rawValue: ipAddress
            ]
        let device = ParticleDevice(deviceJSON: deviceDictionary)
        XCTAssertEqual(device.deviceName, deviceName)
        XCTAssertEqual(device.id, deviceID)
        XCTAssertEqual(device.last_app, "")
        XCTAssertEqual(device.last_heard, "")
        XCTAssertEqual(device.last_ip_address, ipAddress)
        XCTAssertEqual(device.connected, connected.boolValue)
    }
    
    func testEmptyDeviceData() {
        let deviceDictionary = Dictionary<String,AnyObject>()
        let device = ParticleDevice(deviceJSON: deviceDictionary)
        XCTAssertEqual(device.deviceName, "")
        XCTAssertEqual(device.id, "")
        XCTAssertEqual(device.last_app, "")
        XCTAssertEqual(device.last_heard, "")
        XCTAssertEqual(device.last_ip_address, "")
        XCTAssertEqual(device.connected, false)
    }
}
