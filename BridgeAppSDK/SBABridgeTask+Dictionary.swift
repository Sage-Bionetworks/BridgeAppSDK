//
//  SBABridgeTask+Dictionary.swift
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

import Foundation

extension NSDictionary: SBATaskReference {
    
    public func transformToTask(with factory: SBASurveyFactory, isLastStep: Bool) -> (ORKTask & NSCopying & NSSecureCoding)? {
        if !self.taskType.isNilType() {
            // If the task type is non-nil, then create an active task
            let taskOptions: ORKPredefinedTaskOption = isLastStep ? [] : .excludeConclusion
            return factory.createTaskWithActiveTask(self, taskOptions:taskOptions)
        }
        guard let bridgeTask = self.objectWithResourceDictionary() as? SBABridgeTask
        else {
            // If this isn't a resource task then return nil
            assertionFailure("Invalid NSDictionary for SBABridgeTask implementation.")
            return nil
        }
        if let dictionary = bridgeTask as? NSDictionary , !dictionary.isValidBridgeTask() {
            // If the object returned is a dictionary, check validity and return nil if failed
            return nil
        }
        return bridgeTask.createORKTask(with: factory)
    }
    
    public var cancelDisabled: Bool {
        return self["cancelDisabled"] as? Bool ?? false
    }
    
    public var allowMultipleRun: Bool {
        return self["allowMultipleRun"] as? Bool ?? true
    }

    public var scheduleNotification: Bool {
        return self["scheduleNotification"] as? Bool ?? false
    }
}

extension NSDictionary: SBASchemaReference {
    
    public var schemaRevision: NSNumber! {
        return self["schemaRevision"] as? NSNumber ?? 1
    }
    
}

extension NSDictionary: SBABridgeTask {
    
    func isValidBridgeTask() -> Bool {
        
        // Check that the task Identifier is non-nil
        guard self["taskIdentifier"] as? String != nil else {
            assertionFailure("Invalid NSDictionary for SBABridgeTask implementation.")
            return false
        }
        
        // If the task steps returns self as the only step, then need that it has a task type
        // otherwise, can end up in a wacky loop of infinite madness
        if self.taskSteps.first as? NSDictionary == self {
            guard !self.taskType.isNilType() else {
                assertionFailure("Invalid NSDictionary for SBABridgeTask implementation.")
                return false
            }
        }
        
        // Passed validity check
        return true
    }
    
    public var taskIdentifier: String! {
        guard let taskIdentifier = self["taskIdentifier"] as? String else {
            // If this is determined to be an SBABridgeTask dictionary and it does not have a
            // "taskIdentifier" key then throw an assertion, but return a UUID so that a production
            // app will not crash.
            assertionFailure("Invalid NSDictionary for SBABridgeTask implementation.")
            return UUID().uuidString
        }
        return taskIdentifier
    }
    
    public var schemaIdentifier: String! {
        return self["schemaIdentifier"] as? String ?? self.taskIdentifier
    }
    
    public var taskSteps: [SBAStepTransformer] {
        // For reverse-compatibility, allow both steps and taskSteps as the key
        // but assert on "taskSteps" as deprecated.
        let taskSteps = self["taskSteps"] as? [AnyObject]
        if taskSteps != nil {
            assertionFailure("Use of 'taskSteps' as a key into the dictionary is deprecated. Please replace with 'steps'")
        }
        guard let steps = taskSteps ?? self["steps"] as? [AnyObject] else {
            // return self if there are no taskSteps
            return [self as SBAStepTransformer]
        }
        // otherwise, explicitly map the steps to SBASurveyItem
        return steps.mapAndFilter({ return mapToStepTransformer($0) })
    }
    
    public var insertSteps: [SBAStepTransformer]? {
        guard let steps = self["insertSteps"] as? [AnyObject] else {
            // return self if there are no taskSteps
            return nil
        }
        // otherwise, explicitly map the steps to SBASurveyItem
        return steps.mapAndFilter({ return mapToStepTransformer($0) })
    }
    
    fileprivate func mapToStepTransformer(_ obj: AnyObject) -> SBAStepTransformer? {
        // If the object is not a dictionary then just return either the object or nil if not transformable
        guard let dictionary = obj as? NSDictionary,
            let transformer = dictionary.objectWithResourceDictionary() as? SBAStepTransformer else {
            return obj as? SBAStepTransformer
        }
        return transformer
    }
}
