//
//  SBAJSONObject.swift
//  BridgeAppSDK
//
//  Created by Erin Mounts on 5/13/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import Foundation

extension Dictionary: SBAJSONObject {
    func jsonObject() -> AnyObject {
        return (self as NSDictionary).jsonObject()
    }
}