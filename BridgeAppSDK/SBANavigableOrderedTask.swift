//
//  SBANavigableOrderedTask.swift
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
 Define the navigation rule as a protocol to allow for protocol-oriented extention (multiple inheritance).
 Currently defined usage is to allow the SBANavigableOrderedTask to check if a step has a navigation rule.
 */
public protocol SBANavigationRule: class, NSSecureCoding {
    func nextStepIdentifier(with result: ORKTaskResult, and additionalTaskResults:[ORKTaskResult]?) -> String?
}

/**
 A navigation skip rule applies to this step to allow that step to be skipped.
 */
public protocol SBANavigationSkipRule: class, NSSecureCoding {
    func shouldSkipStep(with result: ORKTaskResult, and additionalTaskResults:[ORKTaskResult]?) -> Bool
}

/**
 A conditional rule is appended to the navigable task to check a secondary source for whether or not the
 step should be displayed.
 */
@objc
public protocol SBAConditionalRule: class, NSSecureCoding {
    func shouldSkip(step: ORKStep?, with result: ORKTaskResult) -> Bool
    func nextStep(previousStep: ORKStep?, nextStep: ORKStep?, with result: ORKTaskResult) -> ORKStep?
}

/**
 * SBANavigableOrderedTask can process both SBASubtaskStep steps and as well as any step that conforms
 * to the SBANavigationRule.
 */
open class SBANavigableOrderedTask: ORKOrderedTask, ORKTaskResultSource {
    
    public var additionalTaskResults: [ORKTaskResult]?
    public var conditionalRule: SBAConditionalRule?
    
    @objc fileprivate var orderedStepIdentifiers: [String] = []
    
    // Swift Fun Fact: In order to use a superclass initializer it must be overridden 
    // by the subclass. syoung 02/11/2016
    public override init(identifier: String, steps: [ORKStep]?) {
        super.init(identifier: identifier, steps: steps)
    }

    fileprivate func subtaskStep(identifier: String?) -> SBASubtaskStep? {
        // Look for a period in the range of the string
        guard let identifier = identifier,
            let range = identifier.range(of: "."), range.upperBound > identifier.startIndex else {
            return nil
        }
        // Parse out the subtask identifier and look in super for a step with that identifier
        let subtaskStepIdentifier = identifier.substring(to: identifier.index(range.upperBound, offsetBy: -1))
        guard let subtaskStep = super.step(withIdentifier: subtaskStepIdentifier) as? SBASubtaskStep else {
            return nil
        }
        return subtaskStep
    }
    
    fileprivate func superStep(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        
        // Check the conditional rule to see if it returns a next step for the given previous
        // step and return that with an early exit if applicable.
        if let nextStep = self.conditionalRule?.nextStep(previousStep: step, nextStep: nil, with: result) {
            return nextStep
        }
        
        var returnStep: ORKStep?
        var previousStep: ORKStep? = step
        var shouldSkip = false
        
        repeat {
        
            repeat {
                if let navigableStep = previousStep as? SBANavigationRule,
                    let nextStepIdentifier = navigableStep.nextStepIdentifier(with: result, and:self.additionalTaskResults) {
                        // If this is a step that conforms to the SBANavigableStep protocol and
                        // the next step identifier is non-nil then get the next step by looking within
                        // the steps associated with this task
                        returnStep = super.step(withIdentifier: nextStepIdentifier)
                }
                else {
                    // If we've dropped through without setting the return step to something non-nil
                    // then look to super for the next step
                    returnStep = super.step(after: previousStep, with: result)
                }
                
                // Check if this is a skipable step
                if let navigationSkipStep = returnStep as? SBANavigationSkipRule,
                    navigationSkipStep.shouldSkipStep(with: result, and: self.additionalTaskResults) {
                    shouldSkip = true
                    previousStep = returnStep
                }
                else {
                    shouldSkip = false
                }
                
            } while (shouldSkip)
            
            // If the superclass returns a step of type subtask step, then get the first step from the subtask
            // Since it is possible that the subtask will return an empty task (all steps are invalid) then 
            // need to also check that the return is non-nil
            while let subtaskStep = returnStep as? SBASubtaskStep {
                if let subtaskReturnStep = subtaskStep.stepAfterStep(nil, withResult: result) {
                    returnStep = subtaskReturnStep
                }
                else {
                    returnStep = super.step(after: subtaskStep, with: result)
                }
            }
            
            // Check to see if this is a conditional step that *should* be skipped
            shouldSkip = conditionalRule?.shouldSkip(step: returnStep, with: result) ?? false
            if !shouldSkip, let navigationSkipStep = returnStep as? SBANavigationSkipRule {
                shouldSkip = navigationSkipStep.shouldSkipStep(with: result, and: self.additionalTaskResults)
            }
            if (shouldSkip) {
                previousStep = returnStep
            }
            
        } while(shouldSkip)
        
        // If there is a conditionalRule, then check to see if the step should be mutated or replaced
        if let conditionalRule = self.conditionalRule {
            returnStep = conditionalRule.nextStep(previousStep: nil, nextStep: returnStep, with: result)
        }
        
        return returnStep;
    }

