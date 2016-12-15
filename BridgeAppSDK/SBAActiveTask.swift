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
    
    case custom(String?)
    case memory
    case tapping
    case voice
    case walking
    case tremor
    case moodSurvey
    case trailmaking
    
    init(name: String?) {
        guard let type = name else { self = .custom(nil); return }
        switch(type) {
        case "tapping"      : self = .tapping
        case "memory"       : self = .memory
        case "voice"        : self = .voice
        case "walking"      : self = .walking
        case "tremor"       : self = .tremor
        case "moodSurvey"   : self = .moodSurvey
        case "trailmaking"  : self = .trailmaking
        default             : self = .custom(name)
        }
    }
    
    func isNilType() -> Bool {
        if case .custom(let customType) = self {
            return (customType == nil)
        }
        return false
    }
}

extension ORKPredefinedTaskHandOption {
    init(name: String?) {
        let name = name ?? "both"
        switch name {
        case "right"    : self = .right
        case "left"     : self = .left
        default         : self = .both
        }
    }
}

extension ORKTremorActiveTaskOption {
    init(excludes: [String]?) {
        guard let excludes = excludes else {
            self.init(rawValue: 0)
            return
        }
        let rawValue: UInt = excludes.map({ (exclude) -> ORKTremorActiveTaskOption in
            switch exclude {
            case "inLap"            : return .excludeHandInLap
            case "shoulderHeight"   : return .excludeHandAtShoulderHeight
            case "elbowBent"        : return .excludeHandAtShoulderHeightElbowBent
            case "touchNose"        : return .excludeHandToNose
            case "queenWave"        : return .excludeQueenWave
            default                 : return []
            }
        }).reduce(0) { (raw, option) -> UInt in
            return option.rawValue | raw
        }
        self.init(rawValue: rawValue)
    }
}

extension ORKMoodSurveyFrequency {
    init(name: String?) {
        let name = name ?? "daily"
        switch name {
        case "weekly"   : self = .weekly
        default         : self = .daily
        }
    }
}

public protocol SBAActiveTask: SBABridgeTask, SBAStepTransformer {
    var taskType: SBAActiveTaskType { get }
    var intendedUseDescription: String? { get }
    var taskOptions: [String : Any]? { get }
    var predefinedExclusions: ORKPredefinedTaskOption? { get }
    var localizedSteps: [SBASurveyItem]? { get }
    var optional: Bool { get }
}

extension SBAActiveTask {
    
    func createDefaultORKActiveTask(_ options: ORKPredefinedTaskOption) -> ORKOrderedTask? {
        
        let predefinedExclusions = self.predefinedExclusions ?? options
        
        // Map known active tasks
        var task: ORKOrderedTask!
        switch self.taskType {
        case .tapping:
            task = tappingTask(predefinedExclusions)
        case .memory:
            task = memoryTask(predefinedExclusions)
        case .voice:
            task = voiceTask(predefinedExclusions)
        case .walking:
            task = walkingTask(predefinedExclusions)
        case .tremor:
            task = tremorTask(predefinedExclusions)
        case .moodSurvey:
            task = moodSurvey(predefinedExclusions)
        case .trailmaking:
            task = trailmakingTask(predefinedExclusions)
        default:
            // exit early if not supported by base implementation
            return nil
        }
        
        // Modify the instruction step if this is an optional task
        if self.optional {
            task = taskWithSkipAction(task)
        }
        
        // map the localized steps
        mapLocalizedSteps(task)
        
        return task
    }
    
    func taskWithSkipAction(_ task: ORKOrderedTask) -> ORKOrderedTask {
        
        guard type(of: task) === ORKOrderedTask.self else {
            assertionFailure("Handling of an optional task is not implemented for any class other than ORKOrderedTask")
            return task
        }
        guard let introStep = task.steps.first as? ORKInstructionStep else {
            assertionFailure("Handling of an optional task is not implemented for tasks that do not start with ORKIntructionStep")
            return task
        }
        guard let conclusionStep = task.steps.last as? ORKInstructionStep else {
            assertionFailure("Handling of an optional task is not implemented for tasks that do not end with ORKIntructionStep")
            return task
        }
        
        // Replace the intro step with a direct navigation step that has a skip button 
        // to skip to the conclusion
        let replaceStep = SBAInstructionStep(identifier: introStep.identifier)
        replaceStep.title = introStep.title
        replaceStep.text = introStep.text
        let skipExplanation = Localization.localizedString("SBA_SKIP_ACTIVITY_INSTRUCTION")
        let detail = introStep.detailText ?? ""
        replaceStep.detailText = "\(detail)\n\(skipExplanation)\n"
        replaceStep.learnMoreAction = SBASkipAction(identifier: conclusionStep.identifier)
        replaceStep.learnMoreAction!.learnMoreButtonText = Localization.localizedString("SBA_SKIP_ACTIVITY")
        var steps: [ORKStep] = task.steps
        steps.removeFirst()
        steps.insert(replaceStep, at: 0)
        
        // Return a navigable ordered task
        return SBANavigableOrderedTask(identifier: task.identifier, steps: steps)
    }
    
