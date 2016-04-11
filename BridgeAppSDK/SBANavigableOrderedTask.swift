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
 * Define the navigation rule as a protocol to allow for protocol-oriented extention (multiple inheritance).
 * Currently defined usage is to allow the SBANavigableOrderedTask to check if a step has a navigation rule.
 */
public protocol SBANavigationRule: class, NSSecureCoding {
    func nextStepIdentifier(result: ORKTaskResult, additionalTaskResults:[ORKTaskResult]?) -> String?
}

public protocol SBAConditionalRule: class, NSSecureCoding {
    func shouldSkipStep(step: ORKStep?, previousStep: ORKStep?, result: ORKTaskResult) -> Bool
}

/**
 * SBANavigableOrderedTask can process both SBASubtaskStep steps and as well as any step that conforms
 * to the SBANavigationRule.
 */
public class SBANavigableOrderedTask: ORKOrderedTask {
    
    public var additionalTaskResults: [ORKTaskResult]?
    public var conditionalRule: SBAConditionalRule?
    
    private var orderedStepIdentifiers: [String] = []
    
    // Swift Fun Fact: In order to use a superclass initializer it must be overridden 
    // by the subclass. syoung 02/11/2016
    public override init(identifier: String, steps: [ORKStep]?) {
        super.init(identifier: identifier, steps: steps)
    }

    func subtaskStepWithIdentifier(identifier: String?) -> SBASubtaskStep? {
        // Look for a period in the range of the string
        guard let range = identifier?.rangeOfString(".") where range.endIndex > identifier!.startIndex else {
            return nil
        }
        // Parse out the subtask identifier and look in super for a step with that identifier
        let subtaskStepIdentifier = identifier!.substringToIndex(range.endIndex.advancedBy(-1))
        guard let subtaskStep = super.stepWithIdentifier(subtaskStepIdentifier) as? SBASubtaskStep else {
            return nil
        }
        return subtaskStep
    }
    
    func superStepAfterStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        
        var returnStep: ORKStep?
        var previousStep: ORKStep? = step
        var shouldSkip = false
        
        repeat {
        
            if let navigableStep = previousStep as? SBANavigationRule,
                let nextStepIdentifier = navigableStep.nextStepIdentifier(result, additionalTaskResults:self.additionalTaskResults) {
                    // If this is a step that conforms to the SBANavigableStep protocol and
                    // the next step identifier is non-nil then get the next step by looking within
                    // the steps associated with this task
                    returnStep = super.stepWithIdentifier(nextStepIdentifier)
            }
            else {
                // If we've dropped through without setting the return step to something non-nil
                // then look to super for the next step
                returnStep = super.stepAfterStep(previousStep, withResult: result)
            }
            
            // If the superclass returns a step of type subtask step, then get the first step from the subtask
            if let subtaskStep = returnStep as? SBASubtaskStep {
                returnStep = subtaskStep.stepAfterStep(nil, withResult: result)
            }
            
            // Check to see if this is a conditional step that *should* be skipped
            shouldSkip = conditionalRule?.shouldSkipStep(returnStep, previousStep: previousStep, result: result) ?? false
            if (shouldSkip) {
                previousStep = returnStep
            }
            
        } while(shouldSkip)
        
        return returnStep;
    }

    // MARK: ORKOrderedTask overrides
    
    override public func stepAfterStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        
        var returnStep: ORKStep?

        // Look to see if this has a valid subtask step associated with this step
        if let subtaskStep = subtaskStepWithIdentifier(step?.identifier) {
            returnStep = subtaskStep.stepAfterStep(step, withResult: result)
            if (returnStep == nil) {
                // If the subtask returns nil then it is at the last step
                // Check super for more steps
                returnStep = superStepAfterStep(subtaskStep, withResult: result)
            }
        }
        else {
            // If this isn't a subtask step then look to super nav for the next step
            returnStep = superStepAfterStep(step, withResult: result)
        }
        
        // Look for step in the ordered steps and lop off everything after this one
        if let previousIdentifier = step?.identifier,
            let idx = self.orderedStepIdentifiers.indexOf(previousIdentifier) where idx < self.orderedStepIdentifiers.endIndex {
                self.orderedStepIdentifiers.removeRange(idx.advancedBy(1) ..< self.orderedStepIdentifiers.endIndex)
        }
        if let identifier = returnStep?.identifier {
            if let idx = self.orderedStepIdentifiers.indexOf(identifier) {
                self.orderedStepIdentifiers.removeRange(idx ..< self.orderedStepIdentifiers.endIndex)
            }
            self.orderedStepIdentifiers += [identifier]
        }

        return returnStep
    }

    override public func stepBeforeStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        guard let identifier = step?.identifier,
            let idx = self.orderedStepIdentifiers.indexOf(identifier) where idx > 0 else {
            return nil
        }
        let previousIdentifier = self.orderedStepIdentifiers[idx.advancedBy(-1)]
        return self.stepWithIdentifier(previousIdentifier)
    }
    
    override public func stepWithIdentifier(identifier: String) -> ORKStep? {
        // Look for the step in the superclass
        if let step = super.stepWithIdentifier(identifier) {
            return step
        }
        // If not found check to see if it is a substep
        return subtaskStepWithIdentifier(identifier)?.stepWithIdentifier(identifier)
    }
    
    override public func progressOfCurrentStep(step: ORKStep, withResult result: ORKTaskResult) -> ORKTaskProgress {
        // Do not show progress for an ordered task with navigation rules
        return ORKTaskProgress(current: 0, total: 0)
    }
    
    override public func validateParameters() {
        super.validateParameters()
        for step in self.steps {
            // Check if the step is a subtask step and validate parameters
            if let subtaskStep = step as? SBASubtaskStep {
                subtaskStep.subtask.validateParameters?()
            }
        }
    }
    
    override public var requestedHealthKitTypesForReading: Set<HKObjectType>? {
        var set = super.requestedHealthKitTypesForReading ?? Set()
        for step in self.steps {
            // Check if the step is a subtask step and validate parameters
            if let subtaskStep = step as? SBASubtaskStep,
                let subset = subtaskStep.subtask.requestedHealthKitTypesForReading where subset != nil {
                    set = set.union(subset!)
            }
        }
        return set.count > 0 ? set : nil
    }

    override public var providesBackgroundAudioPrompts: Bool {
        let superRet = super.providesBackgroundAudioPrompts
        if (superRet) {
            return true
        }
        for step in self.steps {
            // Check if the step is a subtask step and validate parameters
            if let subtaskStep = step as? SBASubtaskStep,
                let subRet = subtaskStep.subtask.providesBackgroundAudioPrompts where subRet {
                    return true
            }
        }
        return false
    }
    
    // MARK: NSCopy
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone)
        guard let task = copy as? SBANavigableOrderedTask else { return copy }
        task.additionalTaskResults = self.additionalTaskResults
        task.orderedStepIdentifiers = self.orderedStepIdentifiers
        return task
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        self.additionalTaskResults = aDecoder.decodeObjectForKey("additionalTaskResults") as? [ORKTaskResult]
        self.orderedStepIdentifiers = aDecoder.decodeObjectForKey("orderedStepIdentifiers") as! [String]
        super.init(coder: aDecoder);
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        if let additionalTaskResults = self.additionalTaskResults {
            aCoder.encodeObject(additionalTaskResults, forKey: "additionalTaskResults")
        }
        aCoder.encodeObject(self.orderedStepIdentifiers, forKey: "orderedStepIdentifiers")
    }
}
