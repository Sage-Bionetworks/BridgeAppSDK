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

/**
 The `SBAUser` model object is intended as a singleton object for storing information about
 the currently logged in user in the user defaults and keychain.
 */
public final class SBAUser: NSObject, SBAUserWrapper {
    
    let lockQueue = DispatchQueue(label: "org.sagebase.UserLockQueue")

    public func resetStoredUserData() {
        lockQueue.async {
            self.resetUserDefaults()
            self.resetKeychain()
        }
    }
    
    public var bridgeInfo: SBABridgeInfo? {
       return SBAAppDelegate.shared?.bridgeInfo
    }
    
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
            setKeychainObject(newValue as NSSecureCoding?, key: kSessionTokenKey)
        }
    }
    
    public var name: String? {
        get {
            return getKeychainObject(kNamePropertyKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kNamePropertyKey)
        }
    }
    
    public var email: String? {
        get {
            return getKeychainObject(kEmailPropertyKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kEmailPropertyKey)
        }
    }
    
    public var externalId: String? {
        get {
            return getKeychainObject(kExternalIdKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kExternalIdKey)
        }
    }
    
    public var password: String? {
        get {
            return getKeychainObject(kPasswordPropertyKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kPasswordPropertyKey)
        }
    }

    public var gender: HKBiologicalSex {
        get {
            return HKBiologicalSex(rawValue: (getKeychainObject(kGenderKey) as? NSNumber)?.intValue ?? 0) ?? .notSet
        }
        set (newValue) {
            setKeychainObject(NSNumber(value: newValue.rawValue), key: kGenderKey)
        }
    }
    
    public var birthdate: Date?  {
        get {
            return getKeychainObject(kBirthdateKey) as? Date
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kBirthdateKey)
        }
    }
    
    public var subpopulationGuid: String? {
        get {
            // if no subpopulationGuid found for user, return study identifier instead
            return getKeychainObject(kSubpopulationGuidKey) as? String ?? gSBBAppStudy
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kSubpopulationGuidKey)
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
    
    fileprivate func getKeychainObject(_ key: String) -> NSSecureCoding? {
        var obj: NSSecureCoding?
        lockQueue.sync {
            var err: NSError?
            obj = ORKKeychainWrapper.object(forKey: key, error: &err)
            if let error = err {
                print("Error accessing keychain \(key): \(error.code) \(error)")
            }
        }
        return obj
    }
    
    fileprivate func setKeychainObject(_ object: NSSecureCoding?, key: String) {
        lockQueue.async {
            do {
                if let obj = object {
                    try ORKKeychainWrapper.setObject(obj, forKey: key)
                }
                else {
                    try ORKKeychainWrapper.removeObject(forKey: key)
                }
            }
            catch let error as NSError {
                print("Failed to set \(key): \(error.code) \(error.localizedDescription)")
            }
        }
    }
    
    fileprivate func resetKeychain() {
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
    let kConsentVerifiedKey = "isConsentVerified"
    let kSavedDataGroupsKey = "SavedDataGroups"
    let kDataSharingEnabledKey = "isDataSharingEnabled"
    let kDataSharingScopeKey = "dataSharingScope"
    let kOnboardingStepIdentifier = "onboardingStepIdentifier"
    
    public var isRegistered: Bool {
        get {
            return syncBoolForKey(kRegisteredKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kRegisteredKey)
        }
    }

    public var isLoginVerified: Bool {
        get {
            return syncBoolForKey(kLoginVerifiedKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kLoginVerifiedKey)
        }
    }

    public var isConsentVerified: Bool {
        get {
            return syncBoolForKey(kConsentVerifiedKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kConsentVerifiedKey)
        }
    }
    
    public var isDataSharingEnabled: Bool {
        get {
            return syncBoolForKey(kDataSharingEnabledKey)
        }
        set (newValue) {
            syncSetBool(newValue, forKey: kDataSharingEnabledKey)
        }
    }
    
    public var dataSharingScope: SBBUserDataSharingScope {
        get {
            return SBBUserDataSharingScope(rawValue: syncIntForKey(kDataSharingScopeKey)) ?? .none
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
            syncSetObject(newValue as AnyObject?, forKey: kSavedDataGroupsKey)
        }
    }
    
    public var onboardingStepIdentifier: String? {
        get {
            return syncObjectForKey(kOnboardingStepIdentifier) as? String
        }
        set (newValue) {
            syncSetObject(newValue as AnyObject?, forKey: kOnboardingStepIdentifier)
        }
    }
    
    fileprivate func userDefaults() -> UserDefaults {
        return UserDefaults.standard
    }
    
    fileprivate func syncBoolForKey(_ key: String) -> Bool {
        var ret: Bool = false
        lockQueue.sync {
            ret = self.userDefaults().bool(forKey: key)
        }
        return ret
    }
    
    fileprivate func syncSetBool(_ value:Bool, forKey key: String) {
        lockQueue.async {
            self.userDefaults().set(value, forKey: key)
        }
    }
    
    fileprivate func syncIntForKey(_ key: String) -> Int {
        var ret: Int = 0
        lockQueue.sync {
            ret = self.userDefaults().integer(forKey: key)
        }
        return ret
    }
    
    fileprivate func syncSetInteger(_ value:Int, forKey key: String) {
        lockQueue.async {
            self.userDefaults().set(value, forKey: key)
        }
    }
    
    fileprivate func syncObjectForKey(_ key: String) -> AnyObject? {
        var ret: AnyObject?
        lockQueue.sync {
            ret = self.userDefaults().object(forKey: key) as AnyObject?
        }
        return ret
    }
    
    fileprivate func syncSetObject(_ value:AnyObject?, forKey key: String) {
        lockQueue.async {
            if let obj = value {
                self.userDefaults().set(obj, forKey: key)
            }
            else {
                self.userDefaults().removeObject(forKey: key)
            }
        }
    }
    
    fileprivate func resetUserDefaults() {
        let store = userDefaults()
        for (key, _) in store.dictionaryRepresentation() {
            store.removeObject(forKey: key)
        }
        store.synchronize()
    }
    
}

extension SBAUser : SBBAuthManagerDelegateProtocol {
    
    public func sessionToken(forAuthManager authManager: SBBAuthManagerProtocol) -> String? {
        let token = self.sessionToken
        #if DEBUG
        print("getting Session Token: \(token)")
        #endif
        return token
    }
    
    public func authManager(_ authManager: SBBAuthManagerProtocol?, didGetSessionToken sessionToken: String?) {
        #if DEBUG
        print("setting Session Token: \(sessionToken)")
        #endif
        self.sessionToken = sessionToken
    }
    
    public func email(forAuthManager authManager: SBBAuthManagerProtocol?) -> String? {
        return self.email
    }
    
    public func password(forAuthManager authManager: SBBAuthManagerProtocol?) -> String? {
        return self.password
    }
    
}
