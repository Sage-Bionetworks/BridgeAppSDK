//
//  SBATrackedDataStore.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 9/22/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import Foundation

extension SBATrackedDataStore {
    
    public static var shared: SBATrackedDataStore {
        return __shared()
    }
}