    func mapLocalizedSteps(_ task: ORKOrderedTask) {
        // Map the title, text and detail from the localizedSteps to their matching step from the
        // base factory method defined
        if let items = self.localizedSteps {
            for item in items {
                if let step = task.steps.find({ return $0.identifier == item.identifier }) {
                    step.title = item.stepTitle ?? step.title
                    step.text = item.stepText ?? step.text
                    if let instructionItem = item as? SBAInstructionStepSurveyItem,
                        let detail = instructionItem.stepDetail,
                        let instructionStep = step as? ORKInstructionStep {
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
    
    func tappingTask(_ options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        let duration: TimeInterval = taskOptions?["duration"] as? TimeInterval ?? 10.0
        let handOptions = ORKPredefinedTaskHandOption(name: taskOptions?["handOptions"] as? String)
        return ORKOrderedTask.twoFingerTappingIntervalTask(
            withIdentifier: self.schemaIdentifier,
            intendedUseDescription: self.intendedUseDescription,
            duration: duration,
            handOptions: handOptions,
            options: options)
    }
    
    func memoryTask(_ options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        let initialSpan: Int = (taskOptions?["initialSpan"] as? NSNumber)?.intValue ?? 3
        let minimumSpan: Int = (taskOptions?["minimumSpan"] as? NSNumber)?.intValue ?? 2
        let maximumSpan: Int = (taskOptions?["maximumSpan"] as? NSNumber)?.intValue ?? 15
        let playSpeed: TimeInterval = taskOptions?["playSpeed"] as? TimeInterval ?? 1.0
        let maxTests: Int = (taskOptions?["maxTests"] as? NSNumber)?.intValue ?? 5
        let maxConsecutiveFailures: Int = (taskOptions?["maxConsecutiveFailures"] as? NSNumber)?.intValue ?? 3
        var customTargetImage: UIImage? = nil
        if let imageName = taskOptions?["customTargetImageName"] as? String {
            customTargetImage = SBAResourceFinder.shared.image(forResource: imageName)
        }
        let customTargetPluralName: String? = taskOptions?["customTargetPluralName"] as? String
        let requireReversal: Bool = taskOptions?["requireReversal"] as? Bool ?? false
        
        return ORKOrderedTask.spatialSpanMemoryTask(withIdentifier: self.schemaIdentifier,
                                                                  intendedUseDescription: self.intendedUseDescription,
                                                                  initialSpan: initialSpan,
                                                                  minimumSpan: minimumSpan,
                                                                  maximumSpan: maximumSpan,
                                                                  playSpeed: playSpeed,
                                                                  maximumTests: maxTests,
                                                                  maximumConsecutiveFailures: maxConsecutiveFailures,
                                                                  customTargetImage: customTargetImage,
                                                                  customTargetPluralName: customTargetPluralName,
                                                                  requireReversal: requireReversal,
                                                                  options: options)
    }
    
    func voiceTask(_ options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        let speechInstruction: String? = taskOptions?["speechInstruction"] as? String
        let shortSpeechInstruction: String? = taskOptions?["shortSpeechInstruction"] as? String
        let duration: TimeInterval = taskOptions?["duration"] as? TimeInterval ?? 10.0
        let recordingSettings: [String: AnyObject]? = taskOptions?["recordingSettings"] as? [String: AnyObject]
        
        return ORKOrderedTask.audioTask(withIdentifier: self.schemaIdentifier,
            intendedUseDescription: self.intendedUseDescription,
            speechInstruction: speechInstruction,
            shortSpeechInstruction: shortSpeechInstruction,
            duration: duration,
            recordingSettings: recordingSettings,
            checkAudioLevel: true,
            options: options)
    }
    
    func walkingTask(_ options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        // The walking activity is assumed to be walking back and forth rather than trying to walk down a long hallway.
        let walkDuration: TimeInterval = taskOptions?["walkDuration"] as? TimeInterval ?? 30.0
        let restDuration: TimeInterval = taskOptions?["restDuration"] as? TimeInterval ?? 30.0
        
        return ORKOrderedTask.walkBackAndForthTask(withIdentifier: self.schemaIdentifier,
                                                                 intendedUseDescription: self.intendedUseDescription,
                                                                 walkDuration: walkDuration,
                                                                 restDuration: restDuration,
                                                                 options: options)
    }
    
    func tremorTask(_ options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        let duration: TimeInterval = taskOptions?["duration"] as? TimeInterval ?? 10.0
        let handOptions = ORKPredefinedTaskHandOption(name: taskOptions?["handOptions"] as? String)
        let excludeOptions = ORKTremorActiveTaskOption(excludes: taskOptions?["excludePostions"] as? [String])
        
        return ORKOrderedTask.tremorTest(withIdentifier: self.schemaIdentifier,
                                                           intendedUseDescription: self.intendedUseDescription,
                                                           activeStepDuration: duration,
                                                           activeTaskOptions: excludeOptions,
                                                           handOptions: handOptions,
                                                           options: options)
    }
    
    func moodSurvey(_ options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        let frequency = ORKMoodSurveyFrequency(name: taskOptions?["frequency"] as? String)
        let customQuestionText = taskOptions?["customQuestionText"] as? String
        
        return ORKOrderedTask.moodSurvey(withIdentifier: self.schemaIdentifier,
                                                       intendedUseDescription: self.intendedUseDescription,
                                                       frequency: frequency,
                                                       customQuestionText: customQuestionText,
                                                       options: options)
    }
    
    func trailmakingTask(_ options: ORKPredefinedTaskOption) -> ORKOrderedTask {
        
        let trailType: ORKTrailMakingTypeIdentifier = {
            guard let trailType = taskOptions?["trailType"] as? String else {
                return ORKTrailMakingTypeIdentifier.B
            }
            return ORKTrailMakingTypeIdentifier(rawValue: trailType)
        }()
        let trailmakingInstruction = taskOptions?["trailmakingInstruction"] as? String
        
        return ORKOrderedTask.trailmakingTask(withIdentifier: self.schemaIdentifier,
                                              intendedUseDescription: self.intendedUseDescription,
                                              trailmakingInstruction: trailmakingInstruction,
                                              trailType: trailType,
                                              options: options)
    }
}


