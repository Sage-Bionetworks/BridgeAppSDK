//
//  SBAChangeEmailStep.swift
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

/**
 The `SBAChangeEmailStep` is used to change a person's email address in case the user entered
 their email incorrectly during registration.
 */
open class SBAChangeEmailStep: ORKFormStep {
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        let profileInfo = SBAProfileInfoOptions(includes: [.email])
        self.title = Localization.localizedString("REGISTRATION_CHANGE_EMAIL_TITLE")
        self.formItems = profileInfo.makeFormItems(shouldConfirmPassword: false)
        self.isOptional = false
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return SBAChangeEmailStepViewController.classForCoder()
    }
}

/**
 Allow developers to create their own step view controllers that do not inherit from
 `ORKFormStepViewController`.
 */
public protocol SBAChangeEmailStepController: SBAUserProfileController {
    func goNext()
}

extension SBAChangeEmailStepController {
    
    public var failedValidationMessage: String {
        return Localization.localizedString("SBA_REGISTRATION_UNKNOWN_FAILED")
    }
    
    public var failedRegistrationTitle: String {
        return Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")
    }
    
    public func changeEmail() {
        showLoadingView()
        sharedUser.changeUserEmailAddress(email!) { [weak self] error in
            if let error = error {
                self?.handleFailedRegistration(error)
            }
            else {
                self?.goNext()
            }
        }
    }
}

open class SBAChangeEmailStepViewController: ORKFormStepViewController, SBAChangeEmailStepController {
    
    // MARK: SBASharedInfoController
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // Override the default method for goForward and attempt changing email.
    // Do not allow subclasses to override this method
    final public override func goForward() {
        changeEmail()
    }
    
    open func goNext() {
        // Then call super to go forward
        super.goForward()
    }
}
