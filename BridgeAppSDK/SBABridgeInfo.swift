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

/**
 This protocol is used as the mapping for information used to customize the study.
 */
@objc
public protocol SBABridgeInfo: class {
    
    /**
     Study identifier used to setup the study with Bridge
     */
    var studyIdentifier: String! { get }
    
    /**
     If using BridgeSDK's built-in caching, number of days ahead to cache
     */
    var cacheDaysAhead: Int { get }
    
    /**
     If using BridgeSDK's built-in caching, number of days behind to cache
     */
    var cacheDaysBehind: Int { get }
    
    /**
     Environment to load
     */
    var environment: SBBEnvironment { get }
    
    /**
     App store link for this application. By default, this returns the value pulled from the main bundle
     */
    var appStoreLinkURLString: String? { get }
    
    /**
     Email to use for registration or login via externalId
     */
    var emailForLoginViaExternalId: String? { get }
    
    /**
     Password format for use for registration or login via externalId. (optional)
     */
    var passwordFormatForLoginViaExternalId: String? { get }
    
    /**
     Data group for the test user. (optional)
     */
    var testUserDataGroup: String? { get }
    
    /**
     Mapping of schema identifier and associated info for creating an archive
     */
    var schemaMap: [NSDictionary]? { get }
    
    /**
     Mapping of task identifier and associated info for creating a task
     */
    var taskMap: [NSDictionary]? { get }
    
    /**
     Name of .pem certificate file to use for uploading to Bridge (without the .pem extension)
     */
    var certificateName: String? { get }
    
    /**
     URL for the news feed for this app.
     */
    var newsfeedURLString: String? { get }

    /**
     The Logo image to use for this app.
     */
    var logoImageName: String? { get }
    
    /**
     A custom url for launching an app update.
     */
    var appUpdateURLString: String? { get }
    
    /**
     By default, check the user email for test data group assignment. If disabled, 
     do not check for a text user.
    */
    var disableTestUserCheck: Bool { get }
    
    /**
     Array of objects that can be converted into `SBAPermissionObjectType` objects.
    */
    var permissionTypeItems: [Any]? { get }
    
    /**
     Keychain service name.
     */
    var keychainService: String? { get }
    
    /**
    Keychain access group name.
    */
    var keychainAccessGroup: String? { get }
    
    /**
     App group identifier used for the suite name of NSUserDefaults (if provided).
    */
    var appGroupIdentifier: String? { get }
}

/**
 This is an implementation of the SBABridgeInfo protocol that uses a dictionary to 
 define the values required by the BridgeInfo protocol.
 */
public final class SBABridgeInfoPList : NSObject, SBABridgeInfo {
    
    static let shared = SBABridgeInfoPList()
    
    public var studyIdentifier: String {
        return _studyIdentifier
    }
    private let _studyIdentifier: String
    
    public var cacheDaysAhead: Int = 0
    public var cacheDaysBehind: Int = 0
    public var environment: SBBEnvironment = .prod
    
    private let plist: [String: Any]

    public convenience override init() {
        var plist = SBAResourceFinder.shared.plist(forResource: "BridgeInfo")!
        if let additionalInfo = SBAResourceFinder.shared.plist(forResource: "BridgeInfo-private") {
            plist = plist.merge(from: additionalInfo)
        }
        let studyIdentifier = plist["studyIdentifier"] as! String
        self.init(studyIdentifier: studyIdentifier, plist: plist)
    }
    
    public init(studyIdentifier:String, plist: [String: Any]) {
        
        // Set study identifier and plist pointers
        self._studyIdentifier = studyIdentifier
        self.plist = plist
        super.init()
        
        // Setup cache days using either days ahead and behind or else using 
        // default values for days ahead and behind
        let cacheDaysAhead = plist["cacheDaysAhead"] as? Int
        let cacheDaysBehind = plist["cacheDaysBehind"] as? Int
        if (cacheDaysAhead != nil) || (cacheDaysBehind != nil) {
            self.cacheDaysAhead = cacheDaysAhead ?? SBBDefaultCacheDaysAhead
            self.cacheDaysBehind = cacheDaysBehind ?? SBBDefaultCacheDaysBehind
        }
        else if let useCache = plist["useCache"] as? Bool , useCache {
            // If this plist has the useCache key then set the ahead and behind to default
            self.cacheDaysAhead = SBBDefaultCacheDaysAhead
            self.cacheDaysBehind = SBBDefaultCacheDaysBehind
        }
    }
    
