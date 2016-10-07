//
//  SBAUserWrapper+Bridge.swift
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

import Foundation
import BridgeSDK

/**
 * Constant string to search for in the email for a test user
 */
let SBAHiddenTestEmailString = "+test"

/**
 * Datagroup to set if the user is a test user
 */
let SBATestDataGroup = SBAAppDelegate.shared?.bridgeInfo.testUserDataGroup ?? "test_user"

/**
 * Error domin for user errors
 */
let SBAUserErrorDomain = "SBAUserError"

extension SBBUserDataSharingScope {
    init(key: String) {
        switch key {
        case "sponsors_and_partners":
            self = .study
        case "all_qualified_researchers":
            self = .all
        default:
            self = .none
        }
    }
}

public extension SBAUserWrapper {
    
    /**
     Logout the current user
    */
    public func logout() {
        resetStoredUserData()
        // TODO: syoung 09/19/2016 clear the user cache
    }
    
    /**
     * Returns whether or not the data group is contained in the user's data groups
     */
    public func containsDataGroup(_ dataGroup: String) -> Bool {
        return self.dataGroups?.contains(dataGroup) ?? false
    }
    
    /**
     * Add dataGroup to the user's data groups
     */
    public func addDataGroup(_ dataGroup: String, completion: ((NSError?) -> Void)?) {
        let dataGroups = (self.dataGroups ?? []) + [dataGroup]
        updateDataGroups(dataGroups, completion: completion)
    }
    
    /**
     * Remove dataGroup from the user's data groups
     */
    public func removeDataGroup(_ dataGroup: String, completion: ((NSError?) -> Void)?) {
        guard let idx = self.dataGroups?.index(of: dataGroup) else {
            completion?(nil)
            return
        }
        var dataGroups = self.dataGroups!
        dataGroups.remove(at: idx)
        updateDataGroups(dataGroups, completion: completion)
    }
    
    /**
     * Update the user's data groups
     */
    public func updateDataGroups(_ dataGroups: [String], completion: ((NSError?) -> Void)?) {
        SBABridgeManager.updateDataGroups(dataGroups, completion: { [weak self] (_, error) in
            guard (self != nil) else { return }

            self!.dataGroups = dataGroups
            self!.callCompletionOnMain(error as NSError?, completion: completion)
        })
    }
    
    /**
     * Register a user with an externalId *only*
     */
    public func registerUser(externalId: String, dataGroups: [String]?, completion: ((NSError?) -> Void)?) {
        let (email, password) = emailAndPasswordForExternalId(externalId)
        guard (email != nil) && (password != nil) else {
            return
        }
        registerUser(email: email!, password: password!, externalId: externalId, dataGroups: dataGroups, completion: completion)
    }
    
    /**
     * Register a new user with an email/password
     */
    public func registerUser(email: String, password: String, externalId: String?, dataGroups dataGroupsIn: [String]?, completion: ((NSError?) -> Void)?) {
        
        func completeRegistration(_ isTester: Bool) {
            
            // include test_user in the data groups if applicable
            var dataGroups: [String]? = dataGroupsIn
            if (isTester) {
                dataGroups = (dataGroups ?? []) + [SBATestDataGroup]
            }
            
            // Store the values used in registration
            self.email = email
            self.password = password
            self.externalId = externalId
            self.dataGroups = dataGroups
            
            SBABridgeManager.signUp(email, password: password, externalId: externalId, dataGroups: dataGroups, completion: { [weak self] (_, error) in
                let (unhandledError, _) = self!.checkForConsentError(error as NSError?)
                self?.isRegistered = (unhandledError == nil)
                self?.callCompletionOnMain(unhandledError, completion: completion)
            })
        }
        
        // If this is not a test user (or shouldn't check) then complete the registration and return
        guard email.contains(SBAHiddenTestEmailString),
            let appDelegate = SBAAppDelegate.shared,
            !appDelegate.bridgeInfo.disableTestUserCheck else {
            completeRegistration(false)
            return
        }

        // If this may be a test user, need to first display a prompt to confirm that the user is really QA
        // and then on answering the question, complete the registration
        let title = Localization.localizedString("SBA_TESTER_ALERT_TITLE")
        let messageFormat = Localization.localizedString("SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@")
        let message = String.localizedStringWithFormat(messageFormat, Localization.localizedAppName, Localization.buttonYes())
        appDelegate.showAlertWithYesNo(title: title, message: message, actionHandler: completeRegistration)
    }
    
