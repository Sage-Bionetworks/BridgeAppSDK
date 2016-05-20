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
public class SBASubtaskStep: ORKStep {
    
    public var taskIdentifier: String?
    public var schemaIdentifier: String?
    
    public var subtask: protocol <ORKTask, NSCopying, NSSecureCoding> {
        return _subtask
    }
    private var _subtask: protocol <ORKTask, NSCopying, NSSecureCoding>
    
    public init(identifier: String, steps: [ORKStep]?) {
        _subtask = ORKOrderedTask(identifier: identifier, steps: steps)
        super.init(identifier: identifier);
    }
    
    public init(subtask: protocol <ORKTask, NSCopying, NSSecureCoding>) {
        _subtask = subtask;
        super.init(identifier: subtask.identifier);
    }
    
    func substepIdentifier(identifier: String) -> String? {
        guard let range = identifier.rangeOfString("\(self.subtask.identifier).") else { return nil }
        let stepRange = range.endIndex ..< identifier.endIndex
        let stepIdentifier = identifier.substringWithRange(stepRange)
        return stepIdentifier
    }
    
    func replacementStep(step: ORKStep?) -> ORKStep? {
        guard let step = step else { return nil }
        let stepIdentifier = "\(self.subtask.identifier).\(step.identifier)"
        return step.copyWithIdentifier(stepIdentifier)
    }
    
    func filteredTaskResult(inputResult: ORKTaskResult) -> ORKTaskResult {
        // create a mutated copy of the results that includes only the subtask results
        let subtaskResult: ORKTaskResult = inputResult.copy() as! ORKTaskResult
        if let stepResults = subtaskResult.results as? [ORKStepResult] {
            let (subtaskResults, _) = filteredStepResults(stepResults)
            subtaskResult.results = subtaskResults
        }
        return subtaskResult;
    }
    
    func filteredStepResults(inputResults: [ORKStepResult]) -> (subtaskResults:[ORKStepResult], remainingResults:[ORKStepResult]) {
        let prefix = "\(self.subtask.identifier)."
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        var subtaskResults:[ORKStepResult] = []
        var remainingResults:[ORKStepResult] = []
        for stepResult in inputResults {
            if (predicate.evaluateWithObject(stepResult)) {
                stepResult.identifier = stepResult.identifier.substringFromIndex(prefix.endIndex)
                if let stepResults = stepResult.results {
                    for result in stepResults {
                        if result.identifier.hasPrefix(prefix) {
                            result.identifier = result.identifier.substringFromIndex(prefix.endIndex)
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
    
    func stepWithIdentifier(identifier: String) -> ORKStep? {
        guard let stepIdentifier = substepIdentifier(identifier),
            let step = self.subtask.stepWithIdentifier?(stepIdentifier) else {
                return nil
        }
        return replacementStep(step)
    }
    
    func stepAfterStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        guard let step = step else {
            return replacementStep(self.subtask.stepAfterStep(nil, withResult: result))
        }
        guard let substepIdentifier = substepIdentifier(step.identifier) else {
            return nil
        }
        
        // get the next step
        let substep = step.copyWithIdentifier(substepIdentifier)
        let replacementTaskResult = filteredTaskResult(result)
        let nextStep = self.subtask.stepAfterStep(substep, withResult: replacementTaskResult)
        
        // If the task result was mutated, need to add any changes back into the result set
        if let thisStepResult = replacementTaskResult.stepResultForStepIdentifier(substepIdentifier),
            let parentStepResult = result.stepResultForStepIdentifier(step.identifier) {
            parentStepResult.results = thisStepResult.results
        }
        
        // And finally return the replacement step
        return replacementStep(nextStep)
    }
    
    override public var requestedPermissions: ORKPermissionMask {
        if let permissions = self.subtask.requestedPermissions {
            return permissions
        }
        return .None
    }
    
    // MARK: NSCopy
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone)
        guard let subtaskStep = copy as? SBASubtaskStep else { return copy }
        subtaskStep._subtask = _subtask.copyWithZone(zone) as! protocol <ORKTask, NSCopying, NSSecureCoding>
        subtaskStep.taskIdentifier = taskIdentifier
        subtaskStep.schemaIdentifier = schemaIdentifier
        return subtaskStep
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        _subtask = aDecoder.decodeObjectForKey("subtask") as! protocol <ORKTask, NSCopying, NSSecureCoding>
        taskIdentifier = aDecoder.decodeObjectForKey("taskIdentifier") as? String
        schemaIdentifier = aDecoder.decodeObjectForKey("schemaIdentifier") as? String
        super.init(coder: aDecoder);
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(_subtask, forKey: "subtask")
        aCoder.encodeObject(taskIdentifier, forKey: "taskIdentifier")
        aCoder.encodeObject(schemaIdentifier, forKey: "schemaIdentifier")
    }
    
    // MARK: Equality
    
    override public func isEqual(object: AnyObject?) -> Bool {
        guard let object = object as? SBASubtaskStep else { return false }
        return super.isEqual(object) &&
            _subtask.isEqual(object._subtask) &&
            (self.taskIdentifier == object.taskIdentifier) &&
            (self.schemaIdentifier == object.schemaIdentifier)
    }
    
    override public var hash: Int {
        let hashTaskIdentifier = self.taskIdentifier?.hash ?? 0
        let hashSchemaIdentifier = self.schemaIdentifier?.hash ?? 0
        return super.hash | hashTaskIdentifier | hashSchemaIdentifier | _subtask.hash
    }
    
}

