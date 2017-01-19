//
//  SBAConsentDocument.swift
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
import ResearchUXFactory

/**
 Extension used by the `SBAOnboardingManager` to build the appropriate steps for a consent flow.
 */
extension SBASurveyFactory {
    
    /**
     Return visual consent step
     */
    open func visualConsentStep() -> ORKVisualConsentStep {
        return self.steps?.find({ $0 is ORKVisualConsentStep }) as? ORKVisualConsentStep ??
            ORKVisualConsentStep(identifier: SBAOnboardingSectionBaseType.consent.rawValue, document: self.consentDocument)
    }
    
    /**
    Return subtask step with only the steps required for reconsent
    */
    open func reconsentStep() -> SBASubtaskStep {
        // Strip out the registration steps
        let steps = self.steps?.filter({ !isRegistrationStep($0) })
        let task = SBANavigableOrderedTask(identifier: SBAOnboardingSectionBaseType.consent.rawValue, steps: steps)
        return SBASubtaskStep(subtask: task)
    }
    
    /**
     Return subtask step with only the steps required for consent or reconsent on login
     */
    open func loginConsentStep() -> SBASubtaskStep {
        // Strip out the registration steps
        let steps = self.steps?.filter({ !isRegistrationStep($0) })
        let task = SBANavigableOrderedTask(identifier: SBAOnboardingSectionBaseType.consent.rawValue, steps: steps)
        return SBAConsentSubtaskStep(subtask: task)
    }
    
    private func isRegistrationStep(_ step: ORKStep) -> Bool {
        return (step is SBARegistrationStep) || (step is ORKRegistrationStep) || (step is SBAExternalIDStep)
    }
    
    /**
     Return subtask step with only the steps required for initial registration
    */
    open func registrationConsentStep() -> SBASubtaskStep {
        // Strip out the reconsent steps
        let steps = self.steps?.filter({ (step) -> Bool in
            // If this is a step that conforms to the custom step protocol and the custom step type is 
            // a reconsent subtype, then this is not to be included in the registration steps
            if let customStep = step as? SBACustomTypeStep, let customType = customStep.customTypeIdentifier, customType.hasPrefix("reconsent") {
                return false
            }
            return true
        })
        let task = SBANavigableOrderedTask(identifier: SBAOnboardingSectionBaseType.consent.rawValue, steps: steps)
        return SBASubtaskStep(subtask: task)
    }
}
