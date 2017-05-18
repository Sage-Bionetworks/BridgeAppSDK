//
//  SBAExternalIDAssignStep.swift
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

open class SBAExternalIDAssignStep: SBAProfileFormStep {
    
    override open func defaultOptions(_ inputItem: SBASurveyItem?) -> [SBAProfileInfoOption] {
        return [.externalID]
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return SBAExternalIDAssignStepViewController.classForCoder()
    }

}

/**
 Allow developers to create their own step view controllers that do not inherit from
 `ORKFormStepViewController`.
 */
public protocol SBAExternalIDAssignStepController: SBAOnboardingStepController {
    
    /**
     In general, this method should call through to super.goForward(). See `SBARegistrationStepViewController`
     */
    func goNext()
}

extension SBAExternalIDAssignStepController {
    
    public var failedValidationMessage: String {
        return Localization.localizedString("SBA_REGISTRATION_INVALID_CODE")
    }
    
    public var failedRegistrationTitle: String {
        return Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")
    }

    public func updateExternalID() {
        
        // If the external Id is nil then do not try to set it. Just go to the next step.
        guard let externalId = self.externalID else {
            self.goNext()
            return
        }
        
        // If the user login is not verified, then this needs to be stored until that 
        // step in the onboarding process is done. Store the result and continue.
        guard sharedUser.isLoginVerified else {
            sharedUser.externalId = externalId
            self.goNext()
            return
        }
        
        showLoadingView()
        sharedUser.setExternalID(externalId) { [weak self] (error) in
            if let error = error {
                self?.handleFailedRegistration(error)
            }
            else {
                self?.goNext()
            }
        }
    }
    
}

open class SBAExternalIDAssignStepViewController: ORKFormStepViewController, SBAExternalIDAssignStepController {
    
    // MARK: SBASharedInfoController
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // Override the default method for goForward and attempt user registration. Do not allow subclasses
    // to override this method
    final public override func goForward() {
        updateExternalID()
    }
    
    open func goNext() {
        // Then call super to go forward
        super.goForward()
    }
}
