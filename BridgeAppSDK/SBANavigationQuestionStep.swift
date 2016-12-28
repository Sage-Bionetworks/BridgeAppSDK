//
//  SBANavigationQuestionStep.swift
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

public class SBASurveyRuleItem: SBADataObject, SBASurveyRule {
    
    public var skipIdentifier: String? {
        return self.identifier
    }
    
    public dynamic var rulePredicate: NSPredicate?
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys().appending(#keyPath(rulePredicate))
    }
    
    public init(skipIdentifier: String, rulePredicate: NSPredicate) {
        super.init(identifier: skipIdentifier)
        self.rulePredicate = rulePredicate
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public required init(dictionaryRepresentation dictionary: [AnyHashable : Any]) {
        super.init(dictionaryRepresentation: dictionary)
    }
}

public class SBANavigationQuestionStep: ORKQuestionStep, SBANavigationRule {

    public var rules: [SBASurveyRule]?
    
    public func nextStepIdentifier(with result: ORKTaskResult, and additionalTaskResults: [ORKTaskResult]?) -> String? {
        guard let rules = self.rules,
            let stepResult = result.result(forIdentifier: self.identifier) as? ORKStepResult,
            let questionResult = stepResult.result(forIdentifier: self.identifier)
            else {
                return nil
        }
        for rule in rules {
            if let predicate = rule.rulePredicate, predicate.evaluate(with: questionResult) {
                return rule.skipIdentifier
            }
        }
        return nil
    }

    override public required init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    init(inputItem: SBAFormStepSurveyItem, factory: SBASurveyFactory? = nil) {
        super.init(identifier: inputItem.identifier)
        inputItem.mapStepValues(with: self)
        let subtype = inputItem.surveyItemType.formSubtype()
        self.answerFormat = factory?.createAnswerFormat(inputItem, subtype: subtype) ?? inputItem.createAnswerFormat(subtype)
        self.rules = inputItem.rules
    }
    
    // MARK: NSCopying
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SBANavigationQuestionStep
        copy.rules = self.rules
        return copy
    }
    
    // MARK: NSSecureCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.rules = aDecoder.decodeObject(forKey: "rules") as? [SBASurveyRule]
    }
    
    override public func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.rules, forKey: "rules")
    }
    
    // MARK: Equality
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let castObject = object as? SBANavigationQuestionStep else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(castObject.rules, self.rules)
    }
    
    override public var hash: Int {
        return super.hash ^ SBAObjectHash(self.rules)
    }
}
