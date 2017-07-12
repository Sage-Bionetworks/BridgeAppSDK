//
//  SBATaskResultSource.swift
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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
import BridgeSDK

public protocol SBATaskResultSource: ORKTaskResultSource {
    var identifier: String { get }
}

public class SBASurveyTaskResultSource: NSObject, SBATaskResultSource {
    
    public var identifier: String {
        return task.identifier
    }
    
    public let task: ORKTask
    public let answerMap: [String : Any]
    
    public init(task: ORKTask, answerMap: [String : Any]) {
        self.task = task
        self.answerMap = answerMap
        super.init()
    }
    
    public func stepResult(forStepIdentifier stepIdentifier: String) -> ORKStepResult? {
        guard let step = task.step?(withIdentifier: stepIdentifier) else {
            return nil
        }
        
        // If this is a tracked collection then look to the data store
        if let trackedStep = step as? SBATrackedSelectionStep,
            let collection = (task as? SBANavigableOrderedTask)?.conditionalRule as? SBATrackedDataObjectCollection,
            let selectedItems = collection.dataStore.selectedItems {
            return trackedStep.stepResult(selectedItems: selectedItems)
        }
        
        // Otherwise, map the answers
        return step.stepResult(with: answerMap)
    }
}

public class SBAComboTaskResultSource: SBASurveyTaskResultSource {
    
    public let sources: [SBATaskResultSource]
    
    public init(task: ORKTask, answerMap: [String : Any], sources: [SBATaskResultSource]) {
        self.sources = sources
        super.init(task: task, answerMap: answerMap)
    }
    
    override public func stepResult(forStepIdentifier stepIdentifier: String) -> ORKStepResult? {
        guard let source = sources.first(where: { stepIdentifier.hasPrefix($0.identifier) }),
            let subIdentifier = stepIdentifier.parseSuffix(prefix: source.identifier, separator: ".")
            else {
                return super.stepResult(forStepIdentifier: stepIdentifier)
        }
        return source.stepResult(forStepIdentifier: subIdentifier)
    }
}
