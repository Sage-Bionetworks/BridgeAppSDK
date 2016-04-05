//
//  ResourceTestCase.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 4/6/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import XCTest

class ResourceTestCase: XCTestCase {
    
    func jsonForResource(resourceName: String) -> NSDictionary? {
    
        guard let path = NSBundle(forClass: self.classForCoder).pathForResource(resourceName, ofType:"json"),
            let jsonData = NSData(contentsOfFile: path) else {
                XCTAssert(false, "Resource not found: \(resourceName)")
                return nil
        }
        
        do {
            guard let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions(rawValue: 0)) as? NSDictionary else {
                XCTAssert(false, "Resource not an NSDictionary: \(resourceName)")
                return nil
            }
            return json
        }
        catch let err as NSError {
            XCTAssert(false, "Failed to parse json. \(err)")
        }
        
        return nil
    }
    
}
