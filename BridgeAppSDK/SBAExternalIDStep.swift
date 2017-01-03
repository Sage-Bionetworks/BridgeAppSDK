//
//  SBAExternalIDStep.swift
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

/**
 The `SBAExternalIDStep` is used to handle registering a user where the user must be linked 
 to the app via an external ID. This is used primarily by research clinics that require registering
 users anonymously without using an email account. This step requires entering the external ID twice
 to validate the ID. Then the view controller will attempt to login the user by using the external
 ID to match to a server-side list.
 */
open class SBAExternalIDStep: ORKPageStep {
    
    static let initialStepIdentifier = SBAProfileInfoOption.externalID.rawValue
    static let confirmStepIdentifier = "confirm"
    
    override open var title: String? {
        didSet { didSetTitle() }
    }
    fileprivate func didSetTitle() {
        self.steps.first?.title = title
        self.steps.last?.title = title
    }
    
    override open var text: String? {
        didSet { didSetText() }
    }
    fileprivate func didSetText() {
        self.steps.first?.text = text
    }
    
    // Step is never optional
    override open var isOptional: Bool {
        get { return false }
        set {}
    }
    
    public init(inputItem: SBASurveyItem) {
        let steps = SBAExternalIDStep.steps(SBAExternalIDOptions(options: inputItem.options as [NSObject : AnyObject]?))
        super.init(identifier: inputItem.identifier, steps: steps)
        if let title = inputItem.stepTitle {
            self.title = title
            didSetTitle()
        }
        if let text = inputItem.stepText {
            self.text = text
            didSetText()
        }
    }

    public init(identifier: String) {
        let steps = SBAExternalIDStep.steps()
        super.init(identifier: identifier, steps: steps)
    }
    
    fileprivate class func steps(_ options: SBAExternalIDOptions = SBAExternalIDOptions()) -> [ORKStep] {
        // Create the steps that are used by this method
        let stepIdentifiers = [SBAExternalIDStep.initialStepIdentifier, SBAExternalIDStep.confirmStepIdentifier]
        let steps = stepIdentifiers.map { (stepIdentifier) -> ORKStep in
            let options = SBAProfileInfoOptions(externalIDOptions: options)
            let step = ORKFormStep(identifier: stepIdentifier)
            step.formItems = options.makeFormItems(shouldConfirmPassword: false)
            step.isOptional = false
            return step
        }
        
        // Set the default text for the confirmation step
        steps.last?.text = Localization.localizedString("SBA_CONFIRM_EXTERNALID_TEXT")
        
        return steps
    }
    
    override open func stepViewControllerClass() -> AnyClass {
        return SBAExternalIDStepViewController.classForCoder()
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
}

/**
 Object with the options for the external ID form item `ORKAnswerFormat`
 */
struct SBAExternalIDOptions {
    
    /**
     By default, the autocapitalization type is all characters
    */
    static let defaultAutocapitalizationType: UITextAutocapitalizationType = .allCharacters
    
    /**
     By default, the keyboard type is ASCII
    */
    static let defaultKeyboardType: UIKeyboardType = .asciiCapable
    
    /**
     Auto-capitalization type for the text field
    */
    let autocapitalizationType: UITextAutocapitalizationType
    
    /**
     Keyboard type for the text field
    */
    let keyboardType: UIKeyboardType
    
    init() {
        self.autocapitalizationType = SBAExternalIDOptions.defaultAutocapitalizationType
        self.keyboardType = SBAExternalIDOptions.defaultKeyboardType
    }
    
    init(autocapitalizationType: UITextAutocapitalizationType, keyboardType: UIKeyboardType) {
        self.autocapitalizationType = autocapitalizationType
        self.keyboardType = keyboardType
    }
    
    init(options: [AnyHashable: Any]?) {
        self.autocapitalizationType = {
            if let autocap = options?["autocapitalizationType"] as? String {
                return UITextAutocapitalizationType(key: autocap)
            }
            else {
                return SBAExternalIDOptions.defaultAutocapitalizationType
            }
        }()
        self.keyboardType = {
            if let keyboard = options?["keyboardType"] as? String {
                return UIKeyboardType(key: keyboard)
            }
            else {
                return SBAExternalIDOptions.defaultKeyboardType
            }
        }()
    }
}

/**
 Default class used to handle registration or login via External ID
 */
open class SBAExternalIDStepViewController: ORKPageStepViewController, SBAAccountController {
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // MARK: Navigation
    
