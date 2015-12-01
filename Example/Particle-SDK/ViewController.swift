//
//  ViewController.swift
//  Particle-SDK
//
//  Created by Chris Nielubowicz on 11/30/2015.
//  Copyright (c) 2015 Chris Nielubowicz. All rights reserved.
//

import UIKit
import Particle_SDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Particle.sharedInstance.getDevices { (devices, error) -> Void in
            for device in devices {
                NSLog("found: \(device.deviceName)")
            }
        }
    }

}

