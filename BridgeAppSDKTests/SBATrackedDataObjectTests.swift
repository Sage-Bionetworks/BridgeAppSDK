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
        let data = NSKeyedArchiver.archivedData(withRootObject: [duopa]);
        
        // Unarchive it and check the result
        guard let arr = NSKeyedUnarchiver.unarchiveObject(with: data) as? [SBAMedication],
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
        
        XCTAssertEqual(dataCollection.taskIdentifier, "Medication Task")
        XCTAssertEqual(dataCollection.schemaIdentifier, "Medication Tracker")
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
        guard let levodopa = meds?[0] as? SBAMedication,
            let carbidopa = meds?[1] as? SBAMedication,
            let rytary = meds?[2] as? SBAMedication,
            let duopa = meds?.last as? SBAMedication
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
    
    func checkStandAloneSurveySteps(_ steps: [ORKStep], dataCollection: SBATrackedDataObjectCollection) {
    
        let expectedCount = 4
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
        
        let selectionPageStep = steps[1]
        let (selectionStep, frequencyStep) = splitMedicationSelectionStep(selectionPageStep)
        checkMedicationSelectionStep(selectionStep, optional: false)
        checkMedicationFrequencyStep(frequencyStep, idList: [], expectedFrequencyIds: [], items: dataCollection.items)
        checkMedicationFrequencyStep(frequencyStep, idList: ["Levodopa", "Carbex", "Duopa"], expectedFrequencyIds: ["Levodopa", "Carbex"], items: dataCollection.items)
        checkMedicationFrequencyStep(frequencyStep, idList: ["Duopa"], expectedFrequencyIds: [], items: dataCollection.items)
        
        
        guard let handStep = steps[2] as? ORKFormStep else {
            XCTAssert(false, "\(steps[2]) not of expected type")
            return
        }
        XCTAssertEqual(handStep.identifier, "dominantHand")
        XCTAssertEqual(handStep.text, "Which hand would you normally use to write or throw a ball?")
        
        guard let conclusionStep = steps.last as? ORKInstructionStep else {
            XCTAssert(false, "\(steps.last) not of expected type")
            return
        }
        XCTAssertEqual(conclusionStep.identifier, "medicationConclusion")
        XCTAssertEqual(conclusionStep.title, "Thank You!")
        XCTAssertNil(conclusionStep.text)
    }
    
    func testMedicationSelectionStep_Optional() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        let inputItem: NSDictionary = [
            "identifier"   : "medicationSelection",
            "trackingType" : "selection",
            "type"         : "trackingSelection",
            "text"         : "Do you take any of these medications?\n(Please select all that apply)",
            "optional"     : true,
            ]
        
        let step = SBASurveyFactory().createSurveyStep(inputItem, trackingType: .selection, trackedItems: dataCollection.items)
        let (selectionStep, _) = splitMedicationSelectionStep(step)
        
        checkMedicationSelectionStep(selectionStep, optional: true)
    }
    
    func splitMedicationSelectionStep(_ step: ORKStep?) -> (selection:ORKStep?, frequency:ORKStep?) {
        guard let selectionStep = step as? SBATrackedSelectionStep else {
            XCTAssert(false, "\(step) not of expected type")
            return (nil, nil)
        }
        return (selectionStep.steps.first, selectionStep.steps.last)
    }
    
    func checkMedicationSelectionStep(_ step: ORKStep?, optional: Bool) {
        
        guard let selectionStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) not of expected type")
            return
        }
        
        XCTAssertEqual(selectionStep.identifier, "medicationSelection")
        XCTAssertEqual(selectionStep.text, "Do you take any of these medications?\n(Please select all that apply)")
        
        let selectionFormItem = selectionStep.formItems?.first
        XCTAssertNotNil(selectionFormItem)
        guard let answerFormat = selectionFormItem?.answerFormat as? ORKTextChoiceAnswerFormat else {
            XCTAssert(false, "\(selectionFormItem?.answerFormat) not of expected type")
            return
        }
        XCTAssertEqual(selectionStep.identifier, "medicationSelection")
        XCTAssertFalse(selectionStep.isOptional)
        XCTAssertEqual(selectionStep.formItems?.count, 1)
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.multipleChoice)
        
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
            for (idx, textChoice) in answerFormat.textChoices.enumerated() {
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
    
    func checkMedicationFrequencyStep(_ step: ORKStep?, idList:[String], expectedFrequencyIds: [String], items:[SBATrackedDataObject]) {
        
        guard let trackNav = step as? SBATrackedNavigationStep, let formStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) not of expected type")
            return
        }
        
        XCTAssertEqual(formStep.identifier, "medicationFrequency")
        XCTAssertEqual(formStep.text, "How many times a day do you take each of the following medications?")
        
        let selectedItems = items.filter({ idList.contains($0.identifier) })
        trackNav.update(selectedItems: selectedItems)
        XCTAssertEqual(formStep.formItems?.count, expectedFrequencyIds.count)
        XCTAssertEqual(trackNav.shouldSkipStep, expectedFrequencyIds.count == 0)
        
        for identifier in idList {
            guard let item = items.find(withIdentifier: identifier) else {
                XCTAssert(false, "Couldn't find item \(identifier)")
                return
            }
            let formItem = formStep.formItems?.find(withIdentifier: identifier)
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
    
    func checkActivityOnlySteps(_ steps: [ORKStep], dataCollection: SBATrackedDataObjectCollection) {
        
        let expectedCount = 3
        XCTAssertEqual(steps.count, expectedCount)
        guard steps.count == expectedCount else { return }
        
        guard let momentInDayStep = steps.first as? SBATrackedActivityFormStep,
            let formItem = momentInDayStep.formItems?.first,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat
            else {
                XCTAssert(false, "\(steps.first) not of expected type")
                return
        }
        XCTAssertEqual(momentInDayStep.identifier, "momentInDay")
        XCTAssertFalse(momentInDayStep.isOptional)
        XCTAssertEqual(momentInDayStep.formItems?.count, 1)
        XCTAssertEqual(momentInDayStep.text, "We would like to understand how your performance on this activity could be affected by the timing of your medication.")
        XCTAssertEqual(formItem.identifier, "momentInDayFormat")
        XCTAssertEqual(formItem.text, "When are you performing this activity?")
        XCTAssertEqual(answerFormat.textChoices.count, 3)
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.singleChoice)
        
        checkMedicationActivityStep(momentInDayStep, idList: ["Levodopa", "Carbidopa", "Rytary"], expectedSkipped: false, items: dataCollection.items)
        checkMedicationActivityStep(momentInDayStep, idList: ["Carbidopa"], expectedSkipped: true, items: dataCollection.items)
        
        guard let timingStep = steps[1] as? SBATrackedActivityFormStep,
            let timingFormItem = timingStep.formItems?.first,
            let timingAnswerFormat = timingFormItem.answerFormat as? ORKTextChoiceAnswerFormat
            else {
                XCTAssert(false, "\(steps[1]) not of expected type")
                return
        }
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming")
        XCTAssertFalse(timingStep.isOptional)
        XCTAssertEqual(timingStep.formItems?.count, 1)
        XCTAssertEqual(timingFormItem.identifier, "medicationActivityTiming")
        
        // Look at the answer format
        XCTAssertEqual(timingAnswerFormat.style, ORKChoiceAnswerStyle.singleChoice)
        let expectedTimeChoices = [ "0-30 minutes ago",
                                    "30-60 minutes ago",
                                    "1-2 hours ago",
                                    "2-4 hours ago",
                                    "4-8 hours ago",
                                    "More than 8 hours ago",
                                    "Not sure"]
        XCTAssertEqual(timingAnswerFormat.textChoices.count, expectedTimeChoices.count)
        for (idx, textChoice) in timingAnswerFormat.textChoices.enumerated() {
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
    
    func checkMedicationActivityStep(_ step: SBATrackedNavigationStep, idList:[String], expectedSkipped: Bool, items:[SBATrackedDataObject]) {
        
        let selectedItems = items.filter({ idList.contains($0.identifier) })
        step.update(selectedItems: selectedItems)
        XCTAssertEqual(step.shouldSkipStep, expectedSkipped, "\(idList)")
    }
    
    func testMedicationTrackerFromResourceFile_Steps_ChangedAndActivity() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        let include = SBATrackingStepIncludes.ChangedAndActivity
        let steps = dataCollection.filteredSteps(include)
        
        checkChangedAndActivitySteps(steps, expectedSkipIdentifier: "momentInDay", dataCollection: dataCollection)
    }
    
    func checkChangedAndActivitySteps(_ steps: [ORKStep], expectedSkipIdentifier: String, dataCollection: SBATrackedDataObjectCollection) {
        
        let expectedCount = 6
        XCTAssertEqual(steps.count, expectedCount)
        guard steps.count == expectedCount else { return }
        
        guard let changedStep = steps.first as? SBANavigationFormStep,
            let formItem = changedStep.formItems?.first as? SBANavigationFormItem,
            let _ = formItem.answerFormat as? ORKBooleanAnswerFormat else {
                XCTAssert(false, "\(steps.first) not of expected type")
                return
        }
        XCTAssertEqual(changedStep.identifier, "medicationChanged")
        XCTAssertEqual(changedStep.text, "Has your medication changed?")
        XCTAssertTrue(changedStep.skipIfPassed)
        XCTAssertEqual(changedStep.skipToStepIdentifier, expectedSkipIdentifier)
        
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKBooleanQuestionResult(identifier:formItem.identifier)
        questionResult.booleanAnswer = false
        XCTAssertTrue(navigationRule.evaluate(with: questionResult))
        
        questionResult.booleanAnswer = true
        XCTAssertFalse(navigationRule.evaluate(with: questionResult))
        
        let selectionStep = steps[1]
        XCTAssertEqual(selectionStep.identifier, "medicationSelection")
        
        let handStep = steps[2]
        XCTAssertEqual(handStep.identifier, "dominantHand")
        
        let momentInDayStep = steps[3]
        XCTAssertEqual(momentInDayStep.identifier, "momentInDay")
        
        let timingStep = steps[4]
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming")
        
        let trackEachStep = steps[5]
        XCTAssertEqual(trackEachStep.identifier, "medicationTrackEach")
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
    
    func checkSurveyAndActivitySteps(_ steps: [ORKStep], dataCollection: SBATrackedDataObjectCollection) {
        
        let expectedCount = 6
        XCTAssertEqual(steps.count, expectedCount)
        guard steps.count == expectedCount else { return }
        
        let stepIntro = steps[0]
        XCTAssertEqual(stepIntro.identifier, "medicationIntroduction")
        
        let selectionStep = steps[1]
        XCTAssertEqual(selectionStep.identifier, "medicationSelection")
        
        let handStep = steps[2]
        XCTAssertEqual(handStep.identifier, "dominantHand")
        
        let momentInDayStep = steps[3]
        XCTAssertEqual(momentInDayStep.identifier, "momentInDay")
        
        let timingStep = steps[4]
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming")
        
        let trackEachStep = steps[5]
        XCTAssertEqual(trackEachStep.identifier, "medicationTrackEach")
    }
    
    // MARK: transformToStep tests

    func testTransformToStep_StandAlone() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: true)
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
        dataStore.lastTrackingSurveyDate = Date()
        dataStore.selectedItems = []
        
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        // Task should be empty
        XCTAssertEqual(task.steps.count, 0)
    }
    
    func testTransformToStep_InjectionOnlySet_LastSurveyToday() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        // If the selected items set does not include any that are tracked then should
        // return the empty set (for a date in the near past)
        dataStore.lastTrackingSurveyDate = Date()
        dataStore.selectedItems = dataCollection.items.filter({ !$0.usesFrequencyRange })
        
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        // Task should be empty
        XCTAssertEqual(task.steps.count, 0)
    }
    
    func testTransformToStep_ActivityOnly() {
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return }
        dataCollection.dataStore = dataStore
        
        // If the activity steps includes a tracked item, then should include the activty 
        // steps, but do not need to include any of the others
        dataStore.lastTrackingSurveyDate = Date()
        dataStore.selectedItems = dataCollection.items.filter({ $0.identifier == "Levodopa" })
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
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
        dataStore.lastTrackingSurveyDate = Date(timeIntervalSinceNow: -40*24*60*60)
        dataStore.selectedItems = dataCollection.items.filter({ $0.identifier == "Levodopa" })
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
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
        dataStore.lastTrackingSurveyDate = Date(timeIntervalSinceNow: -40*24*60*60)
        dataStore.selectedItems = []
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
        checkDataStoreDefaultIDMap(dataStore)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkChangedAndActivitySteps(task.steps, expectedSkipIdentifier: "nextSection", dataCollection: dataCollection)
    }
    
    func checkDataStoreDefaultIDMap(_ dataStore: SBATrackedDataStore) {

        guard let defaultMap = dataStore.momentInDayResultDefaultIdMap as? [Array <String>] else {
            XCTAssert(false, "\(dataStore.momentInDayResultDefaultIdMap) not of expected type")
            return
        }
        
        let expectedMap =
            [["momentInDay", "momentInDayFormat"],
             ["medicationActivityTiming", "medicationActivityTiming"],
             ["medicationTrackEach", "medicationTrackEach"]];
        
        XCTAssertEqual(defaultMap.count, expectedMap.count)
        
        for (index, pair) in defaultMap.enumerated() {
            let expected = expectedMap[index]
            XCTAssertEqual(expected, pair)
        }
    }
    
    // Mark: Navigation tests
    
    func testNavigation_NoMedsSelected() {
        let (task, dataStore, selectionStep, taskResult) = stepToSelection(["None"])
        guard task != nil else { return }

        // make selection
        let nextStep = task!.step(after: selectionStep, with: taskResult!)
        XCTAssertNotNil(nextStep)
        XCTAssertNotNil(dataStore!.selectedItems)
        
        guard let selectedItems = dataStore!.selectedItems else { return }
        XCTAssertEqual(selectedItems.count, 0)
        
        guard let nextStepIdentifier = nextStep?.identifier else { return }
        XCTAssertEqual(nextStepIdentifier, "dominantHand")

    }
    
    
    func testNavigation_MedsSelected_TrackEach() {
        
        // Check shared functionality
        let (retTask, retDataStore, selectionStep, retTaskResult) = stepToSelection(["Levodopa", "Carbidopa", "Rytary", "Apokyn"])
        guard let task = retTask, let dataStore = retDataStore, let taskResult = retTaskResult else { return }
        
        // get the next step
        let nextStep = task.step(after: selectionStep, with: taskResult)
        XCTAssertNotNil(nextStep)
        XCTAssertNotNil(dataStore.selectedItems)
        
        // check that the selected items is set in the data store
        guard let selectedItems = dataStore.selectedItems else { return }
        XCTAssertEqual(selectedItems.count, 4)
        
        checkSelectionItemsInserted(dataStore.selectedItems!, taskResult: taskResult)
        
        // check that the frequency values are set for the selected items
        for item in dataStore.selectedItems! {
            if (item.usesFrequencyRange) {
                XCTAssertEqual(item.frequency, UInt(item.identifier.characters.count), "\(item.identifier)")
            }
        }
        
        guard let handStep = nextStep as? ORKFormStep, let handFormItem = handStep.formItems?.first else {
            XCTAssert(false, "\(nextStep) not of expected type" )
            return
        }
    
        // Add the hand result
        let handQuestionResult = ORKChoiceQuestionResult(identifier: handFormItem.identifier)
        handQuestionResult.choiceAnswers = ["Right hand"]
        let handResult = ORKStepResult(stepIdentifier: handStep.identifier, results: [handQuestionResult])
        taskResult.results! += [handResult]
        
        // Get moment in day
        let step2 = task.step(after: handStep, with: taskResult)
        guard let momentStep = step2 as? SBATrackedActivityFormStep , momentStep.trackingType == .activity,
            let momentFormItem = momentStep.formItems?.first  else {
                XCTAssert(false, "\(step2) not of expected type")
                return
        }
        
        // Add the moment in day result
        let questionResult = ORKChoiceQuestionResult(identifier: momentFormItem.identifier)
        questionResult.choiceAnswers = ["Another time"]
        let momentResult = ORKStepResult(stepIdentifier: momentStep.identifier, results: [questionResult])
        taskResult.results! += [momentResult]
        
        let step3 = task.step(after: momentStep, with: taskResult)
        XCTAssertNotNil(dataStore.momentInDayResult)
        XCTAssertEqual(dataStore.momentInDayResult!.count, 1)
        
        guard let timingStep = step3 as? SBATrackedActivityFormStep , timingStep.trackingType == .activity else {
            XCTAssert(false, "\(step3) not of expected type")
            return
        }
        taskResult.results! += [createTimingStepResult(timingStep, answer: "0-30 minutes")]
        
        let step4 = task.step(after: timingStep, with: taskResult)
        XCTAssertNotNil(dataStore.momentInDayResult)
        XCTAssertEqual(dataStore.momentInDayResult!.count, 2)
        
        guard let timingEachStep = step4 as? SBATrackedActivityPageStep else {
            XCTAssert(false, "\(step4) not of expected type")
            return
        }
        
        XCTAssertEqual(timingEachStep.identifier, "medicationTrackEach")
        taskResult.addResult(timingEachStep.instantiateDefaultStepResult(nil))
        
        // progress to next step to set results
        task.step(after: timingEachStep, with: taskResult)
        
        let momentInDayResults = dataStore.momentInDayResult
        XCTAssertNotNil(momentInDayResults)
        guard momentInDayResults != nil else { return }
        
        XCTAssertEqual(momentInDayResults!.count, 3)
        
        let timingResult = momentInDayResults?.last
        XCTAssertNotNil(timingResult)
        XCTAssertNotNil(timingResult?.results)
        guard let timingResults = timingResult?.results else { return }
    
        XCTAssertEqual(timingResult!.identifier, "medicationTrackEach")
        
        guard let trackQuestionResult = timingResults.last as? ORKChoiceQuestionResult,
        let choiceAnswers = trackQuestionResult.choiceAnswers as? [[String: String]]
        else {
            XCTAssert(false, "\(timingResults) not of expected type")
            return
        }
        
        XCTAssertEqual(choiceAnswers.count, 2)
        guard choiceAnswers.count == 2 else { return }
        
        XCTAssertEqual(choiceAnswers.first!["identifier"], "Levodopa")
        XCTAssertEqual(choiceAnswers.first!["answer"], "0-30 minutes ago")
        XCTAssertEqual(choiceAnswers.last!["identifier"], "Rytary")
        XCTAssertEqual(choiceAnswers.last!["answer"], "0-30 minutes ago")
    }
    
    func createTimingStepResult(_ timingStep:SBATrackedActivityFormStep, answer: String) -> ORKStepResult {
        let formItem = timingStep.formItems!.first!
        let questionResult = ORKChoiceQuestionResult(identifier: formItem.identifier)
        questionResult.choiceAnswers = [answer]
        let momentResult = ORKStepResult(stepIdentifier: timingStep.identifier, results: [questionResult])
        return momentResult
    }
    
    func checkSelectionItemsInserted(_ selectedItems: [SBATrackedDataObject], taskResult: ORKTaskResult) {
        
// TODO: FIXME!!! syoung 07/14/2016 In response to changes in RK/master, inserting a result in an
// ORKStepResult now fails. Code has been changed to mutate the taskResult in the archiving stage.
//
//        // Check that the task result includes items
//        guard let selectionStepResults = taskResult.stepResultForStepIdentifier("medicationSelection")?.results,
//            let lastResult = selectionStepResults.last
//            else {
//                XCTAssert(false, "Selection step results not found in \(taskResult)")
//                return
//        }
//        
//        XCTAssertEqual(selectionStepResults.count, 2)
//        guard let formResult = lastResult as? SBATrackedDataSelectionResult,
//            let resultItems = formResult.selectedItems else {
//            XCTAssert(false, "Selection step results do not match expected \(lastResult)")
//            return
//        }
//        
//        XCTAssertEqual(resultItems, selectedItems)
//        XCTAssertEqual(formResult.identifier, "medicationSelection")
    }
    
    // Mark: convenience methods
    
    func dataStoreForMedicationTracking() -> SBATrackedDataStore? {
        let result: AnyClass? = SBAClassTypeMap.shared.class(forClassType: "MockTrackedDataStore")
        XCTAssertNotNil(result)
        guard let classType = result as? SBATrackedDataStore.Type else {
            XCTAssert(false, "\(result) not of expected class type")
            return nil
        }
        return classType.init()
    }
    
    func dataCollectionForMedicationTracking() -> SBATrackedDataObjectCollection? {
        guard let json = self.jsonForResource("MedicationTracking") as? [AnyHashable: Any] else {
            return nil
        }
        return SBATrackedDataObjectCollection(dictionaryRepresentation: json)
    }

    func stepToSelection(_ choiceAnswers: [String]) -> (task: ORKTask?, dataStore: SBATrackedDataStore?, selectionStep: ORKStep?, taskResult: ORKTaskResult?) {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking(),
            let dataStore = self.dataStoreForMedicationTracking() else { return (nil,nil,nil, nil) }
        dataCollection.dataStore = dataStore
        
        let transformedStep = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
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
            guard let nextStep = task.step(after: step, with: taskResult) else {
                XCTAssert(false, "\(step) after not expected to be nil")
                return (nil,nil,nil, nil)
            }
            step = nextStep
        } while (step!.identifier != "medicationSelection")
        
        // modify the result to include the selected items if this is the selection step
        let answerMap = NSMutableDictionary()
        if choiceAnswers.count > 0 {
            answerMap.setValue(choiceAnswers, forKey: "choices")
            for key in choiceAnswers {
                answerMap.setValue(UInt(key.characters.count), forKey: key)
            }
        }
        else {
            answerMap.setValue("None", forKey: "choices")
        }
        let stepResult = step!.instantiateDefaultStepResult(answerMap)
        taskResult.results?.append(stepResult)
        
        return (task, dataStore, step, taskResult)
    }
}
