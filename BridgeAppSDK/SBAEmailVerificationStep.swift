//
//  SBAEmailVerificationStep.swift
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
 The `SBAEmailVerificationStep` is used to stop the user's progress through registration
 until they confirm that they have verified their email address.
 */
open class SBAEmailVerificationStep: SBAInstructionStep, SBASharedInfoController {
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        commonInit()
    }
    
    public init(inputItem: SBASurveyItem, appInfo: SBAAppInfoDelegate?) {
        super.init(identifier: inputItem.identifier)
        if appInfo != nil {
            self.sharedAppDelegate = appInfo!
        }
        commonInit()
    }
    
    func commonInit() {
        if self.title == nil {
            self.title = Localization.localizedString("VERIFICATION_STEP_TITLE")
        }
        if self.detailText == nil {
            self.detailText = Localization.localizedStringWithFormatKey("REGISTRATION_VERIFICATION_DETAIL_%@", Localization.buttonNext())
        }
        if self.footnote == nil {
            self.footnote = Localization.localizedString("REGISTRATION_VERIFICATION_FOOTNOTE")
        }
        if self.iconImage == nil {
            self.iconImage = self.sharedAppDelegate.bridgeInfo.logoImage
        }
        if self.learnMoreAction == nil {
            self.learnMoreAction = SBAEmailVerificationLearnMoreAction(identifier: "additionalEmailActions")
            self.learnMoreAction?.learnMoreButtonText = Localization.localizedString("REGISTRATION_EMAIL_ACTIONS_BUTTON_TEXT")
        }
    }
    
    // Override the text to display the user's email and the app name.
    open override var text: String? {
        get {
            guard let email = sharedUser.email else { return nil }
            let appName = Localization.localizedAppName
            return Localization.localizedStringWithFormatKey("REGISTRATION_VERIFICATION_TEXT_%@_%@", appName, email)
        }
        set {} // do nothing
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return SBAEmailVerificationStepViewController.classForCoder()
    }
    
    // Mark: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

/**
 The `SBAEmailVerificationStepViewController` works with the `SBAEmailVerificationStep` to handle
 email verification, change email, and resend verification email.
 */
open class SBAEmailVerificationStepViewController: SBAInstructionStepViewController, SBAAccountController {
    
    // MARK: SBASharedInfoController
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // MARK: SBAUserProfileController
    
    open var failedValidationMessage = Localization.localizedString("SBA_REGISTRATION_UNKNOWN_FAILED")
    open var failedRegistrationTitle = Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")
    
    
    // MARK: Navigation overrides - cannot go back and override go forward to register
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Continue button should always say "Next"
        self.continueButtonTitle = Localization.buttonNext()
        
        // set the back and cancel buttons to empty items
        self.backButtonItem = UIBarButtonItem()
    }
    
    // Override the default method for goForward and attempt user registration. Do not allow subclasses
    // to override this method
    final public override func goForward() {
    
        showLoadingView()
        sharedUser.verifyRegistration { [weak self] error in

            if let error = error {
                self?.handleFailedRegistration(error)
            }
            else {
                self?.goNext()
            }
        }
    }
    
    func goNext() {
        // Then call super to go forward
        super.goForward()
    }
    
    override open func goBackward() {
        // Do nothing
    }
    
    /**
     Method for handling when the user taps the "Wrong email" button
    */
    open func handleWrongEmailAction() {
        let task = ORKOrderedTask(identifier: "changeEmail", steps: [instantiateChangeEmailStep()])
        let taskVC = SBATaskViewController(task: task, taskRun: nil)
        self.present(taskVC, animated: true, completion: nil)
    }
    
    /**
     Method for instantiating the step used to display a change of email
    */
    open func instantiateChangeEmailStep() -> ORKStep {
        return SBAChangeEmailStep(identifier: "changeEmail")
    }
    
    /**
     Method for handling when the user taps the "resend" button
    */
    open func handleResendEmailAction() {
        showLoadingView()
        sharedUser.resendVerificationEmail { [weak self] (error) in
            if let error = error {
                self?.handleFailedRegistration(error)
            }
            else {
                self?.hideLoadingView()
            }
        }
    }

}

/**
 The `SBAEmailVerificationLearnMoreAction` shows an action sheet when the user taps the 
 email verification "learn more" button. This button action is used to display options to
 the user for handling problems with registration.
 */
@objc
open class SBAEmailVerificationLearnMoreAction: SBALearnMoreAction {
    
    override open func learnMoreAction(for step: SBALearnMoreActionStep, with taskViewController: ORKTaskViewController) {
        guard let emailVC = taskViewController.currentStepViewController as? SBAEmailVerificationStepViewController else { return }
        
        let alertController = UIAlertController(title: nil,
                                                message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: Localization.buttonCancel(), style: .cancel) { (_) in
            // do nothing
        }
        
        let wrongEmailAction = UIAlertAction(title: Localization.localizedString("REGISTRATION_WRONG_EMAIL"), style: .default) { (_) in
            emailVC.handleWrongEmailAction()
        }
        
        let resentEmailAction = UIAlertAction(title: Localization.localizedString("REGISTRATION_RESEND_EMAIL"), style: .default) { (_) in
            emailVC.handleResendEmailAction()
        }
        
        alertController.addAction(wrongEmailAction)
        alertController.addAction(resentEmailAction)
        alertController.addAction(cancelAction)
        
        taskViewController.present(alertController, animated: true, completion: nil)
    }
    
}



