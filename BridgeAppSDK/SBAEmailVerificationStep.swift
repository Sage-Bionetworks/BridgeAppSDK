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

open class SBAEmailVerificationStep: SBAInstructionStep {
    // TODO: syoung 06/08/2016 Implement
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        commonInit(nil)
    }
    
    public init(inputItem: SBASurveyItem, appInfo: SBAAppInfoDelegate?) {
        super.init(identifier: inputItem.identifier)
        commonInit(appInfo)
    }
    
    func commonInit(_ appInfoDelegate: SBAAppInfoDelegate?) {
        let appInfo = appInfoDelegate ?? UIApplication.shared.delegate as! SBAAppInfoDelegate
        
        if self.title == nil {
            self.title = Localization.localizedString("VERIFICATION_STEP_TITLE")
        }
        if self.text == nil {
            let appName = Localization.localizedAppName
            let email = appInfo.currentUser.email!
            self.text = Localization.localizedStringWithFormatKey("REGISTRATION_VERIFICATION_TEXT_%@_%@", appName, email)
        }
        if self.detailText == nil {
            self.detailText = Localization.localizedString("REGISTRATION_VERIFICATION_DETAIL_%@")
        }
        if self.image == nil {
            self.image = appInfo.bridgeInfo.logoImage
        }
        if self.learnMoreAction == nil {
            // TODO: syoung 09/08/2016 Add learn more action for resending email or changing email
        }
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return SBAEmailVerificationStepViewController.classForCoder()
    }
    
    // Mark: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

open class SBAEmailVerificationStepViewController: SBAInstructionStepViewController, SBAUserRegistrationController {
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // Mark: Navigation overrides - cannot go back and override go forward to register
    
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
    
    open override var cancelButtonItem: UIBarButtonItem? {
        get { return nil }
        set {}
    }
    
    open override var backButtonItem: UIBarButtonItem? {
        get { return nil }
        set {}
    }
    
    override open func goBackward() {
        // Do nothing
    }
    
    // MARK: Failure handling
    
    open var failedValidationMessage = Localization.localizedString("SBA_REGISTRATION_UNKNOWN_FAILED")
    open var failedRegistrationTitle = Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")
}