    public var appStoreLinkURLString: String? {
        return  self.plist["appStoreLinkURL"] as? String
    }
    
    public var emailForLoginViaExternalId: String? {
        return self.plist["emailForLoginViaExternalId"] as? String
    }
    
    public var passwordFormatForLoginViaExternalId: String? {
        return self.plist["passwordFormatForLoginViaExternalId"] as? String
    }
    
    public var testUserDataGroup: String? {
        return self.plist["testUserDataGroup"] as? String
    }
    
    public var taskMap: [NSDictionary]? {
        return self.plist["taskMapping"] as? [NSDictionary]
    }
    
    public var schemaMap: [NSDictionary]? {
        return self.plist["schemaMapping"] as? [NSDictionary]
    }
    
    public var certificateName: String? {
        return self.plist["certificateName"] as? String
    }
    
    public var newsfeedURLString: String? {
        return self.plist["newsfeedURL"] as? String
    }
    
    public var logoImageName: String? {
        return self.plist["logoImageName"] as? String
    }
    
    public var appUpdateURLString: String? {
        return self.plist["appUpdateURL"] as? String
    }
    
    public var disableTestUserCheck: Bool {
        return self.plist["disableTestUserCheck"] as? Bool ?? false
    }
    
    public var permissionTypeItems: [Any]? {
        return self.plist["permissionTypes"] as? [Any]
    }
    
    public var keychainService: String? {
        return self.plist["keychainService"] as? String
    }
    
    public var keychainAccessGroup: String? {
        return self.plist["keychainAccessGroup"] as? String
    }
    
    public var appGroupIdentifier: String? {
        return self.plist["appGroupIdentifier"] as? String
    }

}

extension SBABridgeInfo {
    
    public var emailFormatForLoginViaExternalId: String? {
        guard let email = self.emailForLoginViaExternalId, let range = email.range(of: "@") else {
            return nil
        }
        return email.replacingCharacters(in: range, with: "+%@@")
    }
    
    public var appStoreLinkURL: URL! {
        guard let appStoreLinkURLString = self.appStoreLinkURLString,
            let url = URL(string: appStoreLinkURLString) else {
                return Bundle.main.appStoreLinkURL()
        }
        return url
    }
        
    public func schemaReferenceWithIdentifier(_ schemaIdentifier: String) -> SBASchemaReference? {
        return self.schemaMap?.find({ $0.schemaIdentifier == schemaIdentifier})
    }
    
    public func taskReferenceWithIdentifier(_ taskIdentifier: String) -> SBATaskReference? {
        return self.taskMap?.find({ $0.taskIdentifier == taskIdentifier})
    }
    
    public func taskReferenceForSchedule(_ schedule: SBBScheduledActivity) -> SBATaskReference? {
        if let taskId = schedule.taskIdentifier {
            return taskReferenceWithIdentifier(taskId)
        }
        else {
            return schedule.activity.survey
        }
    }
    
    public var newsfeedURL: URL? {
        guard let urlString = newsfeedURLString else { return nil }
        return URL(string: urlString)
    }
    
    public var logoImage: UIImage? {
        guard let imageName = logoImageName else { return nil }
        return UIImage(named: imageName)
    }
    
    public var appUpdateURL: URL {
        guard let urlString = appUpdateURLString, let url = URL(string: urlString) else {
            return Bundle.main.appStoreLinkURL()
        }
        return url
    }
    
    public var userDefaults: UserDefaults {
        return UserDefaults(suiteName: self.appGroupIdentifier) ?? UserDefaults.standard
    }
}

