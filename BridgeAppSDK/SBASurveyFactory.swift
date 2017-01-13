//
//  SBASurveyFactory.swift
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
import BridgeSDK
import ResearchUXFactory

/**
 Custom step types recognized by this Framework
 */
public enum BridgeSurveyItemSubtype: String {
    case login              = "login"                   // SBALoginStep
    case emailVerification  = "emailVerification"       // SBAEmailVerificationStep
    case externalID         = "externalID"              // SBAExternalIDStep
    case completion         = "onboardingCompletion"    // SBAOnboardingCompletionStep
}

/**
 Extend the `SBASurveyItemType` to return the custom bridge subtypes.
 */
extension SBASurveyItemType {
    func bridgeSubtype() -> BridgeSurveyItemSubtype? {
        if case .custom(let subtype) = self, subtype != nil {
            return BridgeSurveyItemSubtype(rawValue: subtype!)
        }
        return nil
    }
}

/**
 Override the base class for the survey factory to return a subclass that includes creating 
 surveys from an `SBBSurvey`, and also to handle account management classes that aren't 
 defined in the base class.
 */
open class SBASurveyFactory : SBABaseSurveyFactory {
    
    /**
     Factory method for creating an ORKTask from an SBBSurvey
     @param survey      An `SBBSurvey` bridge model object
     @return            Task created with this survey
     */
    open func createTaskWithSurvey(_ survey: SBBSurvey) -> SBANavigableOrderedTask {
        let lastStepIndex = survey.elements.count - 1
        let steps: [ORKStep] = survey.elements.enumerated().mapAndFilter({ (offset: Int, element: Any) -> ORKStep? in
            guard let surveyItem = element as? SBBSurveyElement else { return nil }
            return createSurveyStepWithSurveyElement(surveyItem, isLastStep: (offset == lastStepIndex))
        })
        return SBANavigableOrderedTask(identifier: survey.identifier, steps: steps)
    }
    
    /**
     Factory method for creating a survey step with an SBBSurveyElement
     @param inputItem       A `SBBSurveyElement` bridge model object
     @return                An `ORKStep`
     */
    open func createSurveyStepWithSurveyElement(_ inputItem: SBBSurveyElement, isLastStep:Bool = false) -> ORKStep? {
        guard let surveyItem = inputItem as? SBASurveyItem else { return nil }
        let step = self.createSurveyStep(surveyItem)
        if isLastStep, let instructionStep = step as? SBAInstructionStep {
            instructionStep.isCompletionStep = true
            // For the last step of a survey, put the detail text in a popup and assume that it
            // is copyright information
            if let detailText = instructionStep.detailText {
                let popAction = SBAPopUpLearnMoreAction(identifier: "learnMore")
                popAction.learnMoreText = detailText
                popAction.learnMoreButtonText = Localization.localizedString("SBA_COPYRIGHT")
                instructionStep.detailText = nil
                instructionStep.learnMoreAction = popAction
            }
        }
        return step
    }
    
    open override func createSurveyStepWithCustomType(_ inputItem: SBASurveyItem) -> ORKStep? {
        guard let bridgeSubtype = inputItem.surveyItemType.bridgeSubtype() else {
            return super.createSurveyStepWithCustomType(inputItem)
        }
        
        switch (bridgeSubtype) {
        case .login:
            return SBALoginStep(inputItem: inputItem, factory: self)
        case .emailVerification:
            return SBAEmailVerificationStep(inputItem: inputItem)
        case .externalID:
            return SBAExternalIDStep(inputItem: inputItem)
        case .completion:
            return SBAOnboardingCompleteStep(inputItem: inputItem)
        }
    }
    
    open override func createAccountStep(inputItem: SBASurveyItem, subtype: SBASurveyItemType.AccountSubtype) -> ORKStep? {
        if (subtype == .registration) {
            return SBARegistrationStep(inputItem: inputItem, factory: self)
        }
        else {
            return super.createAccountStep(inputItem:inputItem, subtype: subtype)
        }
    }
    
    // Override the base class to implement creating consent steps
    override open func createConsentStep(inputItem: SBASurveyItem, subtype: SBASurveyItemType.ConsentSubtype) -> ORKStep? {
        switch (subtype) {
            
        case .visual:
            return ORKVisualConsentStep(identifier: inputItem.identifier,
                                        document: self.consentDocument)
            
        case .sharingOptions:
            return SBAConsentSharingStep(inputItem: inputItem)
            
        case .review:
            if let consentReview = inputItem as? SBAConsentReviewOptions
                , consentReview.usesDeprecatedOnboarding {
                // If this uses the deprecated onboarding (consent review defined by ORKConsentReviewStep)
                // then return that object type.
                let signature = self.consentDocument.signatures?.first
                signature?.requiresName = consentReview.requiresSignature
                signature?.requiresSignatureImage = consentReview.requiresSignature
                return ORKConsentReviewStep(identifier: inputItem.identifier,
                                            signature: signature,
                                            in: self.consentDocument)
            }
            else {
                let review = inputItem as! SBAFormStepSurveyItem
                let step = SBAConsentReviewStep(inputItem: review, inDocument: self.consentDocument, factory: self)
                return step;
            }
        }
    }
    
}
