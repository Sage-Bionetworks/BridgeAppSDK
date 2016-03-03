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

/**
 * The purpose of the Survey Factory is to allow subclassing for custom types of steps
 * that are not recognized by this factory and to allow usage by Obj-c classes that
 * do not recognize protocol extensions.
 */
public class SBASurveyFactory : NSObject {
    
    public var steps: [ORKStep]?
    
    public override init() {
        super.init()
    }
    
    public convenience init?(jsonNamed: String) {
        guard let json = SBAResourceFinder().jsonNamed(jsonNamed) else { return nil }
        self.init(dictionary: json)
    }
    
    public convenience init(dictionary: NSDictionary) {
        self.init()
        self.mapSteps(dictionary)
    }
    
    func mapSteps(dictionary: NSDictionary) {
        if let steps = dictionary["steps"] as? [NSDictionary] {
            self.steps = steps.map({ self.createSurveyStepWithDictionary($0) })
        }
    }

    /**
     * Factory method for creating a survey step with a dictionary
     */
    public func createSurveyStepWithDictionary(dictionary: NSDictionary) -> ORKStep {
        return self.createSurveyStep(dictionary, isSubtaskStep: false)
    }
    
    /**
     * Factory method for creating a custom type of survey question that is not 
     * defined by this class. Note: Only swift can subclass this method directly
     */
    public func createSurveyStepWithCustomType(inputItem: SBASurveyItem) -> ORKStep {
        return inputItem.createCustomStep()
    }

    func createSurveyStep(inputItem: SBASurveyItem, isSubtaskStep: Bool) -> ORKStep {
        switch (inputItem.surveyItemType) {
        case .Instruction, .Completion:
            return inputItem.createInstructionStep()
        case .Subtask:
            return inputItem.createSubtaskStep(self)
        case .Form(_):
            return inputItem.createFormStep(isSubtaskStep)
        default:
            return self.createSurveyStepWithCustomType(inputItem)
        }
    }
}

extension SBASurveyItem {
    
    func createInstructionStep() -> ORKInstructionStep {
        var instructionStep: ORKInstructionStep!
        let learnMoreHTMLContent = self.learnMoreHTMLContent
        let nextIdentifier = self.nextIdentifier
        if case .Completion = self.surveyItemType {
            instructionStep = ORKInstructionStep.completionStep().copyWithIdentifier(self.identifier)
        }
        else if (nextIdentifier != nil) || (learnMoreHTMLContent != nil) {
            let step = SBADirectNavigationStep(identifier: self.identifier, nextStepIdentifier: nextIdentifier)
            step.learnMoreHTMLContent = learnMoreHTMLContent;
            instructionStep = step
        }
        else {
            instructionStep = ORKInstructionStep(identifier: self.identifier)
        }
        instructionStep.title = self.stepTitle
        instructionStep.text = self.prompt
        instructionStep.detailText = self.detailText
        instructionStep.image = self.image
        return instructionStep
    }
    
    func createSubtaskStep(factory:SBASurveyFactory) -> SBASubtaskStep {
        assert(self.items?.count > 0, "A subtask step requires items")
        let steps = self.items?.map({ factory.createSurveyStep($0 as! SBASurveyItem, isSubtaskStep: true) })
        let step = self.usesNavigation() ?
            SBASurveySubtaskStep(surveyItem: self, steps: steps) :
            SBASubtaskStep(identifier: self.identifier, steps: steps)
        return step
    }
    
    func createFormStep(isSubtaskStep: Bool) -> ORKFormStep {
        let step = (!isSubtaskStep && self.usesNavigation()) ?
            SBASurveyFormStep(surveyItem: self) :
            ORKFormStep(identifier: self.identifier)
        if case SBASurveyItemType.Form(.Compound) = self.surveyItemType {
            step.formItems = self.items?.map({ ($0 as! SBASurveyItem).createFormItem($0.prompt) })
        }
        else {
            step.formItems = [self.createFormItem(nil)]
        }
        step.title = self.stepTitle
        step.text = self.prompt
        step.optional = self.optional
        return step
    }
    
    func createFormItem(text: String?) -> ORKFormItem {
        let answerFormat = self.createAnswerFormat()
        if let rulePredicate = self.rulePredicate {
            // If there is a rule predicate then return a survey form item
            let formItem = SBASurveyFormItem(identifier: self.identifier, text: text, answerFormat: answerFormat, optional: self.optional)
            formItem.rulePredicate = rulePredicate
            return formItem
        }
        else {
            // Otherwise, return a form item
            return ORKFormItem(identifier: self.identifier, text: text, answerFormat: answerFormat, optional: self.optional)
        }
    }
    
    func createAnswerFormat() -> ORKAnswerFormat? {
        guard let subtype = self.surveyItemType.formSubtype() else { return nil }
        switch(subtype) {
        case .Boolean:
            return ORKBooleanAnswerFormat()
        case .SingleChoiceText, .MultipleChoiceText:
            guard let textChoices = self.items?.map({createTextChoice($0)}) else { return nil }
            let style: ORKChoiceAnswerStyle = (subtype == .SingleChoiceText) ? .SingleChoice : .MultipleChoice
            return ORKTextChoiceAnswerFormat(style: style, textChoices: textChoices)
        
        default:
            assertionFailure("Form item question type \(subtype) not implemented")
            return nil
        }
    }
    
    func createTextChoice(obj: AnyObject) -> ORKTextChoice {
        guard let textChoice = obj as? SBATextChoice else {
            assertionFailure("Passing object \(obj) does not match expected protocol SBATextChoice")
            return ORKTextChoice(text: "", detailText: nil, value: NSNull(), exclusive: false)
        }
        let text = textChoice.prompt ?? "\(textChoice.value)"
        return ORKTextChoice(text: text, detailText: textChoice.detailText, value: textChoice.value, exclusive: textChoice.exclusive)
    }

    func usesNavigation() -> Bool {
        if (self.skipIdentifier != nil) || (self.rulePredicate != nil) {
                return true
        }
        guard let items = self.items else { return false }
        for item in items {
            if let item = item as? SBASurveyItem,
                let _ = item.rulePredicate {
                    return true
            }
        }
        return false
    }
}