    /**
     * Verify registration to check that the user has verified their email address.
     */
    public func verifyRegistration(_ completion: ((NSError?) -> Void)?) {
        guard let username = self.email?(forAuthManager: nil), let password = self.password?(forAuthManager: nil) else {
            assertionFailure("Attempting to login without a stored username and password")
            return
        }
        signInUser(username, password: password, completion: completion)
    }
    
    /**
     * Login a user on this device via externalId where registration was handled on a different device
     */
    public func loginUser(externalId: String, completion: ((NSError?) -> Void)?) {
        let (email, password) = emailAndPasswordForExternalId(externalId)
        guard (email != nil) && (password != nil) else {
            return
        }
        loginUser(email: email!, password: password!, externalId: externalId, completion: completion)
    }
    
    /**
     * Login a user on this device who has previously completed registration on a different device.
     */
    public func loginUser(email: String, password: String, completion: ((NSError?) -> Void)?) {
        loginUser(email: email, password: password, externalId: nil, completion: completion)
    }
    
    fileprivate func loginUser(email: String, password: String, externalId: String?, completion: ((NSError?) -> Void)?) {
        signInUser(email, password: password) { [weak self] (error) in
            guard (self != nil) else { return }
            
            if ((error == nil) || error!.code == SBBErrorCode.serverPreconditionNotMet.rawValue) {
                self!.email = email
                self!.password = password
                self!.externalId = externalId
            }
            self!.callCompletionOnMain(error, completion: completion)
        }
    }

    /**
     * Send user consent signature (if server precondition not met and reconsenting user)
     */
    public func sendUserConsented(_ consentSignature: SBAConsentSignatureWrapper, completion: ((NSError?) -> Void)?) {
        
        let name = consentSignature.signatureName ?? self.name ?? "First Last"
        let birthdate = consentSignature.signatureBirthdate?.startOfDay() ?? Date(timeIntervalSince1970: 0)
        let consentImage = consentSignature.signatureImage
        let subpopGuid = self.subpopulationGuid ?? self.bridgeInfo?.studyIdentifier ?? "unknown"
        
        SBABridgeManager.sendUserConsented(name, birthDate: birthdate, consentImage: consentImage, sharingScope: self.dataSharingScope, subpopulationGuid: subpopGuid) { [weak self] (_, error) in
            guard (self != nil) else { return }
            
            self!.isConsentVerified = (error == nil)
            self!.callCompletionOnMain(error as NSError?, completion: completion)
        }
    }

    /**
     * Sign in when app is active if the login and consent have been verified
     */
    public func ensureSignedInWithCompletion(_ completion: ((NSError?) -> Void)?) {
        
        // If the user is not logged in or consented then do not attempt login
        // Just return with an error
        guard self.isLoginVerified && self.isConsentVerified else {
            let code = !self.isLoginVerified ? SBBErrorCode.noCredentialsAvailable.rawValue : SBBErrorCode.serverPreconditionNotMet.rawValue
            let error = NSError(domain: SBAUserErrorDomain, code: code, userInfo: nil)
            self.callCompletionOnMain(error, completion: completion)
            return
        }
        
        // Make sure that 
        SBABridgeManager.ensureSignedIn { [weak self] (_, error) in
            guard (self != nil) else { return }
            
            if let errorCode = (error as? NSError)?.code, errorCode == SBBErrorCode.serverPreconditionNotMet.rawValue {
                // If the server returns a 412 after login and consent have been verified then need to reconsent
                self!.isConsentVerified = false
                self!.consentSignature = nil
            }
            
            self!.callCompletionOnMain(error as NSError?, completion: completion)
        }
    }
    
