//
//  SBAExternalIDOnboardingController.swift
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

/**
 * Allow for any controller that implements this protocol to use the shared implementation for
 * registering a user via an external id rather than an email/password.
 */
public protocol SBAExternalIDOnboardingController: class, SBASharedInfoController, SBALoadingViewPresenter, SBAAlertPresenter, UITextFieldDelegate {
    
    // Text field that is used to enter the registration code
    var registrationCodeTextField: UITextField! { get }
    
    func goNext()
}

public extension SBAExternalIDOnboardingController {
    
    public func handleViewDidAppear() {
        registrationCodeTextField.becomeFirstResponder()
    }

    public func registerUser() {
        
        guard let text: String = self.registrationCodeTextField.text
            where text.characters.count > 0 else {
                let message = NSLocalizedString("Please enter a valid registration code.", comment: "Message for invalid registration code")
                showAlertWithOk(nil, message: message, actionHandler: nil)
                return
        }
        
        registrationCodeTextField.resignFirstResponder()
        showLoadingView()
        
        sharedUser.loginUser(externalId: text) { [weak self] error in
            if let error = error {
                self?.hideLoadingView({
                    let title = NSLocalizedString("Registration Failed", comment: "Title for error when registration fails")
                    let message = error.localizedBridgeErrorMessage
                    self?.showAlertWithOk(title, message: message, actionHandler: nil)
                })
            }
            else {
                self?.goNext()
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        registerUser()
        return false
    }
}