    // MARK: ORKOrderedTask overrides
    
    override open func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        
        var returnStep: ORKStep?

        // Look to see if this has a valid subtask step associated with this step
        if let subtaskStep = subtaskStep(identifier: step?.identifier) {
            returnStep = subtaskStep.stepAfterStep(step, withResult: result)
            if (returnStep == nil) {
                // If the subtask returns nil then it is at the last step
                // Check super for more steps
                returnStep = superStep(after: subtaskStep, with: result)
            }
        }
        else {
            // If this isn't a subtask step then look to super nav for the next step
            returnStep = superStep(after: step, with: result)
        }
        
        // Look for step in the ordered steps and lop off everything after this one
        if let previousIdentifier = step?.identifier,
            let idx = self.orderedStepIdentifiers.index(of: previousIdentifier) , idx < self.orderedStepIdentifiers.endIndex {
                self.orderedStepIdentifiers.removeSubrange(idx.advanced(by: 1) ..< self.orderedStepIdentifiers.endIndex)
        }
        if let identifier = returnStep?.identifier {
            if let idx = self.orderedStepIdentifiers.index(of: identifier) {
                self.orderedStepIdentifiers.removeSubrange(idx ..< self.orderedStepIdentifiers.endIndex)
            }
            self.orderedStepIdentifiers += [identifier]
        }

