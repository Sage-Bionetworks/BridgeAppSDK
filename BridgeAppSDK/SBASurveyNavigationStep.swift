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
    func matchingSurveyStep(_ stepResult: ORKStepResult) -> SBAFormProtocol?
}

public final class SBASurveyQuestionStep: ORKQuestionStep, SBASurveyNavigationStep, SBAFormProtocol {
    
    public var surveyStepResultFilterPredicate: NSPredicate {
        return NSPredicate(format: "identifier = %@", self.identifier)
    }
    
    public func matchingSurveyStep(_ stepResult: ORKStepResult) -> SBAFormProtocol? {
        guard (stepResult.identifier == self.identifier) else { return nil }
        return self
    }
    
    // MARK: SBAFormProtocol
    
    public var formItems: [ORKFormItem]? {
        get {
            guard let answerFormat = self.answerFormat else { return nil }
            let formItem = SBASurveyFormItem(identifier: self.identifier, text: nil, answerFormat: answerFormat)
            formItem.rulePredicate = rulePredicate
            return [formItem]
        }
        set (newValue) {
            guard let formItem = newValue?.first else { return }
            self.answerFormat = formItem.answerFormat
            if let item = formItem as? SBASurveyFormItem {
                self.rulePredicate = item.rulePredicate
            }
        }
    }
    
    // MARK: Stuff you can't extend on a protocol
    
    public var rulePredicate: NSPredicate?
    
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
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SBASurveyQuestionStep
        copy.rulePredicate = self.rulePredicate
        return self.sharedCopying(copy)
    }
    
    // MARK: NSSecureCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.sharedDecoding(coder: aDecoder)
        self.rulePredicate = aDecoder.decodeObject(forKey: "rulePredicate") as? NSPredicate
    }
    
    override public func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        self.sharedEncoding(aCoder)
        aCoder.encode(self.rulePredicate, forKey: "rulePredicate")
    }
    
    // MARK: Equality
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let castObject = object as? SBASurveyQuestionStep else { return false }
        return super.isEqual(object) &&
            sharedEquality(object) &&
            SBAObjectEquality(castObject.rulePredicate, self.rulePredicate)
    }
    
    override public var hash: Int {
        return super.hash ^ sharedHash() ^ SBAObjectHash(self.rulePredicate)
    }
}

public final class SBASurveyFormStep: ORKFormStep, SBASurveyNavigationStep {
    
    public var surveyStepResultFilterPredicate: NSPredicate {
        return NSPredicate(format: "identifier = %@", self.identifier)
    }
    
    public func matchingSurveyStep(_ stepResult: ORKStepResult) -> SBAFormProtocol? {
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
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        return self.sharedCopying(copy)
    }
    
    // MARK: NSSecureCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.sharedDecoding(coder: aDecoder)
    }
    
    override public func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        self.sharedEncoding(aCoder)
    }
    
    // MARK: Equality
    
    override public func isEqual(_ object: Any?) -> Bool {
        return super.isEqual(object) && sharedEquality(object)
    }
    
    override public var hash: Int {
        return super.hash ^ sharedHash()
    }
}

public final class SBASurveySubtaskStep: SBASubtaskStep, SBASurveyNavigationStep {
    
    public var surveyStepResultFilterPredicate: NSPredicate {
        return NSPredicate(format: "identifier BEGINSWITH %@", "\(self.identifier).")
    }
    
    public func matchingSurveyStep(_ stepResult: ORKStepResult) -> SBAFormProtocol? {
        return self.step(withIdentifier: stepResult.identifier) as? SBAFormProtocol
    }
    
    // MARK: Stuff you can't extend on a protocol
    
    public var skipToStepIdentifier: String = ORKNullStepIdentifier
    public var skipIfPassed: Bool = false
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    override public init(identifier: String, steps: [ORKStep]?) {
        super.init(identifier: identifier, steps: steps)
    }
    
    init(surveyItem: SBASurveyItem, steps: [ORKStep]?) {
        super.init(identifier: surveyItem.identifier, steps: steps)
        self.sharedCopyFromSurveyItem(surveyItem)
    }
    
