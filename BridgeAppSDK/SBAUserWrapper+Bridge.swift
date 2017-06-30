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
let SBATestDataGroup: String = {
    let appDelegate = UIApplication.shared.delegate as? SBAAppInfoDelegate
    return appDelegate?.bridgeInfo.testUserDataGroup ?? "test_user"
}()

/**
 * Error domin for user errors
 */
let SBAUserErrorDomain = "SBAUserError"

extension SBBParticipantDataSharingScope {
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

            // Only update the data groups if the error is nil
            if error == nil {
                self!.dataGroups = dataGroups
            }
            self!.callCompletionOnMain(error, completion: completion)
        })
    }
    
    /**
     Set the user's external ID.
     
     @note This method is only used for the participant who is already registered.
     
     @param externalIdentifier      The external identifier
     @param completion              Completion handler
    */
    public func setExternalID(_ externalIdentifier: String, completion: ((Error?) -> Void)?) {
        SBABridgeManager.setExternalIdentifier(externalIdentifier) { [weak self] (_, error) in
            guard (self != nil) else { return }

            // Only set the external ID if the error is nil
            if error == nil {
                self!.externalId = externalIdentifier
            }
            self!.callCompletionOnMain(error, completion: completion)
        }
    }
    
    
    /**
     Register a user with a changed email address
     
     @param email       The email address to use for the new user
     @param completion  Completion handler
     */
    public func changeUserEmailAddress(_ email: String, completion: ((Error?) -> Void)?) {
        guard let password = self.password(forAuthManager: nil) else {
            assertionFailure("Attempting to change email without a stored password")
            return
        }
        registerUser(email: email, password: password, externalId: self.externalId, dataGroups: self.dataGroups, completion: completion)
    }
    
    /**
     Request a password reset sent to the given email address.
     
     @param email       The email address to send the forget password message
     @param completion  Completion handler
    */
    public func forgotPassword(_ email: String, completion: ((Error?) -> Void)?) {
        SBABridgeManager.forgotPassword(email) { [weak self] (_, error) in
            self?.callCompletionOnMain(error, completion: completion)
        }
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
        
        let signup = SBBSignUp()
        signup.email = email
        signup.password = password
        if let dataGroups = dataGroupsIn {
            signup.dataGroups = Set(dataGroups)
        }
        if externalId != nil {
            signup.externalId = externalId!
        }
        if let name = self.name {
            signup.firstName = name
        }
        if let familyName = self.familyName {
            signup.lastName = familyName
        }
        registerUser(signup: signup, completion: completion)
    }
    
    /**
     Register a new user with an `SBBSignUp` object.
     
     @param signup      A valid signup object should include a non-nil password and non-nil email. Other fields are optional.
     @param completion  Completion handler
     */
    public func registerUser(signup: SBBSignUp, completion: ((Error?) -> Void)?) {
    
        func completeRegistration(_ isTester: Bool) {
            
            // include test_user in the data groups if applicable
            var dataGroups: [String]? = {
                if signup.dataGroups != nil {
                    return Array(signup.dataGroups)
                }
                else {
                    return nil
                }
            }()
            if (isTester) {
                dataGroups = (dataGroups ?? []) + [SBATestDataGroup]
                signup.dataGroups = Set(dataGroups!)
            }
            
            // Store the values used in registration
            self.email = signup.email
            self.password = signup.password
            self.externalId = signup.externalId
            self.dataGroups = dataGroups
            
            SBABridgeManager.signUp(signup, completion: { [weak self] (_, error) in
                let (unhandledError, _) = self!.checkForConsentError(error)
                self?.isRegistered = (unhandledError == nil)
                self?.callCompletionOnMain(unhandledError, completion: completion)
            })
        }
        
        // If this is not a test user (or shouldn't check) then complete the registration and return
        guard signup.email.contains(SBAHiddenTestEmailString) &&
            appDelegate != nil &&
            !(bridgeInfo?.disableTestUserCheck ?? false) else {
            completeRegistration(false)
            return
        }

        // If this may be a test user, need to first display a prompt to confirm that the user is really QA
        // and then on answering the question, complete the registration
        let title = Localization.localizedString("SBA_TESTER_ALERT_TITLE")
        let messageFormat = Localization.localizedString("SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@")
        let message = String.localizedStringWithFormat(messageFormat, Localization.localizedAppName, Localization.buttonYes())
        appDelegate!.showAlertWithYesNo(title: title, message: message, actionHandler: completeRegistration)
    }
    
    /**
     Check that the user has verified their email address.
     
     @param completion  Completion handler
     */
    public func verifyRegistration(_ completion: ((Error?) -> Void)?) {
        guard let username = self.email, let password = self.password else {
            assertionFailure("Attempting to login without a stored username and password")
            return
        }
        self.signInUser(username, password: password, completion: { [weak self] (error) in
                self?.callCompletionOnMain(error, completion: completion)
            }
        )
    }
    
    /**
     Resend the registration verification email.
     
     @param completion  Completion handler
     */
    func resendVerificationEmail(_ completion: ((Error?) -> Void)?) {
        guard let email = self.email(forAuthManager: nil) else {
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
        backgroundSendUserConsented(consentSignature) { [weak self] (error) in
            self?.callCompletionOnMain(error, completion: completion)
        }
    }
    
    fileprivate func backgroundSendUserConsented(_ consentSignature: SBAConsentSignatureWrapper, completion: ((Error?) -> Void)?) {
        let name = consentSignature.signatureName ?? self.name ?? "First Last"
        let birthdate = consentSignature.signatureBirthdate?.startOfDay() ?? Date(timeIntervalSince1970: 0)
        let consentImage = consentSignature.signatureImage
        let subpopGuid = self.subpopulationGuid ?? self.bridgeInfo?.studyIdentifier ?? "unknown"
        
        SBABridgeManager.sendUserConsented(name, birthDate: birthdate, consentImage: consentImage, sharingScope: self.dataSharingScope, subpopulationGuid: subpopGuid) { [weak self] (_, error) in
            guard (self != nil) else { return }
            
            self!.isConsentVerified = (error == nil)
            completion?(error)
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
    
    /**
     Use default handling to withdraw from the study for the primary subpopulation (stored on this user)
     
     @param reason      Reason for withdrawing from study
     @param completion  Completion handler
     */
    public func withdrawFromStudy() {
        guard let appDelegate = self.appDelegate else {
            assertionFailure("This method is only applicable for applications that support the SBABridgeAppSDKDelegate")
            return
        }

        // Show action sheet to confirm intent
        let controller = UIAlertController(title: Localization.localizedString("WITHDRAW_TITLE"),
                                           message: Localization.localizedString("WITHDRAW_CONFIRMATION_MESSAGE"),
                                           preferredStyle: .actionSheet)
        
        controller.addAction(UIAlertAction(title: Localization.buttonCancel(), style: .cancel, handler: nil))
        controller.addAction(UIAlertAction(title: Localization.localizedString("WITHDRAW_TITLE"),
                                           style: .destructive, handler: { [weak self] (_) in
                                            self?.promptForWithdraw()
        }))
        
        appDelegate.presentViewController(controller, animated: true) { }
    }
    
    fileprivate func promptForWithdraw() {
        guard let json = SBAResourceFinder.shared.json(forResource: "Withdraw"),
            let task = (json as NSDictionary).createORKTask()
        else {
            assertionFailure("Failed to create withdrawal survey")
            self.withdrawFromStudy(reason: nil, completion: { [weak self] (_) in
                self?.appDelegate?.showAppropriateViewController(animated: true)
                })
            return
        }

        // Setup the task view controller with a finish handler
        let taskVC = SBATaskViewController(task: task, taskRun: nil)
        taskVC.continueButtonText = Localization.localizedString("WITHDRAW_TITLE")
        taskVC.finishTaskHandler = { (taskViewController, reason, _) -> Void in
            guard reason == .completed else {
                taskViewController.dismiss(animated: true, completion: nil)
                return
            }
            let withdrawReason: String? = {
                let stepResult = taskViewController.result.results?.last as? ORKStepResult
                let result = stepResult?.results?.last
                if let choiceResult = result as? ORKChoiceQuestionResult {
                    return choiceResult.choiceAnswers?.first as? String
                }
                else if let textResult = result as? ORKTextQuestionResult {
                    return textResult.textAnswer
                }
                return nil
            }()
            self.withdrawFromStudy(reason: withdrawReason, completion: { [weak self] (_) in
                self?.appDelegate?.showAppropriateViewController(animated: false)
                taskViewController.dismiss(animated: true, completion: nil)
            })
        }
        
        self.appDelegate?.presentViewController(taskVC, animated: true, completion: nil)
    }
    
    /**
     Withdraw from the study for the primary subpopulation (stored on this user)
     
     @param reason      Reason for withdrawing from study
     @param completion  Completion handler
     */
    public func withdrawFromStudy(reason:String?, completion: ((Error?) -> Void)?) {
        guard let subpop = subpopulationGuid else {
            // Valid subpopulation was not found. Just reset and call completion
            self.resetStoredUserData()
            self.callCompletionOnMain(nil, completion: completion)
            return
        }
        self.withdrawFromStudy(subpopulationGuid: subpop, reason: reason, completion: completion)
    }
    
    /**
     Withdraw from the study for a given subpopulation GUID.
     
     @param subpopulationGuid   Subpopulation GUID for the study
     @param reason              Reason for withdrawing from study
     @param completion          Completion handler
     */
    public func withdrawFromStudy(subpopulationGuid:String, reason:String?, completion: ((Error?) -> Void)?) {
        // Withdraw from the study
        SBABridgeManager.withdrawConsent(forSubpopulation: subpopulationGuid, reason: reason) { [weak self] (_, error) in
            self?.callCompletionOnMain(error, completion: completion)
        }
        // reset the stored user data immediately
        self.resetStoredUserData()
    }
    
    fileprivate func signInUser(_ username: String, password: String, completion: ((Error?) -> Void)?) {
        
        SBABridgeManager.sign(in: username, password: password) { [weak self] (responseObject, error) in
            guard (self != nil) else { return }
            
            // If there was an error and it is *not* the consent error then call completion and exit
            let (unhandledError, requiresConsent) = self!.checkForConsentError(error)
            guard unhandledError == nil else {
                completion?(unhandledError)
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
                self!.backgroundSendUserConsented(consentSignature, completion: completion)
            }
            else {
                // otherwise, we are done. Set the flag that the consent has been verified and 
                // call the completion
                self!.isConsentVerified = !requiresConsent
                completion?(unhandledError)
            }
        }
    }
    
    /**
     Call this any time the user session info gets updated elsewhere.
     */
    func updateFromUserSessionInfo(_ info: SBBUserSessionInfo) {
        self.updateFromUserSession(info)
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
        
        // Get the user's name
        self.createdOn = response.createdOn
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
    var dataSharingScope: SBBParticipantDataSharingScope { get }
    var subpopulationGuid: String? { get }
    var firstName: String? { get }
    var lastName: String? { get }
    var createdOn: Date { get }
}

extension NSDictionary: SBAUserSessionInfoWrapper {
    
    var dataGroups : [String]? {
        return self["dataGroups"] as? [String]
    }
    
    var isDataSharingEnabled : Bool {
        return self["dataSharing"] as? Bool ?? false
    }
    
    var firstName : String? {
        return self["firstName"] as? String
    }
    
    var lastName : String? {
        return self["lastName"] as? String
    }
    
    var createdOn : Date {
        guard let dateString = self["createdOn"] as? String else { return Date() }
        return NSDate(iso8601String: dateString) as Date? ?? Date()
    }
    
    var dataSharingScope: SBBParticipantDataSharingScope {
        guard let sharingKey = self["sharingScope"] as? String , self.isDataSharingEnabled else {
            return .none
        }
        return SBBParticipantDataSharingScope(key: sharingKey)
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

extension SBBUserSessionInfo: SBAUserSessionInfoWrapper {
    var createdOn: Date {
        // If the participant hasn't signed in yet, there won't be a createdOn date in the placeholder study participant object.
        return self.studyParticipant?.createdOn ?? Date()
    }

    var lastName: String? {
        return self.studyParticipant?.lastName
    }

    var firstName: String? {
        return self.studyParticipant?.firstName
    }

    var subpopulationGuid: String? {
        // TODO: emm 2017-06-01 Handle multiple consent groups with separate sub populations
        if let consentStatuses = self.consentStatuses as? [String : SBBConsentStatus] {
            for (_, subpop) in consentStatuses {
                if let required = subpop.required as? Bool , required {
                    return subpop.subpopulationGuid
                }
            }
        }
        return nil
    }

    var dataSharingScope: SBBParticipantDataSharingScope {
        guard self.studyParticipant != nil,
            let sharingKey = self.studyParticipant.sharingScope,
            self.isDataSharingEnabled else {
            return .none
        }
        return SBBParticipantDataSharingScope(key: sharingKey)
    }

    var isDataSharingEnabled: Bool {
        return self.dataSharing as? Bool ?? false
    }

    var dataGroups: [String]? {
        guard self.studyParticipant != nil && self.studyParticipant.dataGroups != nil else { return nil }
        return Array(self.studyParticipant.dataGroups)
    }
}





