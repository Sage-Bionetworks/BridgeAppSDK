//
//  SBAResourceFinder.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 2/18/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import UIKit

class SBAResourceFinder: NSObject {
    
    func sharedResourceDelegate() -> SBABridgeAppSDKDelegate? {
        return UIApplication.sharedApplication().delegate as? SBABridgeAppSDKDelegate
    }
    
    func pathForResource(resourceNamed: String, ofType: String) -> String? {
        if let resourceDelegate = self.sharedResourceDelegate(),
            let path = resourceDelegate.pathForResource(resourceNamed, ofType: ofType) {
                return path
        }
        else if let path = NSBundle.mainBundle().pathForResource(resourceNamed, ofType: ofType) {
            return path
        }
        else if let path = NSBundle(forClass: self.classForCoder).pathForResource(resourceNamed, ofType: ofType) {
            return path
        }
        return nil
    }
    
    func imageNamed(named: String) -> UIImage? {
        if let resourceDelegate = self.sharedResourceDelegate(),
            let image = UIImage(named: named, inBundle: resourceDelegate.resourceBundle(), compatibleWithTraitCollection: nil) {
            return image
        }
        else if let image = UIImage(named: named) {
            return image
        }
        else if let image = UIImage(named: named, inBundle: NSBundle(forClass: self.classForCoder), compatibleWithTraitCollection: nil) {
            return image
        }
        return nil;
    }
    
    func dataNamed(resourceNamed: String, ofType: String) -> NSData? {
        if let path = self.pathForResource(resourceNamed, ofType: ofType) {
            return NSData(contentsOfFile: path)
        }
        return nil
    }
    
    func htmlNamed(resourceNamed: String) -> String? {
        if let data = self.dataNamed(resourceNamed, ofType: "html") {
            return String(data: data, encoding: NSUTF8StringEncoding)
        }
        return nil
    }
    
    func jsonNamed(resourceNamed: String) -> NSDictionary? {
        if let data = self.dataNamed(resourceNamed, ofType: "json"),
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers){
                return json as? NSDictionary
        }
        return nil
    }
    
    func urlNamed(resourceNamed: String, withExtension: String) -> NSURL? {
        if let resourceDelegate = self.sharedResourceDelegate(),
            let url = resourceDelegate.resourceBundle().URLForResource(resourceNamed, withExtension: withExtension)
            where url.checkResourceIsReachableAndReturnError(nil) {
                return url
        }
        else if let url = NSBundle.mainBundle().URLForResource(resourceNamed, withExtension: withExtension)
            where url.checkResourceIsReachableAndReturnError(nil) {
            return url
        }
        else if let url = NSBundle(forClass: self.classForCoder).URLForResource(resourceNamed, withExtension: withExtension)
            where url.checkResourceIsReachableAndReturnError(nil) {
                return url
        }
        return nil;
    }

}
