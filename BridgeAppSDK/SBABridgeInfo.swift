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
import ResearchUXFactory

/**
 This protocol is used as the mapping for information used to customize the study.
 */
@objc
public protocol SBABridgeInfo: SBASharedAppInfo, SBBBridgeInfoProtocol {
    
    /**
     App store link for this application. By default, this returns the value pulled from the main bundle
     */
    var appStoreLinkURLString: String? { get }
    
    /**
     Privacy policy link for this application. By default, this returns the value pulled from the main bundle
     */
    var privacyPolicyLinkURLString: String? { get }

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
     URL for the news feed for this app.
     */
    var newsfeedURLString: String? { get }
    
    /**
     A custom url for launching an app update.
     */
    var appUpdateURLString: String? { get }
    
    /**
     By default, check the user email for test data group assignment. If disabled, 
     do not check for a text user.
    */
    var disableTestUserCheck: Bool { get }
}

/**
 This is an implementation of the SBABridgeInfo protocol that uses a dictionary to 
 define the values required by the BridgeInfo protocol.
 */
extension SBAInfoManager: SBABridgeInfo {
        
    public var studyIdentifier: String {
        return self.plist["studyIdentifier"] as! String
    }
    
    public var environment: SBBEnvironment {
        guard let rawValue = self.plist["environment"] as? NSNumber,
            let environment = SBBEnvironment(rawValue: rawValue.intValue)
        else {
            return .prod
        }
        return environment
    }
    
    public var cacheDaysAhead: Int {
        let (cacheDaysAhead, _) = parseCacheDays()
        return cacheDaysAhead
    }
    
    public var cacheDaysBehind: Int {
        let (_, cacheDaysBehind) = parseCacheDays()
        return cacheDaysBehind
    }
    
    fileprivate func parseCacheDays() -> (cacheDaysAhead: Int, cacheDaysBehind: Int) {
        // Setup cache days using either days ahead and behind or else using 
        // default values for days ahead and behind
        let cacheDaysAhead = self.plist["cacheDaysAhead"] as? Int
        let cacheDaysBehind = self.plist["cacheDaysBehind"] as? Int
        if (cacheDaysAhead != nil) || (cacheDaysBehind != nil) {
            return (cacheDaysAhead ?? SBBDefaultCacheDaysAhead, cacheDaysBehind ?? SBBDefaultCacheDaysBehind)
        }
        else if let useCache = self.plist["useCache"] as? Bool, useCache {
            // If this plist has the useCache key then set the ahead and behind to default
            return (SBBDefaultCacheDaysAhead, SBBDefaultCacheDaysBehind)
        }
        return (0,0)
    }
    
    public var appStoreLinkURLString: String? {
        return  self.plist["appStoreLinkURL"] as? String
    }

    public var privacyPolicyLinkURLString: String? {
        return  self.plist["privacyPolicyLinkURL"] as? String
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
    
    public var appUpdateURLString: String? {
        return self.plist["appUpdateURL"] as? String
    }
    
    public var disableTestUserCheck: Bool {
        return self.plist["disableTestUserCheck"] as? Bool ?? false
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
    
    public var appUpdateURL: URL {
        guard let urlString = appUpdateURLString, let url = URL(string: urlString) else {
            return Bundle.main.appStoreLinkURL()
        }
        return url
    }
}

