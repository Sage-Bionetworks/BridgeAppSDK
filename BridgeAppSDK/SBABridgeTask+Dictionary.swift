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

extension NSDictionary: SBABridgeTask {
    
    public var taskIdentifier: String! {
        guard let taskIdentifier = self["taskIdentifier"] as? String else {
            // If this is determined to be an SBABridgeTask dictionary and it does not have a
            // "taskIdentifier" key then throw an assertion, but return a UUID so that a production
            // app will not crash.
            assertionFailure("Invalid NSDictionary for SBABridgeTask implementation.")
            return NSUUID().UUIDString
        }
        return taskIdentifier
    }
    
    public var schemaIdentifier: String! {
        return self["schemaIdentifier"] as? String ?? self.taskIdentifier
    }

    public var schemaRevision: NSNumber! {
        return self["schemaRevision"] as? NSNumber ?? NSNumber(integer:1)
    }
    
    public var taskSteps: [SBAStepTransformer] {
        guard let steps = self["taskSteps"] as? [AnyObject] else {
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
    
    private func mapToStepTransformer(obj: AnyObject) -> SBAStepTransformer? {
        // If the object is not a dictionary then just return either the object or nil if not transformable
        guard let dictionary = obj as? NSDictionary,
            let transformer = dictionary.objectWithResourceDictionary() as? SBAStepTransformer else {
            return obj as? SBAStepTransformer
        }
        return transformer
    }
    

}
