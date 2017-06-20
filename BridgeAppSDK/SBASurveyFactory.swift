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
    case onboardingCompletion   = "onboardingCompletion"    // SBAOnboardingCompletionStep
    case profileItem            = "profileItem"             // Mapped to the profile questions list
    case brainBaseline          = "brainBaseline"           // SBABrainBaselineStep
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
    
    open static var profileQuestionSurveyItems: [SBASurveyItem]? = {
        guard let json = SBAResourceFinder.shared.json(forResource: SBAProfileQuestionsJSONFilename) else { return nil }
        return json["steps"] as? [NSDictionary]
    }()
    
    /**
     Factory method for creating an ORKTask from an SBBSurvey
     @param survey      An `SBBSurvey` bridge model object
     @return            Task created with this survey
     */
    open func createTaskWithSurvey(_ survey: SBBSurvey) -> SBANavigableOrderedTask {
        
        // Build the steps
        let count = survey.elements.count
        var usesTitleAndText: Bool = false
        let steps: [ORKStep] = survey.elements.enumerated().mapAndFilter({ (offset: Int, element: Any) -> ORKStep? in
            guard let surveyItem = element as? SBBSurveyElement else { return nil }
            let step = self.createSurveyStepWithSurveyElement(surveyItem, index: offset, count: count)
            if let qStep = step as? ORKQuestionStep, qStep.title != nil {
                usesTitleAndText = true
            }
            return step
        })
        
        // If some of the questions use the title field, then set all the questions to 
        // use the title field if the prompt was initially set to the text.
        if usesTitleAndText {
            for step in steps {
                if step is ORKQuestionStep, step.title == nil {
                    step.title = step.text
                    step.text = nil
                }
            }
        }
        
        return SBANavigableOrderedTask(identifier: survey.identifier, steps: steps)
    }
    
    /**
     Factory method for creating a survey step with an SBBSurveyElement
     @param inputItem       A `SBBSurveyElement` bridge model object
     @return                An `ORKStep`
     */
    @available(*, unavailable, message: "Use `createSurveyStepWithSurveyElement(_:index:count:) instead.")
    open func createSurveyStepWithSurveyElement(_ inputItem: SBBSurveyElement, isLastStep:Bool = false) -> ORKStep? {
        return nil
    }
    
    /**
     Factory method for creating a survey step with an SBBSurveyElement
     @param inputItem       A `SBBSurveyElement` bridge model object
     @param index           The index into the task
     @param count           The total number of steps
     @return                An `ORKStep`
     */
    open func createSurveyStepWithSurveyElement(_ inputItem: SBBSurveyElement, index: Int, count: Int) -> ORKStep? {
        guard let surveyItem = inputItem as? SBASurveyItem else { return nil }
        return self.createSurveyStep(surveyItem)
    }
    
    open override func createTaskWithActiveTask(_ activeTask: SBAActiveTask, taskOptions: ORKPredefinedTaskOption) -> (NSCopying & NSSecureCoding & ORKTask)? {
        if activeTask.taskType == .activeTask(.cardio) {
            return activeTask.createBridgeCardioChallenge(options: taskOptions, factory: self)
        }
        return super.createTaskWithActiveTask(activeTask, taskOptions: taskOptions)
    }
    
    open override func createSurveyStepWithCustomType(_ inputItem: SBASurveyItem) -> ORKStep? {
        guard let bridgeSubtype = inputItem.surveyItemType.bridgeSubtype() else {
            return super.createSurveyStepWithCustomType(inputItem)
        }
        switch (bridgeSubtype) {
        case .onboardingCompletion:
            return SBAOnboardingCompleteStep(inputItem: inputItem)
            
        case .profileItem:
            return profileItemStep(for: inputItem.identifier)?.copy() as? ORKStep
            
        case .brainBaseline:
            return SBABrainBaselineStep(inputItem: inputItem)
        }
    }
    
    open func profileItemStep(for profileKey: String) -> ORKStep? {
        guard let inputItem = SBASurveyFactory.profileQuestionSurveyItems?.find(withIdentifier: profileKey) else {
            return nil
        }
        return self.createSurveyStep(inputItem)
    }
    
    open override func createFormStep(_ inputItem:SBAFormStepSurveyItem, isSubtaskStep: Bool = false) -> ORKStep? {
        
        if inputItem.surveyItemType.formSubtype() == .mood {
            return SBAMoodScaleStep(inputItem: inputItem)
        }
        
        return super.createFormStep(inputItem, isSubtaskStep: isSubtaskStep)
    }
    
    open override func createAccountStep(inputItem: SBASurveyItem, subtype: SBASurveyItemType.AccountSubtype) -> ORKStep? {
        switch (subtype) {
        case .registration:
            return SBARegistrationStep(inputItem: inputItem, factory: self)
            
        case .login:
            // For the login case, return a different implementation depending upon whether or not
            // this is login via username or externalID. For some studies, PII (email) is not collected
            // and instead the participant is assigned an external identifier that is used to log them in.
            let profileOptions = SBAProfileInfoOptions(inputItem: inputItem)
            if profileOptions.includes.contains(.externalID) {
                return SBAExternalIDLoginStep(inputItem: inputItem)
            }
            else {
                return SBALoginStep(inputItem: inputItem, factory: self)
            }
            
        case .emailVerification:
            return SBAEmailVerificationStep(inputItem: inputItem)
                
        case .externalID:
            return SBAExternalIDAssignStep(inputItem: inputItem, factory: self)
            
        case .permissions:
            // For permissions, we want to replace the default permissions step with a 
            // single step (if possible) to capture info specific to that step
            if let singleStep = SBASinglePermissionStep(inputItem: inputItem) {
                return singleStep
            }
            else {
                return super.createAccountStep(inputItem:inputItem, subtype: subtype)
            }
                
        default:
            return super.createAccountStep(inputItem:inputItem, subtype: subtype)
        }
    }
    
    // Override the base class to implement creating consent steps
    override open func createConsentStep(inputItem: SBASurveyItem, subtype: SBASurveyItemType.ConsentSubtype) -> ORKStep? {
        switch (subtype) {
            
        case .visual:
            // Use the superclass instance of the review step
            return super.createConsentStep(inputItem: inputItem, subtype: subtype)
            
        case .sharingOptions:
            return SBAConsentSharingStep(inputItem: inputItem)
            
        case .review:
            if let consentReview = inputItem as? SBAConsentReviewOptions,
                consentReview.usesDeprecatedOnboarding {
                // Use the superclass instance of the review step
                return super.createConsentStep(inputItem: inputItem, subtype: subtype)
            }
            else {
                let review = inputItem as! SBAFormStepSurveyItem
                let step = SBAConsentReviewStep(inputItem: review, inDocument: self.consentDocument, factory: self)
                return step;
            }
        }
    }
    
}
