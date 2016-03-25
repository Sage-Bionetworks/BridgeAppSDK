//
//  SBAUser.swift
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
import ResearchKit

public class SBAUser: NSObject, SBAUserWrapper {
    
    let lockQueue = dispatch_queue_create("com.sba.UserLockQueue", nil)

    public func logout() {
        self.sessionToken = nil
        dispatch_sync(lockQueue) {
            self.resetUserDefaults()
            self.resetKeychain()
        }
    }
    
    // --------------------------------------------------
    // MARK: Memory-only storage
    // --------------------------------------------------
    
    public var sessionToken: String?
    
    
    // --------------------------------------------------
    // MARK: Keychain storage
    // --------------------------------------------------
    
    let kNamePropertyKey = "name"
    let kEmailPropertyKey = "email"
    let kPasswordPropertyKey = "password"
    let kSubpopulationGuidKey = "SavedSubpopulationGuid"
    let kConsentSignatureKey = "ConsentSignature"
    let kUserIdKey = "userId"
    
    public var name: String? {
        get {
            return getKeychainObject(kNamePropertyKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue, key: kNamePropertyKey)
        }
    }
    
    public var email: String? {
        get {
            return getKeychainObject(kEmailPropertyKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue, key: kEmailPropertyKey)
        }
    }
    
    public var userId: String? {
        get {
            return getKeychainObject(kUserIdKey) as? String ?? self.email?.sha1_hashed()
        }
        set (newValue) {
            setKeychainObject(newValue, key: kUserIdKey)
        }
    }
    
    public var password: String? {
        get {
            return getKeychainObject(kPasswordPropertyKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue, key: kPasswordPropertyKey)
        }
    }
    
    public var subpopulationGuid: String? {
        get {
            // if no subpopulationGuid found for user, return study identifier instead
            return getKeychainObject(kSubpopulationGuidKey) as? String ?? gSBBAppStudy
        }
        set (newValue) {
            setKeychainObject(newValue, key: kSubpopulationGuidKey)
        }
    }

    /**
     * Consent signature should be stored in keychain.
     */
    public var consentSignature: SBAConsentSignatureWrapper? {
        get {
            return getKeychainObject(kConsentSignatureKey) as? SBAConsentSignatureWrapper
        }
        set (newValue) {
            setKeychainObject(newValue, key: kConsentSignatureKey)
        }
    }
    
    func getKeychainObject(key: String) -> NSSecureCoding? {
        var obj: NSSecureCoding?
        dispatch_sync(lockQueue) {
            var err: NSError?
            obj = ORKKeychainWrapper.objectForKey(key, error: &err)
            if let error = err {
                print("Error accessing keychain: \(error)")
            }
        }
        return obj
    }
    
    func setKeychainObject(object: NSSecureCoding?, key: String) {
        dispatch_async(lockQueue) {
            do {
                if let obj = object {
                    try ORKKeychainWrapper.setObject(obj, forKey: key)
                }
                else {
                    try ORKKeychainWrapper.removeObjectForKey(key)
                }
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func resetKeychain() {
        do {
            try ORKKeychainWrapper.resetKeychain()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // --------------------------------------------------
    // MARK: NSUserDefaults storage
    // --------------------------------------------------
    
    let kRegisteredKey = "SignedUp"
    let kLoginVerifiedKey = "SignedIn"
    let kConsentVerifiedKey = "consentVerified"
    let kSavedDataGroupsKey = "SavedDataGroups"
    let kStudyPausedKey = "studyPaused"
    let kDataSharingScopeKey = "dataSharingScope"
    
    public var hasRegistered: Bool {
        get {
            return syncBoolForKey(kRegisteredKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kRegisteredKey)
        }
    }

    public var loginVerified: Bool {
        get {
            return syncBoolForKey(kLoginVerifiedKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kLoginVerifiedKey)
        }
    }

    public var consentVerified: Bool {
        get {
            return syncBoolForKey(kConsentVerifiedKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kConsentVerifiedKey)
        }
    }
    
    public var paused: Bool {
        get {
            return syncBoolForKey(kStudyPausedKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kStudyPausedKey)
        }
    }
    
    public var dataSharingScope: SBBUserDataSharingScope {
        get {
            return SBBUserDataSharingScope(rawValue: syncIntForKey(kDataSharingScopeKey)) ?? .None
        }
        set (newValue) {
            syncSetInteger(newValue.rawValue, forKey: kDataSharingScopeKey)
        }
    }

    public var dataGroups: [String]? {
        get {
            return syncObjectForKey(kSavedDataGroupsKey) as? [String]
        }
        set (newValue) {
            syncSetObject(newValue, forKey: kSavedDataGroupsKey)
        }
    }
    
    func userDefaults() -> NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    func syncBoolForKey(key: String) -> Bool {
        var ret: Bool = false
        dispatch_sync(lockQueue) {
            ret = self.userDefaults().boolForKey(key)
        }
        return ret
    }
    
    func syncSetBool(value:Bool, forKey key: String) {
        dispatch_async(lockQueue) {
            self.userDefaults().setBool(value, forKey: key)
        }
    }
    
    func syncIntForKey(key: String) -> Int {
        var ret: Int = 0
        dispatch_sync(lockQueue) {
            ret = self.userDefaults().integerForKey(key)
        }
        return ret
    }
    
    func syncSetInteger(value:Int, forKey key: String) {
        dispatch_async(lockQueue) {
            self.userDefaults().setInteger(value, forKey: key)
        }
    }
    
    func syncObjectForKey(key: String) -> AnyObject? {
        var ret: AnyObject?
        dispatch_sync(lockQueue) {
            ret = self.userDefaults().objectForKey(key)
        }
        return ret
    }
    
    func syncSetObject(value:AnyObject?, forKey key: String) {
        dispatch_async(lockQueue) {
            if let obj = value {
                self.userDefaults().setObject(obj, forKey: key)
            }
            else {
                self.userDefaults().removeObjectForKey(key)
            }
        }
    }
    
    func resetUserDefaults() {
        let store = userDefaults()
        for (key, _) in store.dictionaryRepresentation() {
            store.removeObjectForKey(key)
        }
        store.synchronize()
    }
    
}

extension String {

    func sha1_hashed() -> String {
        return SBAEncryptionWrapper.sha1(self)
    }
}
