//
//  SBAActiveTask+CardioChallenge.swift
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

import ResearchUXFactory

public enum BridgeCardioChallengeStepIdentifier: String {
    case instruction
    case heartRisk
    case workoutInstruction1
    case workoutInstruction2
    case breathingBefore
    case tiredBefore
    case walkInstruction
    case countdown
    case fitnessWalk = "fitness.walk"
    case heartRateBefore = "heartRate.before"
    case heartRateAfter = "heartRate.after"
    case heartRateBeforeCameraInstruction = "heartRate.before.cameraInstruction"
    case heartRateAfterCameraInstruction = "heartRate.after.cameraInstruction"
    case heartRateBeforeCountdown = "heartRate.before.countdown"
    case heartRateAfterCountdown = "heartRate.after.countdown"
    case outdoorInstruction = "outdoor.instruction"
    case breathingAfter
    case tiredAfter
    case surveyAfter
}

extension SBAActiveTask {
    
    /**
     Build a custom version of the Cardio Challenge Task.
     */
    public func createBridgeCardioChallenge(options: ORKPredefinedTaskOption, factory: SBASurveyFactory) -> ORKOrderedTask? {
        
        // If not iOS 10, then use the default
        let task = self.createDefaultORKActiveTask(options)
        guard #available(iOS 10.0, *), let orderedTask = task else { return task }
        
        var steps: [ORKStep] = []
        var conclusionStep: ORKStep?

        // Include all the inner steps in the workout so that they are included in the same progress
        // Also, replace images and steps as required to match designs
        let workoutSteps = orderedTask.steps.mapAndFilter ({ (step) -> [ORKStep]? in
            
            // Filter out the steps that aren't considered part of the workout (and included in the count)
            let cardioIdentifier = BridgeCardioChallengeStepIdentifier(rawValue: step.identifier)
            if cardioIdentifier == .instruction {
                steps.insert(step, at: 0)
                return nil
            }
            else if cardioIdentifier == .heartRisk {
                steps.insert(replaceCardioStepIfNeeded(step), at: 1)
                return nil
            }
            else if step is ORKCompletionStep {
                conclusionStep = step
                return nil
            }
            else if let permissionStep = step as? SBAPermissionsStep {
                for (idx, _) in permissionStep.permissionTypes.enumerated() {
                    steps.append(SBASinglePermissionStep(permissionsStep: permissionStep, index: idx))
                }
                return nil
            }
            
            if let workout = step as? ORKWorkoutStep {
                return workout.steps.map({ replaceCardioStepIfNeeded($0) })
            }
            else {
                return [replaceCardioStepIfNeeded(step)]
            }
            
        }).flatMap({ $0 })
        let workoutTask = ORKOrderedTask(identifier: "workout", steps: workoutSteps)
        let workoutStep = ORKWorkoutStep(identifier: workoutTask.identifier,
                                         pageTask: workoutTask,
                                         relativeDistanceOnly: !SBAInfoManager.shared.currentParticipant.isTestUser,
                                         options: [])
        
        // Do not use the consolidated recordings
        // TODO: syoung 07/19/2017 Refactor SBAArchiveResult to only archive the results that are included in the 
        // schema for a given activity. 
        workoutStep.recorderConfigurations = []
        
        steps.append(workoutStep)
        if conclusionStep != nil {
            steps.append(conclusionStep!)
        }
        
        return SBANavigableOrderedTask(identifier: orderedTask.identifier, steps: steps)
    }
    
    public func replaceCardioStepIfNeeded(_ step:ORKStep) -> ORKStep {
        guard let identifier = BridgeCardioChallengeStepIdentifier(rawValue: step.identifier)
        else {
            return step
        }
        switch(identifier) {
            
        case .heartRisk, .workoutInstruction1, .workoutInstruction2:
            return replaceInstructionStep(step, imageNamed: step.identifier)
       
        case .walkInstruction:
            let instructionStep = SBAInstructionBelowImageStep(identifier: step.identifier)
            instructionStep.title = step.title
            instructionStep.text = step.text
            instructionStep.image = SBAResourceFinder.shared.image(forResource: "phoneinpocketIllustration")
            return instructionStep
            
        case .breathingBefore, .breathingAfter:
            return SBAMoodScaleStep(step: step, images: nil)
            
        case .tiredBefore, .tiredAfter:
            return SBAMoodScaleStep(step: step, images: nil)

        default:
            return step
        }
    }
    
    public func replaceInstructionStep(_ step: ORKStep, imageNamed: String?) -> SBAInstructionStep {
        let instructionStep = SBAInstructionStep(identifier: step.identifier)
        instructionStep.title = step.title
        instructionStep.text = step.text
        if let detail = (step as? ORKInstructionStep)?.detailText {
            let popAction = SBAPopUpLearnMoreAction(identifier: step.identifier)
            popAction.learnMoreText = detail
            instructionStep.learnMoreAction = popAction
        }
        if imageNamed != nil {
            instructionStep.image = SBAResourceFinder.shared.image(forResource: imageNamed!)
        }
        return instructionStep
    }
    
}
