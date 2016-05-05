//
//  SBAActiveTaskFactory.swift
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
import BridgeSDK
import AVFoundation

public enum SBAActiveTaskType {
    
    case Custom(String?)
    case Memory
    case Tapping
    case Voice
    case Walking
    case Tremor
    
    init(name: String?) {
        guard let type = name else { self = .Custom(nil); return }
        switch(type) {
        case "tapping"  : self = .Tapping
        case "memory"   : self = .Memory
        case "voice"    : self = .Voice
        case "walking"  : self = .Walking
        case "tremor"   : self = .Tremor
        default         : self = .Custom(name)
        }
    }
    
    func isNilType() -> Bool {
        if case .Custom(let customType) = self {
            return (customType == nil)
        }
        return false
    }
}

extension ORKPredefinedTaskHandOption {
    init(name: String?) {
        let name = name ?? "both"
        switch name {
        case "right"    : self = .Right
        case "left"     : self = .Left
        default         : self = .Both
        }
    }
}

public protocol SBAActiveTask: SBABridgeTask, SBAStepTransformer {
    var taskType: SBAActiveTaskType { get }
    var intendedUseDescription: String? { get }
    var taskOptions: [String : AnyObject]? { get }
    var predefinedExclusions: ORKPredefinedTaskOption? { get }
    var localizedSteps: [SBASurveyItem]? { get }
}

extension SBAActiveTask {
    
    func createDefaultORKActiveTask(options: ORKPredefinedTaskOption) -> ORKOrderedTask? {
        
        let predefinedExclusions = self.predefinedExclusions ?? options
        
        // Map known active tasks
        var task: ORKOrderedTask!
        switch self.taskType {
        case .Tapping:
            task = tappingTask(predefinedExclusions)
        case .Memory:
            task = memoryTask(predefinedExclusions)
        case .Voice:
            task = voiceTask(predefinedExclusions)
        case .Walking:
            task = walkingTask(predefinedExclusions)
        case .Tremor:
            task = tremorTask(predefinedExclusions)
        default:
            // exit early if not supported by base implementation
            return nil
        }
        
        // map the localized steps
        mapLocalizedSteps(task)
        
        return task
    }
    
    func mapLocalizedSteps(task: ORKOrderedTask) {
        // Map the title, text and detail from the localizedSteps to their matching step from the
        // base factory method defined
        if let items = self.localizedSteps {
            for item in items {
                if let step = task.steps.filter({ return $0.identifier == item.identifier }).first {
                    step.title = item.stepTitle ?? step.title
                    step.text = item.stepText ?? step.text
                    if let detail = item.stepDetail, let instructionStep = step as? ORKInstructionStep {
                        instructionStep.detailText = detail
                    }
                    if let activeStep = step as? ORKActiveStep,
                        let activeItem = item as? SBAActiveStepSurveyItem {
                        if let spokenInstruction = activeItem.stepSpokenInstruction {
                            activeStep.spokenInstruction = spokenInstruction
                        }
                        if let finishedSpokenInstruction = activeItem.stepFinishedSpokenInstruction {
                            activeStep.finishedSpokenInstruction = finishedSpokenInstruction
                        }
                    }
                }
            }
        }
    }
    
    func tappingTask(options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        let duration: NSTimeInterval = taskOptions?["duration"] as? NSTimeInterval ?? 10.0
        let handOptions = ORKPredefinedTaskHandOption(name: taskOptions?["handOptions"] as? String)
        return ORKOrderedTask.twoFingerTappingIntervalTaskWithIdentifier(
            self.schemaIdentifier,
            intendedUseDescription:self.intendedUseDescription,
            duration:duration,
            options:options,
            handOptions:handOptions)
    }
    
    func memoryTask(options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        let initialSpan: Int = taskOptions?["initialSpan"] as? Int ?? 3
        let minimumSpan: Int = taskOptions?["minimumSpan"] as? Int ?? 2
        let maximumSpan: Int = taskOptions?["maximumSpan"] as? Int ?? 15
        let playSpeed: NSTimeInterval = taskOptions?["playSpeed"] as? NSTimeInterval ?? 1.0
        let maxTests: Int = taskOptions?["maxTests"] as? Int ?? 5
        let maxConsecutiveFailures: Int = taskOptions?["maxConsecutiveFailures"] as? Int ?? 3
        var customTargetImage: UIImage? = nil
        if let imageName = taskOptions?["customTargetImageName"] as? String {
            customTargetImage = SBAResourceFinder.sharedResourceFinder.imageNamed(imageName)
        }
        let customTargetPluralName: String? = taskOptions?["customTargetPluralName"] as? String
        let requireReversal: Bool = taskOptions?["requireReversal"] as? Bool ?? false
        
        return ORKOrderedTask.spatialSpanMemoryTaskWithIdentifier(self.schemaIdentifier,
                                                                  intendedUseDescription: self.intendedUseDescription,
                                                                  initialSpan: initialSpan,
                                                                  minimumSpan: minimumSpan,
                                                                  maximumSpan: maximumSpan,
                                                                  playSpeed: playSpeed,
                                                                  maxTests: maxTests,
                                                                  maxConsecutiveFailures: maxConsecutiveFailures,
                                                                  customTargetImage: customTargetImage,
                                                                  customTargetPluralName: customTargetPluralName,
                                                                  requireReversal: requireReversal,
                                                                  options: options)
    }
    
    func voiceTask(options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        let speechInstruction: String? = taskOptions?["speechInstruction"] as? String
        let shortSpeechInstruction: String? = taskOptions?["shortSpeechInstruction"] as? String
        let duration: NSTimeInterval = taskOptions?["duration"] as? NSTimeInterval ?? 10.0
        let recordingSettings: [String: AnyObject]? = taskOptions?["recordingSettings"] as? [String: AnyObject]
        
        return ORKOrderedTask.audioLevelNavigableTaskWithIdentifier(self.schemaIdentifier,
                                                      intendedUseDescription: self.intendedUseDescription,
                                                      speechInstruction: speechInstruction,
                                                      shortSpeechInstruction: shortSpeechInstruction,
                                                      duration: duration,
                                                      recordingSettings: recordingSettings,
                                                      options: options)
    }
    
    func walkingTask(options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        // The walking activity is assumed to be walking back and forth rather than trying to walk down a long hallway.
        let walkDuration: NSTimeInterval = taskOptions?["walkDuration"] as? NSTimeInterval ?? 30.0
        let restDuration: NSTimeInterval = taskOptions?["restDuration"] as? NSTimeInterval ?? 30.0
        
        return ORKOrderedTask.walkBackAndForthTaskWithIdentifier(self.schemaIdentifier,
                                                                 intendedUseDescription: self.intendedUseDescription,
                                                                 walkDuration: walkDuration,
                                                                 restDuration: restDuration,
                                                                 options: options)
    }
    
    func tremorTask(options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        let duration: NSTimeInterval = taskOptions?["duration"] as? NSTimeInterval ?? 10.0
        let handOptions = ORKPredefinedTaskHandOption(name: taskOptions?["handOptions"] as? String)
        let excludeOptions = ORKTremorActiveTaskOption(rawValue: (taskOptions?["excludeOptions"] as? UInt) ?? 0)
        
        return ORKOrderedTask.tremorTestTaskWithIdentifier(self.schemaIdentifier,
                                                           intendedUseDescription: self.intendedUseDescription,
                                                           activeStepDuration: duration,
                                                           activeTaskOptions: excludeOptions,
                                                           handOptions: handOptions,
                                                           options: options)
    }
}