    // This step is publicly available so that overriding subclasses can access it, but it is marked final
    // because it should not be overridden by subclasses.
    final public func goInitialStep() {
        guard let step = pageStep?.firstStep()
            else {
                assert(false, "Should not be able to get to the goInitialStep method without a valid first step")
                return
        }
        self.go(to: step, direction: .reverse, animated: true)
    }
    
    // Override the default method for goForward and attempt user registration. Do not allow subclasses
    // to override this method
    final public override func goForward() {
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
        catch SBAExternalIDError.notMatching {
            self.handleFailedValidation(failedConfirmationMessage)
        }
        catch SBAExternalIDError.invalid(let reason) {
            self.handleFailedValidation(reason)
        }
        catch let error as NSError {
            self.handleFailedValidation(error.localizedFailureReason)
        }
    }
    
    fileprivate func loginUser(externalId: String, isTestUser:Bool) {
        showLoadingView()
        sharedUser.loginUser(externalId: externalId) { [weak self] error in
            if let error = error {
                self?.handleFailedRegistration(error)
            }
            else if isTestUser, let testUserDataGroup = self?.sharedBridgeInfo.testUserDataGroup {
                self?.sharedUser.addDataGroup(testUserDataGroup, completion: { (_) in
                    self?.goNext()
                })
            }
            else {
                self?.goNext()
            }
        }
    }
    
    open func goNext() {
        super.goForward()
    }
    
    
    // MARK: Validation
    
    // Default RegEx is alphanumeric for the external ID
    open var validationRegEx: String = "^[a-zA-Z0-9]+$"
    
    open func validateParameter(externalId: String) throws {
        guard NSPredicate(format: "SELF MATCHES %@", self.validationRegEx).evaluate(with: externalId) else {
            throw SBAExternalIDError.invalid(reason: nil)
        }
    }
    
    func externalId() throws -> String {
        
        guard let externalIds = externalIdAnswers(),
              let externalId = externalIds.first
        else {
            throw SBAExternalIDError.invalid(reason: nil)
        }
        
        // Check that the external ID is valid
        try validateParameter(externalId: externalId)
        
        // Check that the external ID matches
        guard (externalIds.count == 2 && externalId == externalIds.last) else {
            throw SBAExternalIDError.notMatching
        }
        
        return externalId
    }
    
    fileprivate func externalIdAnswers() -> [String]? {
        return self.result?.results?.mapAndFilter { (result) -> String? in
            guard let textResult = result as? ORKTextQuestionResult,
                  let answer = textResult.textAnswer?.trim()
            else {
                return nil
            }
            return answer
        }
    }
    
    // MARK: Test User
    
    // Default RegEx is nil for checking if this is a test user
    open var testUserRegEx: String?
    
    open func isTestUser(externalId: String) -> Bool {
        guard let testUserRegEx = self.testUserRegEx else { return false }
        return NSPredicate(format: "SELF MATCHES %@", testUserRegEx).evaluate(with: externalId)
    }
    
    open func promptUserForTestDataGroup(externalId: String, loginHandler: @escaping ((_ isTestUser: Bool) -> Void)) {
        // If this may be a test user, need to first display a prompt to confirm that the user is really QA
        // and then on answering the question, complete the registration
        let title = Localization.localizedString("SBA_TESTER_ALERT_TITLE")
        let messageFormat = Localization.localizedString("SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@")
        let message = String.localizedStringWithFormat(messageFormat, Localization.localizedAppName, Localization.buttonYes())
        self.showAlertWithYesNo(title: title, message: message, actionHandler: loginHandler)
    }
    
    // MARK: Error handling
    
    open var failedValidationMessage = Localization.localizedString("SBA_REGISTRATION_INVALID_CODE")
    open var failedConfirmationMessage = Localization.localizedString("SBA_REGISTRATION_MATCH_FAILED")
    open var failedRegistrationTitle = Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")
}

public enum SBAExternalIDError: Error {
    case invalid(reason: String?)
    case notMatching
}

extension ORKPageStep {
    public func firstStep() -> ORKStep? {
        return self.stepAfterStep(withIdentifier: nil, with: ORKTaskResult(identifier: self.identifier))
    }
}


