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
     Returns whether or not the data group is contained in the user's data groups
     
     @param dataGroup   The data group to look for
     @return            `YES` if the user is in this data group and `NO` if not
     */
    public func containsDataGroup(_ dataGroup: String) -> Bool {
        return self.dataGroups?.contains(dataGroup) ?? false
    }
    
    /**
     Add dataGroup to the user's data groups
     
     @param dataGroup   The data group to add to the user's data groups
     @param completion  Completion handler
     */
    public func addDataGroup(_ dataGroup: String, completion: ((Error?) -> Void)?) {
        let dataGroups = (self.dataGroups ?? []) + [dataGroup]
        updateDataGroups(dataGroups, completion: completion)
    }
    
    /**
     Remove dataGroup from the user's data groups
     
     @param dataGroup   The data group to remove
     @param completion  Completion handler
     */
    public func removeDataGroup(_ dataGroup: String, completion: ((Error?) -> Void)?) {
        guard let idx = self.dataGroups?.index(of: dataGroup) else {
            completion?(nil)
            return
        }
        var dataGroups = self.dataGroups!
        dataGroups.remove(at: idx)
        updateDataGroups(dataGroups, completion: completion)
    }
    
    /**
     Update the user's data groups
     
     @param dataGroups  The new set of data groups
     @param completion  Completion handler
     */
    public func updateDataGroups(_ dataGroups: [String], completion: ((Error?) -> Void)?) {
        SBABridgeManager.updateDataGroups(dataGroups, completion: { [weak self] (_, error) in
            guard (self != nil) else { return }

            self!.dataGroups = dataGroups
            self!.callCompletionOnMain(error, completion: completion)
        })
    }
    
    /**
     Register a user with a changed email address
     
     @param email       The email address to use for the new user
     @param completion  Completion handler
     */
    public func changeUserEmailAddress(_ email: String, completion: ((Error?) -> Void)?) {
        guard let password = self.password?(forAuthManager: nil) else {
            assertionFailure("Attempting to change email without a stored password")
            return
        }
        registerUser(email: email, password: password, externalId: self.externalId, dataGroups: self.dataGroups, completion: completion)
    }
    
    /**
     Register a new user with an email/password
     
     @param email       The email address to use for the new user
     @param password    The user's password
     @param externalID  The external ID (if any) associated with this registration
     @param dataGroups  The data groups to assign initially to this user
     @param completion  Completion handler
     */
    public func registerUser(email: String, password: String, externalId: String?, dataGroups dataGroupsIn: [String]?, completion: ((Error?) -> Void)?) {
        
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
                let (unhandledError, _) = self!.checkForConsentError(error)
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
     Check that the user has verified their email address.
     
     @param completion  Completion handler
     */
    public func verifyRegistration(_ completion: ((Error?) -> Void)?) {
        guard let username = self.email?(forAuthManager: nil), let password = self.password?(forAuthManager: nil) else {
            assertionFailure("Attempting to login without a stored username and password")
            return
        }
        signInUser(username, password: password, completion: completion)
    }
    
    /**
     Resend the registration verification email.
     
     @param completion  Completion handler
     */
    func resendVerificationEmail(_ completion: ((Error?) -> Void)?) {
        guard let email = self.email?(forAuthManager: nil) else {
            assertionFailure("Attempting to resend verification email without a stored email")
            return
        }
        SBABridgeManager.resendEmailVerification(email) { [weak self] (_, error) in
            self?.callCompletionOnMain(error, completion: completion)
        }
    }
    
    /**
     Login a user on this device via externalId where registration was handled on a different device,
     in the Bridge study UI or after deleting and re-installing.
     
     @param externalId  External ID to use for login
     @param completion  Completion handler
     */
    public func loginUser(externalId: String, completion: ((Error?) -> Void)?) {
        let (email, password) = emailAndPasswordForExternalId(externalId)
        guard (email != nil) && (password != nil) else {
            return
        }
        loginUser(email: email!, password: password!, externalId: externalId, completion: completion)
    }
    
    /**
     Login a user on this device who has previously completed registration on a different device or
     or in the Bridge study UI.
     
     @param email       Email address to use for login
     @param password    Password to use for login
     @param completion  Completion handler
     */
    public func loginUser(email: String, password: String, completion: ((Error?) -> Void)?) {
        loginUser(email: email, password: password, externalId: nil, completion: completion)
    }
    
    fileprivate func loginUser(email: String, password: String, externalId: String?, completion: ((Error?) -> Void)?) {
        signInUser(email, password: password) { [weak self] (error) in
            guard (self != nil) else { return }
            
            if (error == nil) || error!.preconditionNotMet {
                self!.email = email
                self!.password = password
                self!.externalId = externalId
            }
            self!.callCompletionOnMain(error, completion: completion)
        }
    }

    /**
     Send user consent signature (if server precondition not met and reconsenting user)
     
     @param consentSignature    The consent signature 
     @param completion          Completion handler
     */
    public func sendUserConsented(_ consentSignature: SBAConsentSignatureWrapper, completion: ((Error?) -> Void)?) {
        
        let name = consentSignature.signatureName ?? self.name ?? "First Last"
        let birthdate = consentSignature.signatureBirthdate?.startOfDay() ?? Date(timeIntervalSince1970: 0)
        let consentImage = consentSignature.signatureImage
        let subpopGuid = self.subpopulationGuid ?? self.bridgeInfo?.studyIdentifier ?? "unknown"
        
        SBABridgeManager.sendUserConsented(name, birthDate: birthdate, consentImage: consentImage, sharingScope: self.dataSharingScope, subpopulationGuid: subpopGuid) { [weak self] (_, error) in
            guard (self != nil) else { return }
            
            self!.isConsentVerified = (error == nil)
            self!.callCompletionOnMain(error, completion: completion)
        }
    }

    /**
     Sign in when app is active if the login and consent have been verified
     */
    public func ensureSignedInWithCompletion(_ completion: ((Error?) -> Void)?) {
        
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
            
            if error?.preconditionNotMet == true {
                // If the server returns a 412 after login and consent have been verified then need to reconsent
                self!.isConsentVerified = false
                self!.consentSignature = nil
            }
            
            self!.callCompletionOnMain(error, completion: completion)
        }
    }
    
    fileprivate func signInUser(_ username: String, password: String, completion: ((Error?) -> Void)?) {
        
        SBABridgeManager.sign(in: username, password: password) { [weak self] (responseObject, error) in
            guard (self != nil) else { return }
            
            // If there was an error and it is *not* the consent error then call completion and exit
            let (unhandledError, requiresConsent) = self!.checkForConsentError(error)
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
                self!.callCompletionOnMain(unhandledError, completion: completion)
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
    
    fileprivate func callCompletionOnMain(_ error: Error?, completion: ((Error?) -> Void)?) {
        DispatchQueue.main.async {
            completion?(error)
        }
    }
    
    fileprivate func checkForConsentError(_ error: Error?) -> (error: Error?, requiresConsent: Bool) {
        guard let error = error else { return (nil, false) }
        let requiresConsent = error.preconditionNotMet
        let unhandledError: Error? = requiresConsent ? nil : error
        return (unhandledError, requiresConsent)
    }

}

extension Error {
    
    var preconditionNotMet : Bool {
        return ((self as NSError).code == SBBErrorCode.serverPreconditionNotMet.rawValue)
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





