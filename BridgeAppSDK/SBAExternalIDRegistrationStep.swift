//
//  SBAExternalIDRegistrationStep.swift
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

import ResearchKit

extension ORKPageStep {
    public func firstStep() -> ORKStep? {
        return self.stepAfterStepWithIdentifier(nil, withResult: ORKTaskResult(identifier: self.identifier))
    }
}

public enum SBAExternalIDRegistrationError: ErrorType {
    case Invalid(reason: String?)
    case NotMatching
}

public class SBAExternalIDRegistrationStep: ORKPageStep {
    
    public var shouldConfirm: Bool = true

    public init(identifier: String) {
        super.init(identifier: identifier, steps: nil)
    }
    
    override public func stepViewControllerClass() -> AnyClass {
        return SBAExternalIDRegistrationStepViewController.classForCoder()
    }
    
    // MARK: Navigiation
    
    let initialStepIdentifier = SBAProfileInfoOption.externalID.rawValue
    let confirmStepIdentifier = "confirm"
    
    override public func stepAfterStepWithIdentifier(identifier: String?, withResult result: ORKTaskResult) -> ORKStep? {
        if identifier == nil {
            return self.stepWithIdentifier(initialStepIdentifier)
        }
        else if shouldConfirm && (identifier == initialStepIdentifier) {
            return self.stepWithIdentifier(confirmStepIdentifier)
        }
        return nil
    }
    
    override public func stepBeforeStepWithIdentifier(identifier: String, withResult result: ORKTaskResult) -> ORKStep? {
        if identifier == confirmStepIdentifier {
            return self.stepWithIdentifier(initialStepIdentifier)
        }
        return nil
    }
    
    override public func stepWithIdentifier(identifier: String) -> ORKStep? {
        
        guard identifier == initialStepIdentifier || identifier == confirmStepIdentifier else { return nil }
        
        // Create a step for the substep
        let options = SBAProfileInfoOptions(includes: [.externalID])
        let formItems = options.makeFormItems(surveyItemType: .account(.registration))
        let answerFormat = formItems.first?.answerFormat
        
        let step = ORKQuestionStep(identifier: identifier, title: self.title, answer: answerFormat)
        step.optional = false
        if identifier == initialStepIdentifier {
            step.text = self.text
        }
        else {
            step.text = Localization.localizedString("SBA_CONFIRM_EXTERNALID_TEXT")
        }

        return step
    }
    
    
    // MARK: NSCopying
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone)
        guard let step = copy as? SBAExternalIDRegistrationStep else { return copy }
        step.shouldConfirm = self.shouldConfirm
        return step
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.shouldConfirm = aDecoder.decodeBoolForKey("shouldConfirm")
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeBool(self.shouldConfirm, forKey: "shouldConfirm")
    }
    
    // MARK: Equality
    
    override public var hash: Int {
        return super.hash ^ self.shouldConfirm.hashValue
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        guard let castObject = object as? SBAExternalIDRegistrationStep else { return false }
        return super.isEqual(object) &&
            (castObject.shouldConfirm == self.shouldConfirm)
    }
}

