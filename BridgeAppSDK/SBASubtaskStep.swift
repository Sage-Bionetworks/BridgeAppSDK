//
//  SBASubtaskStep.swift
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
 * The subtask step is a logical grouping of steps where the steps are defined by a subtask.
 */
open class SBASubtaskStep: ORKStep {
    
    open var taskIdentifier: String?
    open var schemaIdentifier: String?
    
    open var subtask: ORKTask & NSCopying & NSSecureCoding {
        return _subtask
    }
    fileprivate var _subtask: ORKTask & NSCopying & NSSecureCoding
    
    override public init(identifier: String) {
        _subtask = ORKOrderedTask(identifier: identifier, steps: nil)
        super.init(identifier: identifier)
    }
    
    public init(identifier: String, steps: [ORKStep]?) {
        _subtask = ORKOrderedTask(identifier: identifier, steps: steps)
        super.init(identifier: identifier);
    }
    
    public init(subtask: ORKTask & NSCopying & NSSecureCoding) {
        _subtask = subtask;
        super.init(identifier: subtask.identifier);
    }
    
    func substepIdentifier(_ identifier: String) -> String? {
        guard let range = identifier.range(of: "\(self.subtask.identifier).") else { return nil }
        let stepRange = range.upperBound ..< identifier.endIndex
        let stepIdentifier = identifier.substring(with: stepRange)
        return stepIdentifier
    }
    
    func replacementStep(_ step: ORKStep?) -> ORKStep? {
        guard let step = step else { return nil }
        let stepIdentifier = "\(self.subtask.identifier).\(step.identifier)"
        return step.copy(withIdentifier: stepIdentifier)
    }
    
    func filteredTaskResult(_ inputResult: ORKTaskResult) -> ORKTaskResult {
        // create a mutated copy of the results that includes only the subtask results
        let subtaskResult: ORKTaskResult = inputResult.copy() as! ORKTaskResult
        if let stepResults = subtaskResult.results as? [ORKStepResult] {
            let (subtaskResults, _) = filteredStepResults(stepResults)
            subtaskResult.results = subtaskResults
        }
        return subtaskResult;
    }
    
    func filteredStepResults(_ inputResults: [ORKStepResult]) -> (subtaskResults:[ORKStepResult], remainingResults:[ORKStepResult]) {
        let prefix = "\(self.subtask.identifier)."
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        var subtaskResults:[ORKStepResult] = []
        var remainingResults:[ORKStepResult] = []
        for stepResult in inputResults {
            if (predicate.evaluate(with: stepResult)) {
                stepResult.identifier = stepResult.identifier.substring(from: prefix.endIndex)
                if let stepResults = stepResult.results {
                    for result in stepResults {
                        if result.identifier.hasPrefix(prefix) {
                            result.identifier = result.identifier.substring(from: prefix.endIndex)
                        }
                    }
                }
                subtaskResults += [stepResult]
            }
            else {
                remainingResults += [stepResult]
            }
        }
        return (subtaskResults, remainingResults)
    }
    
    func step(withIdentifier identifier: String) -> ORKStep? {
        guard let stepIdentifier = substepIdentifier(identifier),
            let step = self.subtask.step?(withIdentifier: stepIdentifier) else {
                return nil
        }
        return replacementStep(step)
    }
    
    func stepAfterStep(_ step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        guard let step = step else {
            return replacementStep(self.subtask.step(after: nil, with: result))
        }
        guard let substepIdentifier = substepIdentifier(step.identifier) else {
            return nil
        }
        
        // get the next step
        let substep = step.copy(withIdentifier: substepIdentifier)
        let replacementTaskResult = filteredTaskResult(result)
        let nextStep = self.subtask.step(after: substep, with: replacementTaskResult)
        
        // If the task result was mutated, need to add any changes back into the result set
        if let thisStepResult = replacementTaskResult.stepResult(forStepIdentifier: substepIdentifier),
            let parentStepResult = result.stepResult(forStepIdentifier: step.identifier) {
            parentStepResult.results = thisStepResult.results
        }
        
        // And finally return the replacement step
        return replacementStep(nextStep)
    }
    
    override open var requestedPermissions: ORKPermissionMask {
        if let permissions = self.subtask.requestedPermissions {
            return permissions
        }
        return []
    }
    
    // MARK: NSCopy
    
    open func copyWithTask(_ subtask: ORKTask & NSCopying & NSSecureCoding) -> SBASubtaskStep {
        let copy = self.copy() as! SBASubtaskStep
        copy._subtask = subtask
        return copy
    }
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SBASubtaskStep
        copy._subtask = _subtask.copy(with: zone) as! ORKTask & NSCopying & NSSecureCoding
        copy.taskIdentifier = taskIdentifier
        copy.schemaIdentifier = schemaIdentifier
        return copy
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        _subtask = aDecoder.decodeObject(forKey: "subtask") as! ORKTask & NSCopying & NSSecureCoding
        taskIdentifier = aDecoder.decodeObject(forKey: "taskIdentifier") as? String
        schemaIdentifier = aDecoder.decodeObject(forKey: "schemaIdentifier") as? String
        super.init(coder: aDecoder);
    }
    
    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(_subtask, forKey: "subtask")
        aCoder.encode(taskIdentifier, forKey: "taskIdentifier")
        aCoder.encode(schemaIdentifier, forKey: "schemaIdentifier")
    }
    
    // MARK: Equality
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBASubtaskStep else { return false }
        return super.isEqual(object) &&
            _subtask.isEqual(object._subtask) &&
            (self.taskIdentifier == object.taskIdentifier) &&
            (self.schemaIdentifier == object.schemaIdentifier)
    }
    
    override open var hash: Int {
        return super.hash ^
            SBAObjectHash(self.taskIdentifier) ^
            SBAObjectHash(self.schemaIdentifier) ^
            _subtask.hash
    }
    
}

