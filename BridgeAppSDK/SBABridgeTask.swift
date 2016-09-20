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
    func transformToTask(with factory: SBASurveyFactory, isLastStep: Bool) -> (ORKTask & NSCopying & NSSecureCoding)?
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
    
    public func createORKTask(with factory: SBASurveyFactory = SBASurveyFactory()) -> (ORKTask & NSCopying & NSSecureCoding)? {

        guard let steps = transformTaskSteps(factory) else { return nil }
        
        let allSteps = addInsertSteps(steps, factory: factory)

        if let subtaskStep = allSteps.first as? SBASubtaskStep , allSteps.count == 1 {
            // If there is only 1 step then do not need to wrap subtasks in a subtask step
            return subtaskStep.subtask
        }
        else {
            // Create a navigable ordered task for the steps
            return SBANavigableOrderedTask(identifier: self.schemaIdentifier, steps: allSteps)
        }
    }
    
    fileprivate func transformTaskSteps(_ factory: SBASurveyFactory) -> [ORKStep]? {
        let transformableSteps = self.taskSteps
        guard transformableSteps.count > 0 else { return nil }
        
        var activeSteps: [ORKStep] = []
        let lastIndex = transformableSteps.count - 1
        
        // Map the step transformers to ORKSteps
        var subtaskSteps: [ORKStep] = transformableSteps.enumerated().mapAndFilter({ (index, item) in
            let step = item.transformToStep(with: factory, isLastStep:(lastIndex == index))
            if let activeStep = step as? SBASubtaskStep,
                let task = activeStep.subtask as? SBATaskExtension,
                let firstStep = task.step(at: 0),
                let taskTitle = firstStep.title
                , task.isActiveTask() {
                // If this is an active task AND the title is available, then track it
                activeStep.title = taskTitle
                activeSteps.append(activeStep)
            }
            return step
        })
        
        // If there should be a progress step added between active tasks, then insert those steps
        if activeSteps.count > 1 {
            let stepTitles = activeSteps.map({ $0.title! })
            for (idx, activeStep) in activeSteps.enumerated() {
                if idx + 1 < activeSteps.count, let insertAfter = subtaskSteps.index(of: activeStep) {
                    let progressStep = SBAProgressStep(identifier: "progress", stepTitles: stepTitles, index: idx)
                    subtaskSteps.insert(progressStep, at: insertAfter.advanced(by: 1))
                }
            }
        }
        
        return subtaskSteps
    }
    
    fileprivate func addInsertSteps(_ subtaskSteps: [ORKStep], factory: SBASurveyFactory) -> [ORKStep] {
        
        // Map the insert steps
        guard let insertSteps = self.insertSteps?.mapAndFilter({ $0.transformToStep(with: factory, isLastStep: false) })
            , insertSteps.count > 0 else {
                return subtaskSteps
        }
        
        var steps = subtaskSteps
        var introStep: ORKStep!
        let firstStep = steps.removeFirst()
        
        // Look at what kind of step the first step is. If this is a subtask step then 
        // pull out the first step of the subtask and use that as the intro step
        if let subtaskStep = firstStep as? SBASubtaskStep,
            let orderedTask = subtaskStep.subtask as? ORKOrderedTask {
            // Pull out the first step from the ordered task and use that as the intro step
            var mutatableSteps = orderedTask.steps
            introStep = mutatableSteps.removeFirst()
            let mutatedTask = orderedTask.copy(with: mutatableSteps)
            let mutatedSubtaskStep = subtaskStep.copy(with: mutatedTask)
            steps.insert(mutatedSubtaskStep, at: 0)
        }
        else {
            // If the first step isn't of the subtask step type with an ordered task
            // then use the first step as the intro step
            introStep = firstStep
        }
        
        // Insert the steps inside
        steps.insert(introStep, at: 0)
        steps.insert(contentsOf: insertSteps, at: 1)
        
        return steps

    }
    
}
