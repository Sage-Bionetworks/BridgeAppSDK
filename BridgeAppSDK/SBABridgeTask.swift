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

public protocol SBABridgeTask: class {
    var taskIdentifier: String! { get }
    var schemaIdentifier: String! { get }
    var schemaRevision: Int! { get }
    var taskSteps: [SBASurveyItem] { get }
}

public extension SBABridgeTask {
    
    public func createORKTask() -> ORKTask? {
        return createORKTask(factory: SBASurveyFactory())
    }
    
    public func createORKTask(factory factory: SBASurveyFactory) -> ORKTask? {
        let steps = self.taskSteps
        guard steps.count > 0 else { return nil }
        guard steps.count > 1 else {
            // If there is only 1 step then do not need to wrap subtasks in a subtask step
            let item = steps.first!
            switch item.surveyItemType {
            case .ActiveTask  :
                return factory.createTaskWithActiveTask(item as! SBAActiveTask, taskOptions: .None)
            default:
                let step = factory.createSurveyStep(item, isSubtaskStep: false)
                return ORKOrderedTask(identifier: self.taskIdentifier, steps: [step])
            }
        }
        
        let lastIndex = steps.count - 1
        let subtaskSteps: [ORKStep] = steps.enumerate().map(){ (index, item) in
            
            switch item.surveyItemType {
                
            case .ActiveTask  :
                let task = item as! SBAActiveTask
                let taskOptions: ORKPredefinedTaskOption = index==lastIndex ? .None : .ExcludeConclusion
                if let subtask = factory.createTaskWithActiveTask(task, taskOptions:taskOptions) {
                    if let orderedTask = subtask as? ORKOrderedTask {
                        return SBASubtaskStep(identifier: orderedTask.identifier, steps: orderedTask.steps)
                    }
                    else {
                        return SBASubtaskStep(subtask: subtask)
                    }
                }
                else {
                    return SBASubtaskStep(identifier: task.identifier, steps: nil)
                }
                
            default:
                return factory.createSurveyStep(item, isSubtaskStep: false)
            }
        }
        
        return SBANavigableOrderedTask(identifier: self.taskIdentifier, steps: subtaskSteps)
    }
    
}
