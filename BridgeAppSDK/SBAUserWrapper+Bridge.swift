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
let SBATestDataGroup = "test_user"

let SBAUserErrorDomain = "SBAUserError"

extension SBBUserDataSharingScope {
    init(key: String) {
        switch key {
        case "sponsors_and_partners":
            self = .Study
        case "all_qualified_researchers":
            self = .All
        default:
            self = .None
        }
    }
}

public extension SBAUserWrapper {
    
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
    public func registerUser(email email: String, password: String, externalId: String?, dataGroups dataGroupsIn: [String]?, completion: ((NSError?) -> Void)?) {
        
        func completeRegistration(isTester: Bool) {
            
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
            
            SBAUserBridgeManager.signUp(email, password: password, externalId: externalId, dataGroups: dataGroups, completion: { [weak self] (_, error) in
                self?.hasRegistered = (error == nil)
                self?.callCompletionOnMain(error, completion: completion)
            })
        }
        
        // If this is not a test user (or shouldn't check) then complete the registration and return
        guard let appDelegate = SBAAppDelegate.sharedDelegate where
            (appDelegate.shouldPerformTestUserEmailCheckOnSignup && email.containsString(SBAHiddenTestEmailString)) else {
            completeRegistration(false)
            return
        }

        // If this may be a test user, need to first display a prompt to confirm that the user is really QA
        // and then on answering the question, complete the registration
        let title = Localization.localizedString("SBA_TESTER_ALERT_TITLE")
        let messageFormat = Localization.localizedString("SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@")
        let message = String(format: messageFormat, Localization.localizedAppName, Localization.buttonYes())
        appDelegate.showAlertWithYesNo(title, message: message, actionHandler: completeRegistration)
    }
    
