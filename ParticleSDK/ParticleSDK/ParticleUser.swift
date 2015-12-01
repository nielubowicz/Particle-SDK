//
//  ParticleUser.swift
//  Particle-SDK
//
//  Created by Chris Nielubowicz on 11/17/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

import Foundation

struct ParticleUser {
    var emailAddress : String = ""
    var password : String = ""
    
    init(email: String, password: String) {
        self.emailAddress = email
        self.password = password
    }
}