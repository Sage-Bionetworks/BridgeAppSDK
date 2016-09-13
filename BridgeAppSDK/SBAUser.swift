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
    
    let lockQueue = dispatch_queue_create("org.sagebase.UserLockQueue", nil)

    public func logout() {
        dispatch_async(lockQueue) {
            self.resetUserDefaults()
            self.resetKeychain()
        }
    }
    
    lazy public var bridgeInfo: SBABridgeInfo? = {
       return SBAAppDelegate.sharedDelegate?.bridgeInfo
    }()
    
    // --------------------------------------------------
    // MARK: Keychain storage
    // --------------------------------------------------
    
    let kSessionTokenKey = "sessionToken"
    let kNamePropertyKey = "name"
    let kEmailPropertyKey = "email"
    let kPasswordPropertyKey = "password"
    let kSubpopulationGuidKey = "SavedSubpopulationGuid"
    let kConsentSignatureKey = "ConsentSignature"
    let kExternalIdKey = "externalId"
    let kGenderKey = "gender"
    let kBirthdateKey = "birthdate"
    
    public var sessionToken: String? {
        get {
            return getKeychainObject(kSessionTokenKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue, key: kSessionTokenKey)
        }
    }
    
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
    
    public var externalId: String? {
        get {
            return getKeychainObject(kExternalIdKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue, key: kExternalIdKey)
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

    public var gender: String? {
        get {
            return getKeychainObject(kGenderKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue, key: kGenderKey)
        }
    }
    
    public var birthdate: NSDate?  {
        get {
            return getKeychainObject(kBirthdateKey) as? NSDate
        }
        set (newValue) {
            setKeychainObject(newValue, key: kBirthdateKey)
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

    public var consentSignature: SBAConsentSignatureWrapper? {
        get {
            return getKeychainObject(kConsentSignatureKey) as? SBAConsentSignature
        }
        set (newValue) {
            var signature = newValue as? SBAConsentSignature
            if newValue != nil && signature == nil {
                signature = SBAConsentSignature(identifier: kConsentSignatureKey)
                signature!.signatureBirthdate = newValue!.signatureBirthdate
                signature!.signatureImage = newValue!.signatureImage
                signature!.signatureName = newValue!.signatureName
            }
            setKeychainObject(signature, key: kConsentSignatureKey)
        }
    }
    
    private func getKeychainObject(key: String) -> NSSecureCoding? {
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
    
    private func setKeychainObject(object: NSSecureCoding?, key: String) {
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
    
    private func resetKeychain() {
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
    let kDataSharingEnabledKey = "dataSharingEnabled"
    let kDataSharingScopeKey = "dataSharingScope"
    let kOnboardingStepIdentifier = "onboardingStepIdentifier"
    
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
    
    public var dataSharingEnabled: Bool {
        get {
            return syncBoolForKey(kDataSharingEnabledKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kDataSharingEnabledKey)
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
    
    public var onboardingStepIdentifier: String? {
        get {
            return syncObjectForKey(kOnboardingStepIdentifier) as? String
        }
        set (newValue) {
            syncSetObject(newValue, forKey: kOnboardingStepIdentifier)
        }
    }
    
    func userDefaults() -> NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    private func syncBoolForKey(key: String) -> Bool {
        var ret: Bool = false
        dispatch_sync(lockQueue) {
            ret = self.userDefaults().boolForKey(key)
        }
        return ret
    }
    
    private func syncSetBool(value:Bool, forKey key: String) {
        dispatch_async(lockQueue) {
            self.userDefaults().setBool(value, forKey: key)
        }
    }
    
    private func syncIntForKey(key: String) -> Int {
        var ret: Int = 0
        dispatch_sync(lockQueue) {
            ret = self.userDefaults().integerForKey(key)
        }
        return ret
    }
    
    private func syncSetInteger(value:Int, forKey key: String) {
        dispatch_async(lockQueue) {
            self.userDefaults().setInteger(value, forKey: key)
        }
    }
    
    private func syncObjectForKey(key: String) -> AnyObject? {
        var ret: AnyObject?
        dispatch_sync(lockQueue) {
            ret = self.userDefaults().objectForKey(key)
        }
        return ret
    }
    
    private func syncSetObject(value:AnyObject?, forKey key: String) {
        dispatch_async(lockQueue) {
            if let obj = value {
                self.userDefaults().setObject(obj, forKey: key)
            }
            else {
                self.userDefaults().removeObjectForKey(key)
            }
        }
    }
    
    private func resetUserDefaults() {
        let store = userDefaults()
        for (key, _) in store.dictionaryRepresentation() {
            store.removeObjectForKey(key)
        }
        store.synchronize()
    }
    
}

extension SBAUser : SBBAuthManagerDelegateProtocol {
    
    public func sessionTokenForAuthManager(authManager: SBBAuthManagerProtocol) -> String? {
        return self.sessionToken
    }
    
    public func authManager(authManager: SBBAuthManagerProtocol?, didGetSessionToken sessionToken: String?) {
        self.sessionToken = sessionToken
    }
    
    public func emailForAuthManager(authManager: SBBAuthManagerProtocol?) -> String? {
        return self.email
    }
    
    public func passwordForAuthManager(authManager: SBBAuthManagerProtocol?) -> String? {
        return self.password
    }
    
}
