//
//  SBAQuizStep.swift
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

public protocol SBASurveyNavigationStep: SBANavigationRule {
    
    // Step identifier to go to if the quiz passed
    var skipToStepIdentifier: String { get set }
    
    // Should the rule skip if results match expected
    var skipIfPassed: Bool { get set }
    
    // Predicate to use for getting the matching step results
    var surveyStepResultFilterPredicate: NSPredicate { get }
    
    // Form step that matches with the given result
    func matchingSurveyStep(stepResult: ORKStepResult) -> ORKFormStep?
}

public final class SBASurveyFormStep: ORKFormStep, SBASurveyNavigationStep {
    
    public var surveyStepResultFilterPredicate: NSPredicate {
        return NSPredicate(format: "identifier = %@", self.identifier)
    }
    
    public func matchingSurveyStep(stepResult: ORKStepResult) -> ORKFormStep? {
        guard (stepResult.identifier == self.identifier) else { return nil }
        return self
    }
    
    // MARK: Stuff you can't extend on a protocol
    
    public var skipToStepIdentifier: String = ORKNullStepIdentifier
    public var skipIfPassed: Bool = false
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    init(surveyItem: SBASurveyItem) {
        super.init(identifier: surveyItem.identifier)
        self.sharedCopyFromSurveyItem(surveyItem)
    }
    
    // MARK: NSCopying
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone)
        return self.sharedCopying(copy)
    }
    
    // MARK: NSSecureCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.sharedDecoding(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        self.sharedEncoding(aCoder)
    }
}

public final class SBASurveySubtaskStep: SBASubtaskStep, SBASurveyNavigationStep {
    
    public var surveyStepResultFilterPredicate: NSPredicate {
        return NSPredicate(format: "identifier BEGINSWITH %@", "\(self.identifier).")
    }
    
    public func matchingSurveyStep(stepResult: ORKStepResult) -> ORKFormStep? {
        return self.stepWithIdentifier(stepResult.identifier) as? ORKFormStep
    }
    
    // MARK: Stuff you can't extend on a protocol
    
    public var skipToStepIdentifier: String = ORKNullStepIdentifier
    public var skipIfPassed: Bool = false
    
    override public init(identifier: String, steps: [ORKStep]?) {
        super.init(identifier: identifier, steps: steps)
    }
    
    init(surveyItem: SBASurveyItem, steps: [ORKStep]?) {
        super.init(identifier: surveyItem.identifier, steps: steps)
        self.sharedCopyFromSurveyItem(surveyItem)
    }
    
    // MARK: NSCopying
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone)
        return self.sharedCopying(copy)
    }
    
    // MARK: NSSecureCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.sharedDecoding(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        self.sharedEncoding(aCoder)
    }
}

public final class SBASurveyFormItem : ORKFormItem {
    
    public var rulePredicate: NSPredicate?
    
    override public init(identifier: String, text: String?, answerFormat: ORKAnswerFormat?) {
        super.init(identifier: identifier, text: text, answerFormat: answerFormat)
    }
    
    override public init(identifier:String, text:String?, answerFormat:ORKAnswerFormat?, optional:Bool) {
        super.init(identifier:identifier, text: text, answerFormat: answerFormat, optional:optional);
    }
    
    // MARK: NSCopying
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone)
        guard let formItem = copy as? SBASurveyFormItem else { return copy }
        formItem.rulePredicate = self.rulePredicate
        return formItem
    }
    
    // MARK: NSSecureCoding
    
    required public init?(coder aDecoder: NSCoder) {
        rulePredicate = aDecoder.decodeObjectForKey("rulePredicate") as? NSPredicate
        super.init(coder: aDecoder);
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        if let rulePredicate = self.rulePredicate {
            aCoder.encodeObject(rulePredicate, forKey: "rulePredicate")
        }
    }
}

public extension SBASurveyNavigationStep {
    
    public func nextStepIdentifier(taskResult: ORKTaskResult, additionalTaskResults:[ORKTaskResult]?) -> String? {
        guard let results = taskResult.results else { return nil }
        let predicate = self.surveyStepResultFilterPredicate
        let passed = results.filter({ predicate.evaluateWithObject($0) && !matchesExpectedResult($0)}).count == 0
        if (passed && self.skipIfPassed) || (!passed && !self.skipIfPassed) {
            return self.skipToStepIdentifier
        }
        return nil;
    }
    
    func matchesRulePredicate(item: AnyObject, result: ORKResult?) -> Bool? {
        if let rule = item as? SBASurveyFormItem,
            let predicate = rule.rulePredicate {
                // If the result is nil then it fails
                guard let result = result else { return false }
                // Otherwise, evaluate against the predicate
                return predicate.evaluateWithObject(result)
        }
        return nil
    }
    
    func matchesExpectedResult(result: ORKResult) -> Bool {
        if let stepResult = result as? ORKStepResult,
            let step = self.matchingSurveyStep(stepResult) {
                // evaluate each form item
                if let formItems = step.formItems {
                    for formItem in formItems {
                        let formResult = stepResult.resultForIdentifier(formItem.identifier)
                        if let matchingRule = matchesRulePredicate(formItem, result:formResult) where !matchingRule {
                            // If a form item does not match the expected result then exit, otherwise keep going
                            return false
                        }
                    }
                }
        }
        return true;
    }
    
    func sharedCopying(copy: AnyObject) -> AnyObject {
        guard let step = copy as? SBASurveyNavigationStep else { return copy }
        step.skipToStepIdentifier = self.skipToStepIdentifier
        return step
    }
    
    func sharedDecoding(coder aDecoder: NSCoder) {
        self.skipToStepIdentifier = aDecoder.decodeObjectForKey("skipToStepIdentifier") as! String
        self.skipIfPassed = aDecoder.decodeBoolForKey("skipIfPassed")
    }
    
    func sharedEncoding(aCoder: NSCoder) {
        aCoder.encodeObject(self.skipToStepIdentifier, forKey: "skipToStepIdentifier")
        aCoder.encodeBool(self.skipIfPassed, forKey: "skipIfPassed")
    }
    
    func sharedCopyFromSurveyItem(surveyItem: AnyObject) {
        guard let surveyItem = surveyItem as? SBASurveyItem else { return }
        if let skipIdentifier = surveyItem.skipIdentifier {
            self.skipToStepIdentifier = skipIdentifier
        }
        self.skipIfPassed = surveyItem.skipIfPassed
    }
}
