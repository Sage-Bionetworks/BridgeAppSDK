//
//  SBABridgeInfo.swift
//  BridgeAppSDK
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import BridgeSDK

public protocol SBABridgeInfo: class {
    
    /**
     * Study identifier used to setup the study with Bridge
     */
    var studyIdentifier: String! { get }
    
    /**
     * Environment to load
     */
    var environment: SBBEnvironment! { get }
    
    /**
     * App store link for this application. By default, this returns the value pulled from the main bundle
     */
    var appStoreLinkURL: NSURL! { get }
    
    /**
     * Email format to use for registration via externalId should be in the form
     * "name+%@@company.org"
     */
    var emailFormatForRegistrationViaExternalId: String? { get }
    
    /**
     * Password format for use for registration via externalId. (optional)
     */
    var passwordFormatForRegistrationViaExternalId: String? { get }
    
    /**
     * Data group for the test user. (optional)
     */
    var testUserDataGroup: String? { get }
}

public class SBABridgeInfoPList : NSObject, SBABridgeInfo {
    
    public var studyIdentifier: String!
    public var environment: SBBEnvironment! = .Prod
    
    var plist: NSDictionary!

    convenience override init() {
        self.init(name: "BridgeInfo")!
    }
    
    init?(name: String) {
        super.init()
        guard let plist = SBAResourceFinder().plistNamed(name) else {
            assertionFailure("\(name) plist file not found in the resource bundle")
            return nil
        }
        guard let studyIdentifier = plist["studyIdentifier"] as? String else {
            assertionFailure("\(name) plist file does not define the 'studyIdentifier'")
            return nil
        }
        self.studyIdentifier = studyIdentifier
        self.plist = plist
    }
    
    public var appStoreLinkURL: NSURL! {
        guard let appStoreLinkURLString = self.plist["appStoreLinkURL"] as? String,
            let url = NSURL(string: appStoreLinkURLString)
        else {
            return NSBundle.mainBundle().appStoreLinkURL()
        }
        return url
    }
    
    public var emailFormatForRegistrationViaExternalId: String? {
        return self.plist["emailFormatForRegistrationViaExternalId"] as? String
    }
    
    public var passwordFormatForRegistrationViaExternalId: String? {
        return self.plist["passwordFormatForRegistrationViaExternalId"] as? String
    }
    
    public var testUserDataGroup: String? {
        return self.plist["testUserDataGroup"] as? String
    }

    
}