        return returnStep
    }

    override open func step(before step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        guard let identifier = step?.identifier,
            let idx = self.orderedStepIdentifiers.index(of: identifier) , idx > 0 else {
            return nil
        }
        let previousIdentifier = self.orderedStepIdentifiers[idx.advanced(by: -1)]
        return self.step(withIdentifier: previousIdentifier)
    }
    
    override open func step(withIdentifier identifier: String) -> ORKStep? {
        // Look for the step in the superclass
        if let step = super.step(withIdentifier: identifier) {
            return step
        }
        // If not found check to see if it is a substep
        return subtaskStep(identifier: identifier)?.step(withIdentifier: identifier)
    }
    
    override open func progress(ofCurrentStep step: ORKStep, with result: ORKTaskResult) -> ORKTaskProgress {
        // Do not show progress for an ordered task with navigation rules
        return ORKTaskProgress(current: 0, total: 0)
    }
    
    override open func validateParameters() {
        super.validateParameters()
        for step in self.steps {
            // Check if the step is a subtask step and validate parameters
            if let subtaskStep = step as? SBASubtaskStep {
                subtaskStep.subtask.validateParameters?()
            }
        }
    }
    
    override open var requestedHealthKitTypesForReading: Set<HKObjectType>? {
        var set = super.requestedHealthKitTypesForReading ?? Set()
        for step in self.steps {
            // Check if the step is a subtask step and validate parameters
            if let subtaskStep = step as? SBASubtaskStep,
                let subset = subtaskStep.subtask.requestedHealthKitTypesForReading , subset != nil {
                    set = set.union(subset!)
            }
        }
        return set.count > 0 ? set : nil
    }

    override open var providesBackgroundAudioPrompts: Bool {
        let superRet = super.providesBackgroundAudioPrompts
        if (superRet) {
            return true
        }
        for step in self.steps {
            // Check if the step is a subtask step and validate parameters
            if let subtaskStep = step as? SBASubtaskStep,
                let subRet = subtaskStep.subtask.providesBackgroundAudioPrompts , subRet {
                    return true
            }
        }
        return false
    }
    
    // MARK: ORKTaskResultSource
    
    public var initialResult: ORKTaskResult?
    
    fileprivate var storedTaskResults: [ORKResult] {
        if (initialResult == nil) {
            initialResult = ORKTaskResult(identifier: self.identifier)
            initialResult!.results = []
        }
        return initialResult!.results!
    }
    
    public func appendInitialResults(_ result: ORKStepResult) {
        var results = storedTaskResults
        results.append(result)
        initialResult?.results = results
    }
    
    public func appendInitialResults(contentsOf results: [ORKResult]) {
        var storedResults = storedTaskResults
        storedResults.append(contentsOf: results)
        initialResult?.results = storedResults
    }

    public func stepResult(forStepIdentifier stepIdentifier: String) -> ORKStepResult? {
        // If there is an initial result then return that
        if let result = initialResult?.stepResult(forStepIdentifier: stepIdentifier) {
            return result
        }
        // Otherwise, look at the substeps
        return subtaskStep(identifier: stepIdentifier)?.stepResult(forStepIdentifier: stepIdentifier)
    }
    
    // MARK: NSCopy
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let task = copy as? SBANavigableOrderedTask else { return copy }
        task.additionalTaskResults = self.additionalTaskResults
        task.orderedStepIdentifiers = self.orderedStepIdentifiers
        task.conditionalRule = self.conditionalRule
        task.initialResult = self.initialResult
        return task
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        self.additionalTaskResults = aDecoder.decodeObject(forKey: #keyPath(additionalTaskResults)) as? [ORKTaskResult]
        self.orderedStepIdentifiers = aDecoder.decodeObject(forKey: #keyPath(orderedStepIdentifiers)) as! [String]
        self.conditionalRule = aDecoder.decodeObject(forKey: #keyPath(conditionalRule)) as? SBAConditionalRule
        self.initialResult = aDecoder.decodeObject(forKey: #keyPath(initialResult)) as? ORKTaskResult
        super.init(coder: aDecoder);
    }
    
    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.additionalTaskResults, forKey: #keyPath(additionalTaskResults))
        aCoder.encode(self.conditionalRule, forKey: #keyPath(conditionalRule))
        aCoder.encode(self.orderedStepIdentifiers, forKey: #keyPath(orderedStepIdentifiers))
        aCoder.encode(self.initialResult, forKey: #keyPath(initialResult))
    }
    
    // MARK: Equality
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBANavigableOrderedTask else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(self.additionalTaskResults, object.additionalTaskResults) &&
            SBAObjectEquality(self.orderedStepIdentifiers, object.orderedStepIdentifiers) &&
            SBAObjectEquality(self.conditionalRule as? NSObject, object.conditionalRule as? NSObject) &&
            SBAObjectEquality(self.initialResult, self.initialResult)
    }
    
    override open var hash: Int {
        return super.hash ^
            SBAObjectHash(self.additionalTaskResults) ^
            SBAObjectHash(self.orderedStepIdentifiers) ^
            SBAObjectHash(self.conditionalRule) ^
            SBAObjectHash(self.initialResult)
    }

}