    fileprivate func signInUser(_ username: String, password: String, completion: ((NSError?) -> Void)?) {
        
        SBABridgeManager.sign(in: username, password: password) { [weak self] (responseObject, error) in
            guard (self != nil) else { return }
            
            // If there was an error and it is *not* the consent error then call completion and exit
            let (unhandledError, requiresConsent) = self!.checkForConsentError(error as NSError?)
            guard unhandledError == nil else {
                self!.callCompletionOnMain(unhandledError, completion: completion)
                return
            }
            
            // If signed in successfully, then set the registered and verified flags to true
            self!.isRegistered = true
            self!.isLoginVerified = true
            
            // Copy info from the user session response object
            if let response = responseObject as? SBAUserSessionInfoWrapper {
                self!.updateFromUserSession(response)
            }
            
            if let consentSignature = self!.consentSignature, requiresConsent {
                // If there is a consent signature object stored for this user then attempt
                // sending consent once signed in.
                self!.sendUserConsented(consentSignature, completion: completion)
            }
            else {
                // otherwise, we are done. Set the flag that the consent has been verified and 
                // call the completion
                self!.isConsentVerified = !requiresConsent
                self!.callCompletionOnMain(unhandledError as NSError?, completion: completion)
            }
        }
    }
    
    fileprivate func updateFromUserSession(_ response: SBAUserSessionInfoWrapper) {
        
        // Get the data groups from the response object
        self.dataGroups = response.dataGroups
        
        // Get whether or not sharing is enabled and the sharing scope
        self.isDataSharingEnabled = response.isDataSharingEnabled
        if self.isDataSharingEnabled {
            self.dataSharingScope = response.dataSharingScope
        }
        
        // Get the subpopulation consent status
        self.subpopulationGuid = response.subpopulationGuid
    }
    
    public func emailAndPasswordForExternalId(_ externalId: String) -> (String?, String?) {
        
        guard let emailFormat = self.bridgeInfo?.emailFormatForLoginViaExternalId else {
            assertionFailure("'emailFormatForRegistrationViaExternalId' key missing from BridgeInfo")
            return (nil, nil)
        }
        let passwordFormat = self.bridgeInfo?.passwordFormatForLoginViaExternalId ?? "%@"
        
        let email = NSString(format: emailFormat as NSString, externalId) as String
        let password = NSString(format: passwordFormat as NSString, externalId) as String
        
        return (email, password)
    }
    
    fileprivate func callCompletionOnMain(_ error: NSError?, completion: ((NSError?) -> Void)?) {
        DispatchQueue.main.async {
            completion?(error)
        }
    }
    
    fileprivate func checkForConsentError(_ error: NSError?) -> (error: NSError?, requiresConsent: Bool) {
        guard let error = error else { return (nil, false) }
        let requiresConsent = (error.code == SBBErrorCode.serverPreconditionNotMet.rawValue)
        let unhandledError: NSError? = requiresConsent ? nil : error
        return (unhandledError, requiresConsent)
    }

}

protocol SBAUserSessionInfoWrapper : class {
    var dataGroups : [String]? { get }
    var isDataSharingEnabled : Bool { get }
    var dataSharingScope: SBBUserDataSharingScope { get }
    var subpopulationGuid: String? { get }
}

extension NSDictionary: SBAUserSessionInfoWrapper {
    
    var dataGroups : [String]? {
        return self["dataGroups"] as? [String]
    }
    
    var isDataSharingEnabled : Bool {
        return self["dataSharing"] as? Bool ?? false
    }
    
    var dataSharingScope: SBBUserDataSharingScope {
        guard let sharingKey = self["sharingScope"] as? String , self.isDataSharingEnabled else {
            return .none
        }
        return SBBUserDataSharingScope(key: sharingKey)
    }

    var subpopulationGuid: String? {
        // TODO: syoung 03/29/2016 Handle multiple consent groups with separate sub populations
        if let consentStatuses = self["consentStatuses"] as? [String : [String : AnyObject]] {
            for (_, subpop) in consentStatuses {
                if let required = subpop["required"] as? Bool , required {
                    return subpop["subpopulationGuid"] as? String
                }
            }
        }
        return nil
    }
    
}