    /**
     * Verify registration to check that the user has verified their email address.
     */
    public func verifyRegistration(completion: ((NSError?) -> Void)?) {
        guard let username = self.usernameForAuthManager?(nil), let password = self.passwordForAuthManager?(nil) else {
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
        signInUser(email!, password: password!, completion: completion)
    }
    
    /**
     * Login a user on this device who has previously completed registration on a different device.
     */
    public func loginUser(email email: String, password: String, completion: ((NSError?) -> Void)?) {
        signInUser(email, password: password) { [weak self] (error) in
            guard (self != nil) else { return }
            
            if ((error == nil) || error!.code == SBBErrorCode.ServerPreconditionNotMet.rawValue) {
                self!.email = email
                self!.password = password
            }
            self!.callCompletionOnMain(error, completion: completion)
        }
    }

    /**
     * Send user consent signature (if server precondition not met and reconsenting user)
     */
    public func sendUserConsented(consentSignature: SBAConsentSignature, completion: ((NSError?) -> Void)?) {
        
        let name = consentSignature.signatureName ?? self.name ?? "First Last"
        let birthdate = consentSignature.signatureBirthdate?.startOfDay() ?? NSDate(timeIntervalSince1970: 0)
        let consentImage = consentSignature.signatureImage
        let subpopGuid = self.subpopulationGuid ?? SBAAppDelegate.sharedDelegate?.bridgeInfo.studyIdentifier ?? "unknown"
        
        SBAUserBridgeManager.sendUserConsented(name, birthDate: birthdate, consentImage: consentImage, sharingScope: self.dataSharingScope, subpopulationGuid: subpopGuid) { [weak self] (_, error) in
            guard (self != nil) else { return }
            
            self!.consentVerified = (error == nil)
            self!.callCompletionOnMain(error, completion: completion)
        }
    }

    /**
     * Sign in when app is active if the login and consent have been verified
     */
    public func ensureSignedInWithCompletion(completion: ((NSError?) -> Void)?) {
        
        // If the user is not logged in or consented then do not attempt login
        // Just return with an error
        guard self.loginVerified && self.consentVerified else {
            let code = !self.loginVerified ? SBBErrorCode.NoCredentialsAvailable.rawValue : SBBErrorCode.ServerPreconditionNotMet.rawValue
            let error = NSError(domain: SBAUserErrorDomain, code: code, userInfo: nil)
            self.callCompletionOnMain(error, completion: completion)
            return
        }
        
        // Make sure that 
        SBAUserBridgeManager.ensureSignedInWithCompletion { [weak self] (_, error) in
            guard (self != nil) else { return }
            
            if (error != nil) && error!.code == SBBErrorCode.ServerPreconditionNotMet.rawValue {
                // If the server returns a 412 after login and consent have been verified then need to reconsent
                self!.consentVerified = false
                self!.consentSignature = nil
            }
            
            self!.callCompletionOnMain(error, completion: completion)
        }
    }
    
    private func signInUser(username: String, password: String, completion: ((NSError?) -> Void)?) {
        
        SBAUserBridgeManager.signIn(username, password: password) { [weak self] (responseObject, error) in
            guard (self != nil) else { return }
            
            // If there was an error and it is *not* the consent error then call completion and exit
            let requiresConsent = (error != nil) && error!.code == SBBErrorCode.ServerPreconditionNotMet.rawValue
            guard ((error != nil) && !requiresConsent) else {
                self!.callCompletionOnMain(error, completion: completion)
                return
            }
            
            // If signed in successfully, then set the registered and verified flags to true
            self!.hasRegistered = true
            self!.loginVerified = true
            
            // Copy info from the user session response object
            if let response = responseObject as? SBAUserSessionInfoWrapper {
                self!.copyFromUserSession(response)
            }
            
            if let consentSignature = self!.consentSignature where requiresConsent {
                // If there is a consent signature object stored for this user then attempt
                // sending consent once signed in.
                self!.sendUserConsented(consentSignature, completion: completion)
            }
            else {
                // otherwise, we are done. Set the flag that the consent has been verified and 
                // call the completion
                self!.consentVerified = !requiresConsent
                self!.callCompletionOnMain(error, completion: completion)
            }
        }
    }
    
    private func copyFromUserSession(response: SBAUserSessionInfoWrapper) {
        
        // Get the data groups from the response object
        self.dataGroups = response.dataGroups
        
        // Get whether or not sharing is enabled and the sharing scope
        self.dataSharingEnabled = response.dataSharingEnabled
        if self.dataSharingEnabled {
            self.dataSharingScope = response.dataSharingScope
        }
        
        // Get the subpopulation consent status
        self.subpopulationGuid = response.subpopulationGuid
    }
    
    private func emailAndPasswordForExternalId(externalId: String) -> (String?, String?) {
        
        guard let emailFormat = SBAAppDelegate.sharedDelegate?.bridgeInfo.emailFormatForRegistrationViaExternalId else {
            assertionFailure("'emailFormatForRegistrationViaExternalId' key missing from BridgeInfo")
            return (nil, nil)
        }
        let passwordFormat = SBAAppDelegate.sharedDelegate?.bridgeInfo.passwordFormatForRegistrationViaExternalId ?? "%@"
        
        let email = NSString(format: emailFormat, externalId) as String
        let password = NSString(format: passwordFormat, externalId) as String
        
        return (email, password)
    }
    
    private func callCompletionOnMain(error: NSError?, completion: ((NSError?) -> Void)?) {
        dispatch_async(dispatch_get_main_queue()) {
            completion?(error)
        }
    }

}

protocol SBAUserSessionInfoWrapper : class {
    var dataGroups : [String]? { get }
    var dataSharingEnabled : Bool { get }
    var dataSharingScope: SBBUserDataSharingScope { get }
    var subpopulationGuid: String? { get }
}

extension NSDictionary: SBAUserSessionInfoWrapper {
    
    var dataGroups : [String]? {
        return self["dataGroups"] as? [String]
    }
    
    var dataSharingEnabled : Bool {
        return self["dataSharing"] as? Bool ?? false
    }
    
    var dataSharingScope: SBBUserDataSharingScope {
        guard let sharingKey = self["dataGroups"] as? String where self.dataSharingEnabled else {
            return .None
        }
        return SBBUserDataSharingScope(key: sharingKey)
    }

    var subpopulationGuid: String? {
        // TODO: Handle multiple consent groups with separate sub populations
        if let consentStatuses = self["consentStatuses"] as? [String : [String : AnyObject]] {
            for (_, subpop) in consentStatuses {
                if let required = subpop["required"] as? Bool where required {
                    return subpop["subpopulationGuid"] as? String
                }
            }
        }
        return nil
    }
    
}





