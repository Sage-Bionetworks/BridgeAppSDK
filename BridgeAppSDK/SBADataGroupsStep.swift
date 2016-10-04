//
//  SBADataGroupsStep.swift
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

public class SBADataGroupsStep: SBANavigationFormStep {
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    
    public override init(inputItem: SBASurveyItem) {
        super.init(inputItem: inputItem)
        guard let surveyForm = inputItem as? SBAFormStepSurveyItem else {
            return
        }
        
        // map the values
        surveyForm.mapStepValues(with: self)
        self.formItems = [surveyForm.createFormItem(text: nil, subtype: .multipleChoice)]
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     The subset of data groups that are selected/deselected using this step.
    */
    public var dataGroups: Set<String> {
        guard let answerFormat = self.formItems?.first?.answerFormat as? ORKTextChoiceAnswerFormat else {
            return []
        }
        let dataGroups = answerFormat.textChoices.reduce(Set<String>()) { $0.union(convertValueToArray($1.value)) }
        return dataGroups
    }
    
    /**
     Create an `ORKStepResult` from the given set of data groups.
     @return    Step result for this step.
     */
    public func stepResult(currentGroups: [String]?) -> ORKStepResult? {
        
        // Look for a current choice from the input groups
        let currentChoices: [Any]? = {
            // Check that the current group is non-nil
            guard currentGroups != nil, let answerFormat = self.formItems?.first?.answerFormat as? ORKTextChoiceAnswerFormat
            else {
                return nil
            }
            // Create the intersection set that is the values from the current group that are in this steps subset of data groups
            let currentSet = Set(currentGroups!).intersection(self.dataGroups)
            // If there is no overlap then return nil
            guard currentSet.count > 0 else { return nil }
            // Otherwise, look for an answer that maps to the current set
            return answerFormat.textChoices.mapAndFilter({ (textChoice) -> Any? in
                let value = Set(convertValueToArray(textChoice.value))
                guard value.count > 0, currentSet.intersection(value) == value else { return nil }
                return textChoice.value
            })
        }()
        
        // If nothing is found then return a nil results set
        guard currentChoices != nil else {
            return ORKStepResult(stepIdentifier: self.identifier, results: nil)
        }
        
        // If found, then create a questionResult for that choice
        let questionResult = ORKChoiceQuestionResult(identifier: self.identifier)
        questionResult.choiceAnswers = currentChoices
        return ORKStepResult(stepIdentifier: self.identifier, results: [questionResult])
    }
    
    /**
     Return the union/minus set that includes the data groups from the current set of data groups
     that are *not* edited in this step unioned with the new data groups that are selected values
     for this step. For example, if this step is used to select either "groupA" OR "groupB" and 
     the current data groups are "test_user" and "groupA", then the returned groups will include
     "test_user" AND whichever group has been selected via the step result.
     
     @param  previousGroups The current data groups set
     @param  stepResult     The step result to use to get the new selection
     @return                The set of data groups based on the current and step result
     */
    public func union(previousGroups: Set<String>?, stepResult: ORKStepResult) -> Set<String> {
        let questionResult = stepResult.results?.first as? ORKChoiceQuestionResult
        let choices = convertValueToArray(questionResult?.choiceAnswers?.first)
        
        // Return the choices if there isn't a minus set
        guard previousGroups != nil else { return Set(choices) }
        
        // Create a set with only the groups that are *not* selected as a part of this step
        let minusSet = Set(previousGroups!).subtracting(self.dataGroups)
        
        // And the union that minus set with the new choices
        return minusSet.union(choices)
    }
    
    fileprivate func convertValueToArray(_ value: Any?) -> [String] {
        if let arr = value as? [String] {
            return arr
        }
        else if let str = value as? String, str != "" {
            return [str]
        }
        return []
    }
}
