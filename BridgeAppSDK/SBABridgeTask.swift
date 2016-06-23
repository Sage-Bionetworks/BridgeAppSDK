//
//  SBABridgeTask.swift
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

public protocol SBATaskTransformable: class {
    func transformToTask(factory factory: SBASurveyFactory, isLastStep: Bool) -> protocol <ORKTask, NSCopying, NSSecureCoding>?
}

public protocol SBATaskReference: SBATaskTransformable {
    var cancelDisabled: Bool { get }
    var allowMultipleRun: Bool { get }
    var scheduleNotification: Bool { get }
}

public protocol SBASchemaReference: class {
    var schemaIdentifier: String! { get }
    var schemaRevision: NSNumber! { get }
}

public protocol SBABridgeTask: class {
    var taskIdentifier: String! { get }
    var schemaIdentifier: String! { get }
    var taskSteps: [SBAStepTransformer] { get }
    var insertSteps: [SBAStepTransformer]? { get }
}

public extension SBABridgeTask {
    
    public func createORKTask() -> protocol <ORKTask, NSCopying, NSSecureCoding>? {
        return createORKTask(factory: SBASurveyFactory())
    }
    
    public func createORKTask(factory factory: SBASurveyFactory) -> protocol <ORKTask, NSCopying, NSSecureCoding>? {
        let steps = self.taskSteps
        guard steps.count > 0 else { return nil }

        // Map to ORKSteps
        var activeSteps:[ORKStep] = []
        let lastIndex = steps.count - 1
        var subtaskSteps: [ORKStep] = steps.enumerate().mapAndFilter({ (index, item) in
            let step = item.transformToStep(factory, isLastStep:(lastIndex == index))
            if let activeStep = step as? SBASubtaskStep,
                let task = activeStep.subtask as? SBATaskExtension,
                let firstStep = task.stepAtIndex(0),
                let taskTitle = firstStep.title
                where task.isActiveTask() {
                // If this is an active task AND the title is available, then track it
                activeStep.title = taskTitle
                activeSteps += [activeStep]
            }
            return step
        })
        guard subtaskSteps.count > 0 else { return nil }
        
        // Check for progress steps
        if activeSteps.count > 1 {
            let stepTitles = activeSteps.map({ $0.title! })
            subtaskSteps = subtaskSteps.map({ (step) -> [ORKStep] in
                if let idx = activeSteps.indexOf(step) where idx != activeSteps.count - 1 {
                    let progressStep = SBAProgressStep(identifier: "progress", stepTitles: stepTitles, index: idx)
                    return [step, progressStep]
                }
                else {
                    return [step]
                }
            }).flatMap({$0})
        }
        
        // Map the insert steps
        if let insertSteps = self.insertSteps?.mapAndFilter({ $0.transformToStep(factory, isLastStep: false) })
            where insertSteps.count > 0 {
            
            var introStep: ORKStep!
            if let subtaskStep = subtaskSteps.first as? SBASubtaskStep,
                let orderedTask = subtaskStep.subtask as? ORKOrderedTask {
                // Pull out the first step from the ordered task and use that as the intro step
                introStep = orderedTask.removeStepAtIndex(0)
            }
            else {
                // If the first step isn't of the subtask step type with an ordered task
                // then use the first step as the intro step
                introStep = subtaskSteps.removeAtIndex(0)
            }
            
            // Insert the steps inside
            subtaskSteps = [introStep] + insertSteps + subtaskSteps
        }

        if let subtaskStep = subtaskSteps.first as? SBASubtaskStep where subtaskSteps.count == 1 {
            // If there is only 1 step then do not need to wrap subtasks in a subtask step
            return subtaskStep.subtask
        }
        else {
            // Create a navigable ordered task for the steps
            return SBANavigableOrderedTask(identifier: self.schemaIdentifier, steps: subtaskSteps)
        }
    }
    
}
