//
//  SBAOnboardingStepController.swift
//  BridgeAppSDK
//
//  Copyright © 2016-2017 Sage Bionetworks. All rights reserved.
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
 The `SBAOnboardingStepController` protocol is used during onboarding to update the different model objects 
 stored on with the participant info to determine the user's onboarding state. Some values (such as name 
 and age) are saved as a part of that process. This is intended for subclasses of `ORKStepViewController`
 where the specific subclasses may not share a superclass inheritance.
 */
public protocol SBAOnboardingStepController: SBAAccountStepController, SBAResearchKitResultConverter {
}

extension SBAOnboardingStepController {
    
    /**
     Look for profile keys and set them if found.
     */
    func updateUserProfileInfo() {
        guard let profileKeys = (self.step as? SBAProfileInfoForm)?.formItems?.map({ $0.identifier }) else { return }
        let excludeKeys: [SBAProfileInfoOption] = [.email, .password]
        let keySet = Set(profileKeys).subtracting(excludeKeys.map({ $0.rawValue }))
        self.update(participantInfo: self.sharedUser, with: Array(keySet))
    }
    
    /**
     During consent and registration, update the consent signature with new values
     before finishing.
     */
    func updateUserConsentSignature(_ consentSignature: SBAConsentSignature? = nil) {
        guard let signature = consentSignature ?? sharedUser.consentSignature else { return }
        
        // Look for full name and birthdate to use in populating the consent
        if let fullName = self.fullName ?? self.sharedNameDataSource?.fullName {
            signature.signatureName = fullName
        }
        if let birthdate = self.birthdate ?? sharedUser.birthdate {
            signature.signatureBirthdate = birthdate
        }
        
        // Update the signature back to the shared user
        sharedUser.consentSignature = signature
    }
}

