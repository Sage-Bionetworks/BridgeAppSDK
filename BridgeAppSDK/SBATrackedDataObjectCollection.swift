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
    
    public func transformToTask(factory: SBASurveyFactory, isLastStep: Bool) -> protocol <ORKTask, NSCopying, NSSecureCoding>? {
        
        // Check the dataStore to determine if the momentInDay id map has been setup and do so if needed
        if (self.dataStore.momentInDayResultDefaultIdMap == nil) {
            self.dataStore.updateMomentInDayIdMap(filteredSteps(.ActivityOnly, factory: factory))
        }
        
        // Build the approproate steps
        var steps: [ORKStep]!
        if (isLastStep) {
            // If this is the last step then it is not being inserted into another task activity
            steps = filteredSteps(.StandAloneSurvey, factory: factory)
        }
        else if (!self.dataStore.hasSelectedOrSkipped) {
            steps = filteredSteps(.SurveyAndActivity, factory: factory)
        }
        else if (self.shouldShowChangedStep()) {
            if (self.dataStore.hasNoTrackedItems) {
                steps = filteredSteps(.ChangedOnly, factory: factory)
            }
            else {
                steps = filteredSteps(.ChangedAndActivity, factory: factory)
            }
        }
        else if (self.dataStore.shouldIncludeMomentInDayStep ||
                (self.alwaysIncludeActivitySteps && !self.dataStore.hasNoTrackedItems)) {
            steps = filteredSteps(.ActivityOnly, factory: factory)
        }
        else {
            // Exit early with nil if there are no steps to return
            return nil
        }
        
        let task = SBANavigableOrderedTask(identifier: self.schemaIdentifier, steps: steps)
        task.conditionalRule = self
        
        return task
    }
    
    public func transformToStep(factory: SBASurveyFactory, isLastStep: Bool) -> ORKStep? {
        
        guard let task = transformToTask(factory, isLastStep: isLastStep) else { return nil }
        
        let subtaskStep = SBASubtaskStep(subtask: task)
        subtaskStep.taskIdentifier = self.taskIdentifier
        subtaskStep.schemaIdentifier = self.schemaIdentifier
        
        return subtaskStep
    }
    
    // MARK: SBAConditionalRule
    
    public func shouldSkipStep(step: ORKStep?, result: ORKTaskResult) -> Bool {

        // Check if this step is a tracked step. If the tracked step is nil then should *not* skip the step
        guard let trackedStep = step as? SBATrackedFormStep else { return false }
        
        // Otherwise, update the step with the selected items and then determine if it should be skipped
        trackedStep.updateWithSelectedItems(self.dataStore.selectedItems ?? [])
        return trackedStep.shouldSkipStep
    }
    
    public func nextStep(previousStep: ORKStep?, nextStep: ORKStep?, result: ORKTaskResult) -> ORKStep? {
        
        if let previous = previousStep as? SBATrackedFormStep {
            
            // update the previous step with the result
            switch (previous.trackingType!) {
            case .Selection:
                self.dataStore.updateSelectedItems(self.items, stepIdentifier: previous.identifier, result: result)
            case .Frequency:
                self.dataStore.updateFrequencyForStepIdentifier(previous.identifier, result: result)
            case .Activity:
                self.dataStore.updateMomentInDayForStepIdentifier(previous.identifier, result: result)
            default:
                break
            }
            
            // If this step is a trackEach, then split into multiple steps
            if previous.trackEach,
                let previousTrackedId = previous.trackedItemIdentifier,
                let selectedItems = self.dataStore.selectedItems?.filter({ $0.tracking })
            {
                guard let nextItem = selectedItems.nextObject({ $0.identifier == previousTrackedId })
                else {
                    // the previous item was the last tracked item so return nil
                    return nil
                }
                // create a copy of the step with the next item to be tracked
                return previous.copyWithTrackedItem(nextItem)
            }
        }
        else if let next = nextStep as? SBATrackedFormStep
                where next.trackEach && next.trackedItemIdentifier == nil,
                let firstItem = self.dataStore.selectedItems?.filter({ $0.tracking }).first {
            // If this is the first step in a step where each item is tracked separately, then 
            // replace the next step with a copy that includes the first selected item
            return next.copyWithTrackedItem(firstItem)
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
                // and let the factory create the step
                guard include.shouldInclude(trackingType),
                    let step = factory.createSurveyStep(trackingItem, trackedItems: self.items)
                else {
                    return nil
                }

                // Keep a pointer to the first activity step
                if (trackingType == .Activity) && (firstActivityStepIdentifier == nil) {
                    firstActivityStepIdentifier = step.identifier
                }
                
                return step
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
            where include.nextStepIfNoChange == .Activity  {
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
        if let _ = self.findStep(.Changed), let lastDate = self.dataStore.lastTrackingSurveyDate {
            let interval = self.repeatTimeInterval as NSTimeInterval
            return interval > 0 && lastDate.timeIntervalSinceNow < -1 * interval
        }
        else {
            return false
        }
    }
}