public class SBAExternalIDRegistrationStepViewController: ORKPageStepViewController, SBASharedInfoController, SBALoadingViewPresenter {
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.sharedApplication().delegate as! SBAAppInfoDelegate
    }()
    
    lazy public var user: SBAUserWrapper = {
        return self.sharedUser
    }()
    
    
    // MARK: Navigation
    
    final public func goInitialStep() {
        guard let step = pageStep?.firstStep()
            else {
                assert(false, "Should not be able to get to the goInitialStep method without a valid first step")
                return
        }
        self.goToStep(step, direction: .Reverse, animated: true)
    }
    
    // Override the default method for goForward and attempt user registration
    public override func goForward() {
        do {
            let externalId = try self.externalId()
            if self.isTestUser(externalId: externalId) {
                self.promptUserForTestDataGroup(externalId: externalId, loginHandler: { (testUser) in
                    self.loginUser(externalId: externalId, isTestUser: testUser)
                })
            }
            else {
                // Otherwise, just login user using the external id
                self.loginUser(externalId: externalId, isTestUser: false)
            }
        }
        catch SBAExternalIDRegistrationError.NotMatching {
            self.handleFailedConfirmation()
        }
        catch SBAExternalIDRegistrationError.Invalid(let reason) {
            self.handleFailedValidation(reason)
        }
        catch let error as NSError {
            self.handleFailedValidation(error.localizedFailureReason)
        }
    }
    
    func loginUser(externalId externalId: String, isTestUser:Bool) {
        user.loginUser(externalId: externalId) { [weak self] error in
            if let error = error {
                self?.handleFailedRegistration(error)
            }
            else if isTestUser, let testUserDataGroup = self?.sharedBridgeInfo.testUserDataGroup {
                self?.user.addDataGroup(testUserDataGroup, completion: { (_) in
                    self?.goNext()
                })
            }
            else {
                self?.goNext()
            }
        }
    }
    
    func goNext() {
        super.goForward()
    }
    
    
    // MARK: Validation
    
    // Default RegEx is alphanumeric for the external ID
    public var validationRegEx: String = "^[a-zA-Z0-9]+$"
    
    public func validateParameter(externalId externalId: String) throws {
        guard NSPredicate(format: "SELF MATCHES %@", self.validationRegEx).evaluateWithObject(externalId) else {
            throw SBAExternalIDRegistrationError.Invalid(reason: nil)
        }
    }
    
    public func externalId() throws -> String {
        
        guard let externalIdStep = self.step as? SBAExternalIDRegistrationStep else {
            throw SBAExternalIDRegistrationError.Invalid(reason: nil)
        }
        
        let externalIds = self.result?.results?.mapAndFilter { (result) -> String? in
            guard let textResult = result as? ORKTextQuestionResult,
                let answer = textResult.textAnswer?.trim()
                else { return nil }
            return answer
        }
        
        // Check that the external ID is valid
        guard let externalId = externalIds?.first else {
            throw SBAExternalIDRegistrationError.Invalid(reason: nil)
        }
        try validateParameter(externalId: externalId)
        
        // Check that the external ID matches
        guard !externalIdStep.shouldConfirm || (externalIds!.count == 2 && externalId == externalIds?.last) else {
            throw SBAExternalIDRegistrationError.NotMatching
        }
        
        return externalId
    }
    
    
    // MARK: Test User
    
    // Default RegEx is nil for checking if this is a test user
    public var testUserRegEx: String?
    
    public func isTestUser(externalId externalId: String) -> Bool {
        guard let testUserRegEx = self.testUserRegEx else { return false }
        return NSPredicate(format: "SELF MATCHES %@", testUserRegEx).evaluateWithObject(externalId)
    }
    
    public func promptUserForTestDataGroup(externalId externalId: String, loginHandler: ((isTestUser: Bool) -> Void)) {
        // If this may be a test user, need to first display a prompt to confirm that the user is really QA
        // and then on answering the question, complete the registration
        let title = Localization.localizedString("SBA_TESTER_ALERT_TITLE")
        let messageFormat = Localization.localizedString("SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@")
        let message = String.localizedStringWithFormat(messageFormat, Localization.localizedAppName, Localization.buttonYes())
        self.showAlertWithYesNo(title, message: message, actionHandler: loginHandler)
    }
    
    
    // MARK: Error handling
    
    public var failedValidationMessage = Localization.localizedString("SBA_REGISTRATION_INVALID_CODE")
    public var failedConfirmationMessage = Localization.localizedString("SBA_REGISTRATION_MATCH_FAILED")
    public var failedRegistrationTitle = Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")
    
    func handleFailedValidation(reason: String? = nil) {
        showAlertWithOk(nil, message: reason ?? failedValidationMessage, actionHandler: { (_) in
            self.goInitialStep()
        })
    }
    
    func handleFailedConfirmation() {
        showAlertWithOk(nil, message: failedConfirmationMessage, actionHandler: { (_) in
            self.goInitialStep()
        })
    }
    
    func handleFailedRegistration(error: NSError) {
        self.hideLoadingView({
            let message = error.localizedBridgeErrorMessage
            self.showAlertWithOk(self.failedRegistrationTitle, message: message, actionHandler: { (_) in
                self.goInitialStep()
            })
        })
    }
}