    // MARK: NSCopying
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        return self.sharedCopying(copy)
    }
    
    // MARK: NSSecureCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.sharedDecoding(coder: aDecoder)
    }
    
    override public func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        self.sharedEncoding(aCoder)
    }
    
    // MARK: Equality
    
    override public func isEqual(_ object: Any?) -> Bool {
        return super.isEqual(object) && sharedEquality(object)
    }
    
    override public var hash: Int {
        return super.hash ^ sharedHash()
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
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let formItem = copy as? SBASurveyFormItem else { return copy }
        formItem.rulePredicate = self.rulePredicate
        return formItem
    }
    
    // MARK: NSSecureCoding
    
    required public init?(coder aDecoder: NSCoder) {
        self.rulePredicate = aDecoder.decodeObject(forKey: "rulePredicate") as? NSPredicate
        super.init(coder: aDecoder);
    }
    
    override public func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.rulePredicate, forKey: "rulePredicate")
    }
    
    // MARK: Equality
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBASurveyFormItem else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(self.rulePredicate, object.rulePredicate)
    }
    
    override public var hash: Int {
        return super.hash ^
            SBAObjectHash(self.rulePredicate)
    }
}

public extension SBASurveyNavigationStep {
    
    public func nextStepIdentifier(_ taskResult: ORKTaskResult, additionalTaskResults:[ORKTaskResult]?) -> String? {
        guard let results = taskResult.results else { return nil }
        let predicate = self.surveyStepResultFilterPredicate
        let passed = results.filter({ predicate.evaluate(with: $0) && !matchesExpectedResult($0)}).count == 0
        if (passed && self.skipIfPassed) || (!passed && !self.skipIfPassed) {
            return self.skipToStepIdentifier
        }
        return nil;
    }
    
    func matchesRulePredicate(_ item: AnyObject, result: ORKResult?) -> Bool? {
        if let rule = item as? SBASurveyFormItem,
            let predicate = rule.rulePredicate {
                // If the result is nil then it fails
                guard let result = result else { return false }
                // Otherwise, evaluate against the predicate
                return predicate.evaluate(with: result)
        }
        return nil
    }
    
    func matchesExpectedResult(_ result: ORKResult) -> Bool {
        if let stepResult = result as? ORKStepResult,
            let step = self.matchingSurveyStep(stepResult) {
                // evaluate each form item
                if let formItems = step.formItems {
                    for formItem in formItems {
                        let formResult = stepResult.result(forIdentifier: formItem.identifier)
                        if let matchingRule = matchesRulePredicate(formItem, result:formResult) , !matchingRule {
                            // If a form item does not match the expected result then exit, otherwise keep going
                            return false
                        }
                    }
                }
        }
        return true;
    }
    
    func sharedCopying(_ copy: Any) -> Any {
        guard let step = copy as? SBASurveyNavigationStep else { return copy }
        step.skipToStepIdentifier = self.skipToStepIdentifier
        step.skipIfPassed = self.skipIfPassed
        return step
    }
    
    func sharedDecoding(coder aDecoder: NSCoder) {
        self.skipToStepIdentifier = aDecoder.decodeObject(forKey: "skipToStepIdentifier") as! String
        self.skipIfPassed = aDecoder.decodeBool(forKey: "skipIfPassed")
    }
    
    func sharedEncoding(_ aCoder: NSCoder) {
        aCoder.encode(self.skipToStepIdentifier, forKey: "skipToStepIdentifier")
        aCoder.encode(self.skipIfPassed, forKey: "skipIfPassed")
    }
    
    func sharedCopyFromSurveyItem(_ surveyItem: Any) {
        guard let surveyItem = surveyItem as? SBAFormStepSurveyItem else { return }
        if let skipIdentifier = surveyItem.skipIdentifier {
            self.skipToStepIdentifier = skipIdentifier
        }
        self.skipIfPassed = surveyItem.skipIfPassed
    }
    
    func sharedHash() -> Int {
        return SBAObjectHash(self.skipToStepIdentifier)
    }
    
    func sharedEquality(_ object: Any?) -> Bool {
        guard let object = object as? SBASurveyNavigationStep else { return false }
        return SBAObjectEquality(self.skipToStepIdentifier, object.skipToStepIdentifier) &&
            self.skipIfPassed == object.skipIfPassed
    }
}
