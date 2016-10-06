//
//  SBAConsentSharingStep.swift
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

public final class SBAConsentSharingStep: ORKConsentSharingStep, SBALearnMoreActionStep {
    
    public var learnMoreAction: SBALearnMoreAction?
    
    public override func stepViewControllerClass() -> AnyClass {
        return SBAConsentSharingStepViewController.classForCoder()
    }

    public init(inputItem: SBASurveyItem) {
        
        let share = inputItem as? SBAConsentSharingOptions
        let investigatorShortDescription = share?.investigatorShortDescription
        let investigatorLongDescription = share?.investigatorLongDescription
        
        // Use placeholder values if the investigator is nil for either the short or long
        // description. This is because the super class will assert if these values are nil
        super.init(identifier: inputItem.identifier,
                   investigatorShortDescription: investigatorShortDescription ?? "PLACEHOLDER",
                   investigatorLongDescription: investigatorLongDescription ?? "PLACEHOLDER",
                   localizedLearnMoreHTMLContent: "PLACEHOLDER")
        
        if investigatorLongDescription == nil {
            // If there is no long description then use the text from the input item
            self.text = inputItem.stepText
        }
        else if let additionalText = inputItem.stepText, let text = self.text {
            // Otherwise, append the text built by the super class
            self.text = String.localizedStringWithFormat("%@\n\n%@", text, additionalText)
        }

        // If the inputItem has custom values for the choices, use those
        if let form = inputItem as? SBAFormStepSurveyItem,
            let textChoices = form.items?.map({form.createTextChoice(from: $0)}) {
            self.answerFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: textChoices)
        }
        
        // Finally, setup the learn more. The learn more html from the parent is ignored
        if let learnMoreURLString = share?.localizedLearnMoreHTMLContent {
            self.learnMoreAction = SBAURLLearnMoreAction(identifier: learnMoreURLString)
        }
    }
    
    // MARK: NSCopy
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let step = copy as? SBAConsentSharingStep else { return copy }
        step.learnMoreAction = self.learnMoreAction
        return step
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.learnMoreAction = aDecoder.decodeObject(forKey: #keyPath(learnMoreAction)) as? SBALearnMoreAction
    }
    
    override open func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.learnMoreAction, forKey: #keyPath(learnMoreAction))
    }
    
    // MARK: Equality
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBAInstructionStep else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(self.learnMoreAction, object.learnMoreAction)
    }
    
    override open var hash: Int {
        return super.hash ^
            SBAObjectHash(learnMoreAction)
    }
}

class SBAConsentSharingStepViewController: ORKQuestionStepViewController, SBASharedInfoController {
    
    lazy var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // Override the default method for goForward and attempt user registration. Do not allow subclasses
    // to override this method
    final override func goForward() {
        
        // Set the user's sharing scope
        sharedUser.dataSharingScope = {
            guard let choice = self.result?.results?.first as? ORKChoiceQuestionResult,
                let answer = choice.choiceAnswers?.first as? Bool
            else {
                return .none
            }
            return answer ? .all : .study
        }()
        
        // finally call through to super to continue once the consent sharing scope has been stored
        super.goForward()
    }
    
}
