//
//  SBADataObjectCollection.swift
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

extension SBATrackedDataObjectCollection: SBABridgeTask, SBAStepTransformer, SBAConditionalRule {
    
    // MARK: SBABridgeTask
    
    public var taskSteps: [SBAStepTransformer] {
        return [self]
    }

    public var insertSteps: [SBAStepTransformer]? {
        return nil
    }
    
    // MARK: SBAStepTransformer
    
    func transformToTaskAndIncludes(factory: SBASurveyFactory, isLastStep: Bool) -> (task: SBANavigableOrderedTask?, include: SBATrackingStepIncludes?)  {
        
        // Check the dataStore to determine if the momentInDay id map has been setup and do so if needed
        if (self.dataStore.momentInDayResultDefaultIdMap == nil) {
            self.dataStore.updateMomentInDayIdMap(filteredSteps(.ActivityOnly, factory: factory))
        }
        
        // Build the approproate steps
        
        var include: SBATrackingStepIncludes = .None
        if (isLastStep) {
            // If this is the last step then it is not being inserted into another task activity
            include = .StandAloneSurvey
        }
        else if (!self.dataStore.hasSelectedOrSkipped) {
            include = .SurveyAndActivity
        }
        else if (self.shouldShowChangedStep()) {
            if (self.dataStore.hasNoTrackedItems) {
                include = .ChangedOnly
            }
            else {
                include = .ChangedAndActivity
            }
        }
        else if (self.dataStore.shouldIncludeMomentInDayStep ||
                (self.alwaysIncludeActivitySteps && !self.dataStore.hasNoTrackedItems)) {
            include = .ActivityOnly
        }
        
        let steps = filteredSteps(include, factory: factory)
        let task = SBANavigableOrderedTask(identifier: self.schemaIdentifier, steps: steps)
        task.conditionalRule = self
        
        return (task, include)
    }
    
    public func transformToStep(factory: SBASurveyFactory, isLastStep: Bool) -> ORKStep? {
        let (retTask, retInclude) = transformToTaskAndIncludes(factory, isLastStep: isLastStep)
        guard let task = retTask, let include = retInclude else { return nil }
        
        let subtaskStep = SBASubtaskStep(subtask: task)
        if (include.includeSurvey()) {
            // Only set the task and schema identifier if the full survey is included
            subtaskStep.taskIdentifier = self.taskIdentifier
            subtaskStep.schemaIdentifier = self.schemaIdentifier
        }
        
        return subtaskStep
    }
    
    // MARK: SBAConditionalRule
    
    public func shouldSkipStep(step: ORKStep?, result: ORKTaskResult) -> Bool {

        // Check if this step is a tracked step. If the tracked step is nil then should *not* skip the step
        guard let trackedStep = step as? SBATrackedNavigationStep else { return false }
        
        // Otherwise, update the step with the selected items and then determine if it should be skipped
        trackedStep.update(selectedItems: self.dataStore.selectedItems ?? [])
        return trackedStep.shouldSkipStep
    }
    
    public func nextStep(previousStep: ORKStep?, nextStep: ORKStep?, result: ORKTaskResult) -> ORKStep? {
        
        if let previous = previousStep as? SBATrackedNavigationStep, let trackingType = previous.trackingType {
            
            // update the previous step with the result
            switch (trackingType) {
            case .selection:
                self.dataStore.updateSelectedItems(self.items, stepIdentifier: previousStep!.identifier, result: result)
            case .frequency:
                self.dataStore.updateFrequencyForStepIdentifier(previousStep!.identifier, result: result)
            case .activity:
                if let stepResult = result.stepResultForStepIdentifier(previousStep!.identifier) {
                    self.dataStore.updateMomentInDayForStepResult(stepResult)
                }
            default:
                break
            }
        }
        
        return nextStep
    }
    
    // MARK: Functions for transforming and recording results
    
    public func filteredSteps(include: SBATrackingStepIncludes) -> [ORKStep] {
        return filteredSteps(include, factory: SBASurveyFactory())
    }
    
    private func filteredSteps(include: SBATrackingStepIncludes, factory: SBASurveyFactory) -> [ORKStep] {
        
        var firstActivityStepIdentifier: String?
        
        // Filter and map
        let steps: [ORKStep] = self.steps.mapAndFilter { (element) -> ORKStep? in
            
            // If the item is not of the expected protocol then ignore it
            guard let item = element as? SBASurveyItem else { return nil }
            
            // Look to see if the item has a tracking type and create the appropriate step if it does
            if let trackingItem = item as? SBATrackedStepSurveyItem,
                let trackingType = trackingItem.trackingType {
                
                // If should not include the tracking item then just return nil
                guard include.shouldInclude(trackingType) else { return nil }
                
                if trackingType == .activity, let activityItem = trackingItem as? SBATrackedActivitySurveyItem {
                    // keep a pointer to the first activity step identifier
                    if firstActivityStepIdentifier == nil {
                        firstActivityStepIdentifier = activityItem.identifier
                    }
                    // Let the activity item return the appropriate instance of the step
                    return activityItem.createTrackedActivityStep(self.items)
                }
                else if trackingType.isTrackedFormStepType() {
                    // If this is a selection/frequency step then return a tracked form step
                    return SBATrackedFormStep(surveyItem: trackingItem, items: self.items)
                }
                else {
                    // Otherwise, return the step from the factory
                    return factory.createSurveyStep(trackingItem)
                }
            }
            else if (include.includeSurvey()) {
                // If this is the survey then all non-tracking type items are included
                // otherwise, if only including activities then they are not.
                return factory.createSurveyStep(item)
            }
            return nil
        }
        
        // Map the next step identifier back into the changed step
        if let changedStep = steps.first as? SBASurveyFormStep,
            let nextStepIdentifier = firstActivityStepIdentifier
            where include.nextStepIfNoChange == .activity  {
            changedStep.skipToStepIdentifier = nextStepIdentifier
        }
        
        return steps
    }
    
    public func findStep(trackingType: SBATrackingStepType) -> SBATrackedStepSurveyItem? {
        return self.steps.findObject({ (obj) -> Bool in
            guard let trackingItem = obj as? SBATrackedStepSurveyItem,
                let type = trackingItem.trackingType else { return false }
            return type == trackingType
        }) as? SBATrackedStepSurveyItem
    }
    
    func shouldShowChangedStep() -> Bool {
        if let _ = self.findStep(.changed), let lastDate = self.dataStore.lastTrackingSurveyDate {
            let interval = self.repeatTimeInterval as NSTimeInterval
            return interval > 0 && lastDate.timeIntervalSinceNow < -1 * interval
        }
        else {
            return false
        }
    }
    
    func mutateSelectionStepResult(taskResult: ORKTaskResult) {
        guard let selectionItem = self.findStep(.selection),
              let stepResult = taskResult.stepResultForStepIdentifier(selectionItem.identifier),
              let firstResult = stepResult.results?.first
        else {
            // Only create the step for a task result that includes selection
            return
        }
        
        // Create and return a step result for the consolidated steps
        let trackedResult = SBATrackedDataSelectionResult(identifier: selectionItem.identifier)
        trackedResult.selectedItems = self.dataStore.selectedItems
        trackedResult.startDate = stepResult.startDate
        trackedResult.endDate = stepResult.endDate
        
        // Add the consolidated result to the step results
        stepResult.results = [firstResult, trackedResult]
    }
}
