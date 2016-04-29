//
//  SBATrackedDataObjectTests.swift
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

import XCTest
import ResearchKit
import BridgeAppSDK

class SBATrackedDataObjectTests: ResourceTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    func testMedicationArchiveAndUnarchive() {
        
        // Create a medication
        let duopa = SBAMedication(dictionaryRepresentation: [
            "identifier"            : "Duopa",
            "name"                  : "Carbidopa/Levodopa",
            "detail"                : "Continuous Infusion",
            "brand"                 : "Duopa",
            "tracking"              : true,
            "injection"             : true,
            ])
        
        
        // Modify the frequency
        duopa.frequency = 4;
        
        // Archive
        let data = NSKeyedArchiver.archivedDataWithRootObject([duopa]);
        
        // Unarchive it and check the result
        guard let arr = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [SBAMedication],
            let med = arr.first else {
                XCTAssert(false, "Value did not unarchive as array")
                return
        }
        
        XCTAssertEqual(duopa.identifier, med.identifier)
        XCTAssertEqual(duopa.name, med.name)
        XCTAssertEqual(duopa.brand, med.brand)
        XCTAssertEqual(duopa.detail, med.detail)
        XCTAssertEqual(duopa.frequency, med.frequency)
        XCTAssertTrue(duopa.tracking)
        XCTAssertTrue(duopa.injection)
    }
    
    func testMedicationTrackerFromResourceFile() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        XCTAssertEqual(dataCollection.taskIdentifier, "1-APHMedicationTracker-20EF8ED2-E461-4C20-9024-F43FCAAAF4C3")
        XCTAssertEqual(dataCollection.schemaIdentifier, "Medication Tracker")
        XCTAssertEqual(dataCollection.schemaRevision, 8)
    }
    
    func testMedicationTrackerFromResourceFile_Items() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        XCTAssertEqual(dataCollection.itemsClassType, "Medication")
        
        let expectedCount = 15
        XCTAssertEqual(dataCollection.items.count, expectedCount);
        if (dataCollection.items.count != expectedCount) {
            return
        }
        
        let meds = dataCollection.items;
        guard let levodopa = meds[0] as? SBAMedication,
            let carbidopa = meds[1] as? SBAMedication,
            let rytary = meds[2] as? SBAMedication,
            let duopa = meds.last as? SBAMedication
            else {
                XCTAssert(false, "items not of expected type \(meds)")
                return
        }
        
        XCTAssertEqual(levodopa.identifier, "Levodopa");
        XCTAssertEqual(levodopa.name, "Levodopa");
        XCTAssertEqual(levodopa.text, "Levodopa");
        XCTAssertEqual(levodopa.shortText, "Levodopa");
        XCTAssertTrue(levodopa.tracking);
        XCTAssertFalse(levodopa.injection);
        
        XCTAssertEqual(carbidopa.identifier, "Carbidopa");
        XCTAssertEqual(carbidopa.name, "Carbidopa");
        XCTAssertEqual(carbidopa.text, "Carbidopa");
        XCTAssertEqual(carbidopa.shortText, "Carbidopa");
        XCTAssertFalse(carbidopa.tracking);
        XCTAssertFalse(carbidopa.injection);
        
        XCTAssertEqual(rytary.identifier, "Rytary");
        XCTAssertEqual(rytary.name, "Carbidopa/Levodopa");
        XCTAssertEqual(rytary.brand, "Rytary");
        XCTAssertEqual(rytary.text, "Carbidopa/Levodopa (Rytary)");
        XCTAssertEqual(rytary.shortText, "Rytary");
        XCTAssertTrue(rytary.tracking);
        XCTAssertFalse(rytary.injection);
        
        XCTAssertEqual(duopa.identifier, "Duopa");
        XCTAssertEqual(duopa.name, "Carbidopa/Levodopa");
        XCTAssertEqual(duopa.brand, "Duopa");
        XCTAssertEqual(duopa.detail, "Continuous Infusion");
        XCTAssertEqual(duopa.text, "Carbidopa/Levodopa Continuous Infusion (Duopa)");
        XCTAssertEqual(duopa.shortText, "Duopa");
        XCTAssertFalse(duopa.tracking);
        XCTAssertTrue(duopa.injection);
        
    }
    
    func testMedicationTrackerFromResourceFile_Steps_StandAloneSurvey() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        let include = SBATrackingStepIncludes.StandAloneSurvey
        let steps = dataCollection.filteredSteps(include)
        
        checkStandAloneSurveySteps(steps, dataCollection: dataCollection)
    }
    
    func checkStandAloneSurveySteps(steps: [ORKStep], dataCollection: SBATrackedDataObjectCollection) {
    
        let expectedCount = 5
        XCTAssertEqual(steps.count, expectedCount)
        guard steps.count == expectedCount else { return }
        
        // Step 1
        guard let introStep = steps[0] as? ORKInstructionStep else {
            XCTAssert(false, "\(steps[0]) not of expected type")
            return
        }
        XCTAssertEqual(introStep.identifier, "medicationIntroduction")
        XCTAssertEqual(introStep.title, "Diagnosis and Medication")
        XCTAssertEqual(introStep.text, "We want to understand how certain medications affect the app activities. To do that we need more information from all study participants.\n\nPlease tell us if you have PD and if you take medications from the proposed list. We’ll ask you again from time to time to track any changes.\n\nThis survey should take about 5 minutes.")
        
        // Step 2
        let dataGroupsStep = steps[1]
        XCTAssertEqual(dataGroupsStep.identifier, "dataGroups")
        
        // Step 3
        let selectionStep = steps[2]
        XCTAssertEqual(selectionStep.identifier, "medicationSelection")
        XCTAssertEqual(selectionStep.text, "Do you take any of these medications?\n(Please select all that apply)")
        checkMedicationSelectionStep(selectionStep, optional: true)
        
        // Step 4
        guard let frequencyStep = steps[3] as? SBATrackedFormStep else {
            XCTAssert(false, "\(steps[3]) not of expected type")
            return
        }
        XCTAssertEqual(frequencyStep.identifier, "medicationFrequency")
        XCTAssertEqual(frequencyStep.text, "How many times a day do you take each of the following medications?")
        checkMedicationFrequencyStep(frequencyStep, idList: [], expectedFrequencyIds: [], items: dataCollection.items)
        checkMedicationFrequencyStep(frequencyStep, idList: ["Levodopa", "Carbex", "Duopa"], expectedFrequencyIds: ["Levodopa", "Carbex"], items: dataCollection.items)
        checkMedicationFrequencyStep(frequencyStep, idList: ["Duopa"], expectedFrequencyIds: [], items: dataCollection.items)
        
        // Step 5
        guard let conclusionStep = steps.last as? ORKInstructionStep else {
            XCTAssert(false, "\(steps.last) not of expected type")
            return
        }
        XCTAssertEqual(conclusionStep.identifier, "medicationConclusion")
        XCTAssertEqual(conclusionStep.title, "Thank You!")
        XCTAssertEqual(conclusionStep.text, "")
    }
    
    func testMedicationSelectionStep_NotOptional() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        let inputItem: NSDictionary = [
            "identifier"   : "medicationSelection",
            "trackingType" : "selection",
            "type"         : "trackingSelection",
            "text"         : "Do you take any of these medications?\n(Please select all that apply)",]
        
        let step = SBATrackedFormStep(surveyItem: inputItem, items:dataCollection.items)
        checkMedicationSelectionStep(step, optional: false)
    }
    
    func checkMedicationSelectionStep(step: ORKStep, optional: Bool) {
        
        guard let selectionStep = step as? SBATrackedFormStep else {
            XCTAssert(false, "\(step) not of expected type")
            return
        }
        let selectionFormItem = selectionStep.formItems?.first
        XCTAssertNotNil(selectionFormItem)
        guard let answerFormat = selectionFormItem?.answerFormat as? ORKTextChoiceAnswerFormat else {
            XCTAssert(false, "\(selectionFormItem?.answerFormat) not of expected type")
            return
        }
        XCTAssertEqual(selectionStep.identifier, "medicationSelection")
        XCTAssertFalse(selectionStep.optional)
        XCTAssertFalse(selectionStep.shouldSkipStep)
        XCTAssertEqual(selectionStep.formItems?.count, 1)
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.MultipleChoice)
        
        var expectedChoices = [ ["Levodopa", "Levodopa"],
                                ["Carbidopa", "Carbidopa"],
                                ["Carbidopa/Levodopa (Rytary)", "Rytary"],
                                ["Carbidopa/Levodopa (Sinemet)", "Sinemet"],
                                ["Carbidopa/Levodopa (Atamet)", "Atamet"],
                                ["Carbidopa/Levodopa/Entacapone (Stalevo)","Stalevo"],
                                ["Amantadine (Symmetrel)", "Symmetrel"],
                                ["Rotigotine (Neupro)", "Neupro"],
                                ["Selegiline (Eldepryl)", "Eldepryl"],
                                ["Selegiline (Carbex)", "Carbex"],
                                ["Selegiline (Atapryl)", "Atapryl"],
                                ["Pramipexole (Mirapex)", "Mirapex"],
                                ["Ropinirole (Requip)", "Requip"],
                                ["Apomorphine (Apokyn)", "Apokyn"],
                                ["Carbidopa/Levodopa Continuous Infusion (Duopa)", "Duopa"],
                                ["None of the above", "None"]];
        if (optional) {
            expectedChoices += [["Prefer not to answer", "Skipped"]];
        }
        XCTAssertEqual(answerFormat.textChoices.count, expectedChoices.count)
        if answerFormat.textChoices.count <= expectedChoices.count {
            for (idx, textChoice) in answerFormat.textChoices.enumerate() {
                XCTAssertEqual(textChoice.text, expectedChoices[idx].first!)
                if let value = textChoice.value as? String {
                    XCTAssertEqual(value, expectedChoices[idx].last!)
                }
                else {
                    XCTAssert(false, "\(textChoice.value) not expected type")
                }
                let exclusive = optional ? (idx >= expectedChoices.count - 2) : (idx == expectedChoices.count - 1);
                XCTAssertEqual(textChoice.exclusive, exclusive);
            }
        }
    }
    
    func checkMedicationFrequencyStep(step: SBATrackedFormStep, idList:[String], expectedFrequencyIds: [String], items:[SBATrackedDataObject]) {
        
        let selectedItems = items.filter({ idList.contains($0.identifier) })
        step.updateWithSelectedItems(selectedItems)
        XCTAssertEqual(step.formItems?.count, expectedFrequencyIds.count)
        XCTAssertEqual(step.shouldSkipStep, expectedFrequencyIds.count == 0)
        
        for identifier in idList {
            guard let item = items.objectWithIdentifier(identifier) else {
                XCTAssert(false, "Couldn't find item \(identifier)")
                return
            }
            let formItem = step.formItems?.objectWithIdentifier(identifier)
            if (expectedFrequencyIds.contains(item.identifier)) {
                XCTAssertNotNil(formItem, "\(identifier)")
                XCTAssertEqual(formItem?.text, item.text)
                if let answerFormat = formItem?.answerFormat as? ORKScaleAnswerFormat {
                    XCTAssertEqual(answerFormat.minimum, 1)
                    XCTAssertEqual(answerFormat.maximum, 12)
                    XCTAssertEqual(answerFormat.step, 1)
                }
                else {
                    XCTAssert(false, "\(formItem?.answerFormat) not expected type for \(identifier)")
                }
            }
            else {
                XCTAssertNil(formItem, "\(identifier)")
            }
        }
    }
    
    func testMedicationTrackerFromResourceFile_Steps_ActivityOnly() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        let include = SBATrackingStepIncludes.ActivityOnly
        let steps = dataCollection.filteredSteps(include)
        
        checkActivityOnlySteps(steps, dataCollection: dataCollection)
    }
    
    func checkActivityOnlySteps(steps: [ORKStep], dataCollection: SBATrackedDataObjectCollection) {
        
        let expectedCount = 2
        XCTAssertEqual(steps.count, expectedCount)
        guard steps.count == expectedCount else { return }
        
        guard let momentInDayStep = steps.first as? SBATrackedFormStep,
            let formItem = momentInDayStep.formItems?.first,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat
            else {
                XCTAssert(false, "\(steps.first) not of expected type")
                return
        }
        XCTAssertEqual(momentInDayStep.identifier, "momentInDay")
        XCTAssertFalse(momentInDayStep.optional)
        XCTAssertEqual(momentInDayStep.formItems?.count, 1)
        XCTAssertEqual(momentInDayStep.text, "We would like to understand how your performance on this activity could be affected by the timing of your medication.")
        XCTAssertEqual(formItem.identifier, "momentInDayFormat")
        XCTAssertEqual(formItem.text, "When are you performing this activity?")
        XCTAssertEqual(answerFormat.textChoices.count, 3)
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.SingleChoice)
        
        checkMedicationActivityStep(momentInDayStep, idList: ["Levodopa", "Carbidopa", "Rytary"], expectedSkipped: false, items: dataCollection.items)
        checkMedicationActivityStep(momentInDayStep, idList: ["Carbidopa"], expectedSkipped: true, items: dataCollection.items)
        
        guard let timingStep = steps.last as? SBATrackedFormStep,
            let timingFormItem = timingStep.formItems?.first,
            let timingAnswerFormat = timingFormItem.answerFormat as? ORKTextChoiceAnswerFormat
            else {
                XCTAssert(false, "\(steps.last) not of expected type")
                return
        }
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming")
        XCTAssertFalse(timingStep.optional)
        XCTAssertEqual(timingStep.formItems?.count, 1)
        XCTAssertEqual(timingFormItem.identifier, "medicationActivityTiming")
        
        // Look at the answer format
        XCTAssertEqual(timingAnswerFormat.style, ORKChoiceAnswerStyle.SingleChoice)
        let expectedTimeChoices = [ "0-30 minutes ago",
                                    "30-60 minutes ago",
                                    "1-2 hours ago",
                                    "2-4 hours ago",
                                    "4-8 hours ago",
                                    "More than 8 hours ago",
                                    "Not sure"]
        XCTAssertEqual(timingAnswerFormat.textChoices.count, expectedTimeChoices.count)
        for (idx, textChoice) in timingAnswerFormat.textChoices.enumerate() {
            if (idx < expectedTimeChoices.count) {
                XCTAssertEqual(textChoice.text, expectedTimeChoices[idx])
                if let value = textChoice.value as? String {
                    XCTAssertEqual(value, expectedTimeChoices[idx])
                }
                else {
                    XCTAssert(false, "\(textChoice.value) not of expected type")
                }
            }
        }
        
        // Check the text formatting
        checkMedicationActivityStep(timingStep, idList: ["Levodopa", "Carbidopa", "Rytary"], expectedSkipped: false, items: dataCollection.items)
        XCTAssertEqual(timingStep.text, "When was the last time you took your Levodopa or Rytary?")
        
        checkMedicationActivityStep(timingStep, idList: ["Carbidopa"], expectedSkipped: true, items: dataCollection.items)
        
        checkMedicationActivityStep(timingStep, idList: ["Levodopa", "Rytary", "Sinemet"], expectedSkipped: false, items: dataCollection.items)
        XCTAssertEqual(timingStep.text, "When was the last time you took your Levodopa, Rytary, or Sinemet?")
        
        checkMedicationActivityStep(timingStep, idList: ["Levodopa", "Rytary", "Sinemet", "Atamet"], expectedSkipped: false, items: dataCollection.items)
        XCTAssertEqual(timingStep.text, "When was the last time you took your Levodopa, Rytary, Sinemet, or Atamet?")

    }
    
    func checkMedicationActivityStep(step: SBATrackedFormStep, idList:[String], expectedSkipped: Bool, items:[SBATrackedDataObject]) {
        
        let selectedItems = items.filter({ idList.contains($0.identifier) })
        step.updateWithSelectedItems(selectedItems)
        XCTAssertEqual(step.shouldSkipStep, expectedSkipped, "\(idList)")
    }
    
    func testMedicationTrackerFromResourceFile_Steps_ChangedAndActivity() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        let include = SBATrackingStepIncludes.ChangedAndActivity
        let steps = dataCollection.filteredSteps(include)
        
        checkChangedAndActivitySteps(steps, expectedSkipIdentifier: "momentInDay", dataCollection: dataCollection)
    }
    
    func checkChangedAndActivitySteps(steps: [ORKStep], expectedSkipIdentifier: String, dataCollection: SBATrackedDataObjectCollection) {
        
        let expectedCount = 6
        XCTAssertEqual(steps.count, expectedCount)
        guard steps.count == expectedCount else { return }
        
        guard let changedStep = steps.first as? SBASurveyFormStep,
            let formItem = changedStep.formItems?.first as? SBASurveyFormItem,
            let _ = formItem.answerFormat as? ORKBooleanAnswerFormat else {
                XCTAssert(false, "\(steps.first) not of expected type")
                return
        }
        XCTAssertEqual(changedStep.identifier, "medicationChanged")
        XCTAssertEqual(changedStep.text, "Has your Parkinson diagnosis or medication changed?")
        XCTAssertTrue(changedStep.skipIfPassed)
        XCTAssertEqual(changedStep.skipToStepIdentifier, expectedSkipIdentifier)
        
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKBooleanQuestionResult(identifier:formItem.identifier)
        questionResult.booleanAnswer = false
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.booleanAnswer = true
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        // Step 2
        let dataGroupsStep = steps[1]
        XCTAssertEqual(dataGroupsStep.identifier, "dataGroups")
        
        // Step 3
        let selectionStep = steps[2]
        XCTAssertEqual(selectionStep.identifier, "medicationSelection")
        
        // Step 4
        let frequencyStep = steps[3]
        XCTAssertEqual(frequencyStep.identifier, "medicationFrequency")
        
        // Step 5
        let momentInDayStep = steps[4]
        XCTAssertEqual(momentInDayStep.identifier, "momentInDay")
        
        // Step 6
        let timingStep = steps[5]
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming")
    }
    
    func testMedicationTrackerFromResourceFile_Steps_ChangedAndNoMedsPreviouslySelected() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        let include = SBATrackingStepIncludes.ChangedOnly
        let steps = dataCollection.filteredSteps(include)
        
        checkChangedAndActivitySteps(steps, expectedSkipIdentifier: "nextSection", dataCollection: dataCollection)
    }

    func testMedicationTrackerFromResourceFile_Steps_SurveyAndActivity() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        let include = SBATrackingStepIncludes.SurveyAndActivity
        let steps = dataCollection.filteredSteps(include)
        
        checkSurveyAndActivitySteps(steps, dataCollection: dataCollection)
    }
    
    func checkSurveyAndActivitySteps(steps: [ORKStep], dataCollection: SBATrackedDataObjectCollection) {
        
        let expectedCount = 6
        XCTAssertEqual(steps.count, expectedCount)
        guard steps.count == expectedCount else { return }
        
        // Step 1
        let stepIntro = steps[0]
        XCTAssertEqual(stepIntro.identifier, "medicationIntroduction")
        
        // Step 2
        let dataGroupsStep = steps[1]
        XCTAssertEqual(dataGroupsStep.identifier, "dataGroups")
        
        // Step 3
        let selectionStep = steps[2]
        XCTAssertEqual(selectionStep.identifier, "medicationSelection")
        
        // Step 4
        let frequencyStep = steps[3]
        XCTAssertEqual(frequencyStep.identifier, "medicationFrequency")
        
        // Step 5
        let momentInDayStep = steps[4]
        XCTAssertEqual(momentInDayStep.identifier, "momentInDay")
        
        // Step 6
        let timingStep = steps[5]
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming")
    }
    
    // MARK: transformToStep tests

    func testTransformToStep_StandAlone() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        let step = dataCollection.transformToStep(SBASurveyFactory(), isLastStep: true)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkStandAloneSurveySteps(task.steps, dataCollection: dataCollection)
    }
    
    func testTransformToStep_EmptySet_LastSurveyToday() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        // If the selected items set is empty (but there is one) then do not show the activity steps
        dataStore.lastTrackingSurveyDate = NSDate()
        dataStore.selectedItems = []
        
        let step = dataCollection.transformToStep(SBASurveyFactory(), isLastStep: false)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        XCTAssertEqual(task.steps.count, 0)
    }
    
    func testTransformToStep_InjectionOnlySet_LastSurveyToday() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        // If the selected items set does not include any that are tracked then should
        // return the empty set (for a date in the near past)
        dataStore.lastTrackingSurveyDate = NSDate()
        dataStore.selectedItems = dataCollection.items.filter({ !$0.usesFrequencyRange })
        
        let step = dataCollection.transformToStep(SBASurveyFactory(), isLastStep: false)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        XCTAssertEqual(task.steps.count, 0)
    }
    
    func testTransformToStep_ActivityOnly() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        // If the activity steps includes a tracked item, then should include the activty 
        // steps, but do not need to include any of the others
        dataStore.lastTrackingSurveyDate = NSDate()
        dataStore.selectedItems = dataCollection.items.filter({ $0.identifier == "Levodopa" })
        let step = dataCollection.transformToStep(SBASurveyFactory(), isLastStep: false)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkActivityOnlySteps(task.steps, dataCollection: dataCollection)
    }
    
    func testTransformToStep_ChangedAndActivity_CurrentlyHasTracked() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        // If the activity steps includes a tracked item and the last survey was more than
        // 30 days ago then should ask about changes
        dataStore.lastTrackingSurveyDate = NSDate(timeIntervalSinceNow: -40*24*60*60)
        dataStore.selectedItems = dataCollection.items.filter({ $0.identifier == "Levodopa" })
        let step = dataCollection.transformToStep(SBASurveyFactory(), isLastStep: false)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkChangedAndActivitySteps(task.steps, expectedSkipIdentifier: "momentInDay", dataCollection: dataCollection)
    }
    
    func testTransformToStep_ChangedAndActivity_NoMedsCurrentlyTracked() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        // If the activity steps includes a tracked item and the last survey was more than
        // 30 days ago then should ask about changes
        dataStore.lastTrackingSurveyDate = NSDate(timeIntervalSinceNow: -40*24*60*60)
        dataStore.selectedItems = []
        let step = dataCollection.transformToStep(SBASurveyFactory(), isLastStep: false)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkChangedAndActivitySteps(task.steps, expectedSkipIdentifier: "nextSection", dataCollection: dataCollection)
    }
    
    func checkDataStoreDefaultIDMap(dataStore: SBATrackedDataStore) {

        guard let defaultMap = dataStore.momentInDayResultDefaultIdMap as? [[String]] else {
            XCTAssert(false, "\(dataStore.momentInDayResultDefaultIdMap) not of expected type")
            return
        }
        
        let expectedMap =
            [["momentInDay", "momentInDayFormat"],
             ["medicationActivityTiming", "medicationActivityTiming"]];
        
        XCTAssertEqual(defaultMap, expectedMap);
    }
    
    // Mark: Navigation tests
    
    func testNavigation_NoMedsSelected() {
        let (task, dataStore, selectionStep, taskResult) = stepToSelection(["None"])
        guard task != nil else { return }

        // make selection
        let nextStep = task!.stepAfterStep(selectionStep, withResult: taskResult!)
        XCTAssertNil(nextStep)
        XCTAssertNotNil(dataStore!.selectedItems)
        
        guard let selectedItems = dataStore!.selectedItems else { return }
        XCTAssertEqual(selectedItems.count, 0)
    }
    
    func testNavigation_MedsSelected_Grouped() {
        
        // Check shared functionality
        let (retTask, retDataStore, selectionStep, retTaskResult) = stepToSelection(["Levodopa", "Carbidopa", "Rytary", "Apokyn"])
        guard let task = retTask, let dataStore = retDataStore, let taskResult = retTaskResult,
              let timingStep = checkMedsSelectedSteps(task, dataStore, selectionStep!, taskResult, trackEach: false)
        else {
            return
        }
        
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming")
    }
    
    func testNavigation_MedsSelected_TrackEach() {
        
        // Check shared functionality
        let (retTask, retDataStore, selectionStep, retTaskResult) = stepToSelection(["Levodopa", "Carbidopa", "Rytary", "Apokyn"])
        guard let task = retTask, let dataStore = retDataStore, let taskResult = retTaskResult,
            let timingStep = checkMedsSelectedSteps(task, dataStore, selectionStep!, taskResult, trackEach: true)
            else {
                return
        }
        
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming.Levodopa")

        // Add the timing result
        guard let formItem = timingStep.formItems?.first else { return }
        let questionResult = ORKChoiceQuestionResult(identifier: formItem.identifier)
        questionResult.choiceAnswers = ["0-30 minutes"]
        let momentResult = ORKStepResult(stepIdentifier: timingStep.identifier, results: [questionResult])
        taskResult.results! += [momentResult]
        
        let nextStep = task.stepAfterStep(timingStep, withResult: taskResult)
        XCTAssertNotNil(dataStore.momentInDayResult)
        XCTAssertEqual(dataStore.momentInDayResult!.count, 2)
        
        XCTAssertEqual(nextStep!.identifier, "medicationActivityTiming.Rytary")
    }
    
    func checkMedsSelectedSteps(task: ORKTask, _ dataStore: SBATrackedDataStore, _ selectionStep: SBATrackedFormStep, _ taskResult: ORKTaskResult, trackEach: Bool) -> SBATrackedFormStep? {
        
        // setup last question for trackEach
        if  let orderedTask = task as? ORKOrderedTask,
            let lastStep = orderedTask.steps.last as? SBATrackedFormStep {
            lastStep.trackEach = trackEach
        }
    
        // get the next step
        let nextStep = task.stepAfterStep(selectionStep, withResult: taskResult)
        XCTAssertNotNil(nextStep)
        XCTAssertNotNil(dataStore.selectedItems)
        
        // check that the selected items is set in the data store
        guard let selectedItems = dataStore.selectedItems else { return nil }
        XCTAssertEqual(selectedItems.count, 4)
        
        // Check that the next step is the frequency step
        guard let frequencyStep = nextStep as? SBATrackedFormStep where frequencyStep.trackingType == .Frequency,
            let formItems = frequencyStep.formItems  else {
            XCTAssert(false, "\(nextStep) not of expected type")
            return nil
        }
        XCTAssertEqual(formItems.count, 3)
        
        // Build frequency results and add to the task results
        let frequencyResults = formItems.map { (formItem) -> ORKScaleQuestionResult in
            let result = ORKScaleQuestionResult(identifier: formItem.identifier)
            result.scaleAnswer = formItem.identifier.characters.count
            return result
        }
        let frequencyStepResult = ORKStepResult(stepIdentifier: frequencyStep.identifier, results: frequencyResults)
        taskResult.results! += [frequencyStepResult]
        
        // Get the moment in day step
        let step2 = task.stepAfterStep(frequencyStep, withResult: taskResult)
        for item in dataStore.selectedItems! {
            if (item.usesFrequencyRange) {
                XCTAssertEqual(item.frequency, UInt(item.identifier.characters.count), "\(item.identifier)")
            }
        }
        
        guard let momentStep = step2 as? SBATrackedFormStep where momentStep.trackingType == .Activity,
            let formItem = momentStep.formItems?.first  else {
                XCTAssert(false, "\(nextStep) not of expected type")
                return nil
        }
        
        // Add the moment in day result
        let questionResult = ORKChoiceQuestionResult(identifier: formItem.identifier)
        questionResult.choiceAnswers = ["Another time"]
        let momentResult = ORKStepResult(stepIdentifier: momentStep.identifier, results: [questionResult])
        taskResult.results! += [momentResult]
        
        let step3 = task.stepAfterStep(momentStep, withResult: taskResult)
        XCTAssertNotNil(dataStore.momentInDayResult)
        XCTAssertEqual(dataStore.momentInDayResult!.count, 1)
        
        return step3 as? SBATrackedFormStep
    }
    
    // Mark: convenience methods
    
    func dataStoreForMedicationTracking() -> SBATrackedDataStore? {
        let result: AnyClass? = SBAClassTypeMap.sharedMap().classForClassType("MockTrackedDataStore")
        XCTAssertNotNil(result)
        guard let classType = result as? SBATrackedDataStore.Type else {
            XCTAssert(false, "\(result) not of expected class type")
            return nil
        }
        return classType.init()
    }
    
    func dataCollectionForMedicationTracking() -> SBATrackedDataObjectCollection? {
        guard let json = self.jsonForResource("MedicationTracking") as? [NSObject: AnyObject] else {
            return nil
        }
        return SBATrackedDataObjectCollection(dictionaryRepresentation: json)
    }

    func stepToSelection(choiceAnswers: [String]) -> (task: ORKTask?, dataStore: SBATrackedDataStore?, selectionStep: SBATrackedFormStep?, taskResult: ORKTaskResult?) {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return (nil,nil,nil, nil) }
        dataCollection.dataStore = dataStore
        
        let transformedStep = dataCollection.transformToStep(SBASurveyFactory(), isLastStep: false)
        guard let subtaskStep = transformedStep as? SBASubtaskStep
            else {
                XCTAssert(false, "\(transformedStep) not of expected type")
                return (nil,nil,nil, nil)
        }
        
        // Iterate through the steps before the selection step
        let task = subtaskStep.subtask
        let taskResult = ORKTaskResult(identifier: task.identifier)
        taskResult.results = []
        var step: ORKStep? = nil
        repeat {
            if let previousStep = step {
                let stepResult = ORKStepResult(stepIdentifier: previousStep.identifier, results: nil)
                taskResult.results! += [stepResult]
            }
            guard let nextStep = task.stepAfterStep(step, withResult: taskResult) else {
                XCTAssert(false, "\(step) after not expected to be nil")
                return (nil,nil,nil, nil)
            }
            step = nextStep
        } while (step!.identifier != "medicationSelection")
        
        guard let selectionStep = step as? SBATrackedFormStep,
              let formItem = selectionStep.formItems?.first
        else {
            XCTAssert(false, "\(transformedStep) not of expected type")
            return (nil,nil,nil, nil)
        }
        
        // Add a question answer to the selection step
        let questionResult = ORKChoiceQuestionResult(identifier: formItem.identifier)
        questionResult.choiceAnswers = choiceAnswers
        let selectionResult = ORKStepResult(stepIdentifier: selectionStep.identifier, results: [questionResult])
        taskResult.results! += [selectionResult]
        
        return (task, dataStore, selectionStep, taskResult)
    }
}
