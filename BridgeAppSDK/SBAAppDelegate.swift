//
//  SBAAppDelegate.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 3/22/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import UIKit
import BridgeSDK

@UIApplicationMain
public class SBAAppDelegate: UIResponder, UIApplicationDelegate, SBABridgeAppSDKDelegate, SBBBridgeAppDelegate  {
    
    public var window: UIWindow?
    
    public func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // Override point for customization before application launch.
        
        self.initializeBridgeServerConnection()
        
        return true
    }

    
    // MARK: Default setup
    
    public func initializeBridgeServerConnection()
    {
        // TODO:
        //    [BridgeSDK setupWithStudy:self.initializationOptions[kAppPrefixKey] environment:(SBBEnvironment)[self.initializationOptions[kBridgeEnvironmentKey] integerValue]];
    }
    
    
    // MARK: SBABridgeAppSDKDelegate
    
    public func resourceBundle() -> NSBundle! {
        return NSBundle.mainBundle()
    }
    
    public func pathForResource(resourceName: String!, ofType resourceType: String!) -> String! {
        return self.resourceBundle().pathForResource(resourceName, ofType: resourceType)
    }
}
