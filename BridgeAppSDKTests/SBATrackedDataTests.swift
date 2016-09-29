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
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
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
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
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
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
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
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        let include = SBATrackingStepIncludes.ChangedAndActivity
        let steps = dataCollection.filteredSteps(include)
        
        checkChangedAndActivitySteps(steps, expectedSkipIdentifier: "momentInDay", dataCollection: dataCollection)
    }
    
    func checkDefaultMomentInDayResults(_ dataStore: SBATrackedDataStore) -> Bool {
        
        guard let momentInDayResults = dataStore.momentInDayResults, momentInDayResults.count == 3 else {
            XCTAssert(false, "\(dataStore.momentInDayResults) nil or not expected count")
            return false
        }
        
        // Moment in day should have
        let result1 = momentInDayResults[0]
        XCTAssertEqual(result1.identifier, "momentInDay")
        XCTAssertNotNil(result1.results)
        XCTAssertEqual(result1.results!.count, 1)
        let questionResult1 = result1.results!.first! as! ORKChoiceQuestionResult
        XCTAssertEqual(questionResult1.identifier, "momentInDayFormat")
        XCTAssertEqual(questionResult1.choiceAnswers as! [String], ["No Tracked Data"])

        //
        let result2 = momentInDayResults[1]
        XCTAssertEqual(result2.identifier, "medicationActivityTiming")
        XCTAssertNotNil(result2.results)
        XCTAssertEqual(result2.results!.count, 1)
        let questionResult2 = result2.results!.first! as! ORKChoiceQuestionResult
        XCTAssertEqual(questionResult2.identifier, "medicationActivityTiming")
        XCTAssertEqual(questionResult2.choiceAnswers as! [String], ["No Tracked Data"])
        
        let result3 = momentInDayResults[2]
        XCTAssertEqual(result3.identifier, "medicationTrackEach")
        XCTAssertNotNil(result3.results)
        XCTAssertEqual(result3.results!.count, 1)
        let questionResult3 = result3.results!.first! as! ORKChoiceQuestionResult
        XCTAssertEqual(questionResult3.identifier, "medicationTrackEach")
        XCTAssertEqual(questionResult3.choiceAnswers as! [String], [] as [String])
        
        return true
        
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
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        let include = SBATrackingStepIncludes.ChangedOnly
        let steps = dataCollection.filteredSteps(include)
        
        checkChangedAndActivitySteps(steps, expectedSkipIdentifier: "nextSection", dataCollection: dataCollection)
    }

    func testMedicationTrackerFromResourceFile_Steps_SurveyAndActivity() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
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
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: true)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkStandAloneSurveySteps(task.steps, dataCollection: dataCollection)
    }
    
    func testTransformToStep_EmptySet_LastSurveyToday() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        // If the selected items set is empty (but there is one) then do not show the activity steps
        dataStore.selectedItems = []
        dataStore.commitChanges()
        
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
        
        // The moment in day results should have default values
        XCTAssert(checkDefaultMomentInDayResults(dataStore))

        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        // Task should be empty
        XCTAssertEqual(task.steps.count, 0)
    }
    
    func testTransformToStep_InjectionOnlySet_LastSurveyToday() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        // If the selected items set does not include any that are tracked then should
        // return the empty set (for a date in the near past)
        dataStore.selectedItems = dataCollection.items.filter({ !$0.usesFrequencyRange })
        dataStore.commitChanges()
        
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
        
        // The moment in day results should have default values
        XCTAssert(checkDefaultMomentInDayResults(dataStore))
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        // Task should be empty
        XCTAssertEqual(task.steps.count, 0)
    }
    
    func testTransformToStep_ActivityOnly() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        // If the activity steps includes a tracked item, then should include the activty 
        // steps, but do not need to include any of the others
        dataStore.selectedItems = dataCollection.items.filter({ $0.identifier == "Levodopa" })
        dataStore.commitChanges()
        dataStore.lastTrackingSurveyDate = Date()
        
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkActivityOnlySteps(task.steps, dataCollection: dataCollection)
    }
    
    func testTransformToStep_ChangedAndActivity_CurrentlyHasTracked() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        // If the activity steps includes a tracked item and the last survey was more than
        // 30 days ago then should ask about changes
        dataStore.selectedItems = dataCollection.items.filter({ $0.identifier == "Levodopa" })
        dataStore.commitChanges()
        dataStore.lastTrackingSurveyDate = Date(timeIntervalSinceNow: -40*24*60*60)
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
        
        // The moment in day results should have steps for creating default results
        XCTAssertNil(dataStore.momentInDayResults)
        XCTAssertNotNil(dataStore.momentInDaySteps)

        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkChangedAndActivitySteps(task.steps, expectedSkipIdentifier: "momentInDay", dataCollection: dataCollection)
    }
    
    func testTransformToStep_ChangedAndActivity_NoMedsCurrentlyTracked() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        // If the activity steps includes a tracked item and the last survey was more than
        // 30 days ago then should ask about changes
        dataStore.selectedItems = []
        dataStore.commitChanges()
        dataStore.lastTrackingSurveyDate = Date(timeIntervalSinceNow: -40*24*60*60)
        
        let step = dataCollection.transformToStep(with: SBASurveyFactory(), isLastStep: false)
        
        // The moment in day results should have default values
        XCTAssert(checkDefaultMomentInDayResults(dataStore))
        
        guard let taskStep = step as? SBASubtaskStep, let task = taskStep.subtask as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(step) not of expected class type")
            return
        }
        
        checkChangedAndActivitySteps(task.steps, expectedSkipIdentifier: "nextSection", dataCollection: dataCollection)
    }
    
    // Mark: Navigation tests
    
    func testNavigation_NoMedsSelected() {
        let (retTask, retDataStore, step, retTaskResult) = stepToActivity(["None"])
        guard let task = retTask,
            let dataStore = retDataStore,
            let taskResult = retTaskResult,
            let selectedItems = dataStore.selectedItems
            else {
                XCTAssert(false, "preconditions not met")
                return
        }

        // Check that there are no selected items
        XCTAssertEqual(selectedItems.count, 0)
        
        // And the default moment in day results are given
        XCTAssert(checkDefaultMomentInDayResults(dataStore))
        
        // Tracked steps should not be shown
        let nextStep = task.step(after: step, with: taskResult)
        XCTAssertNil(nextStep)
    }
    
    func testNavigation_WithMedsSelected() {
        
        // Check shared functionality
        let (retTask, retDataStore, step, retTaskResult) = stepToActivity(["Levodopa", "Carbidopa", "Rytary", "Apokyn"])
        guard let task = retTask,
            let dataStore = retDataStore,
            let taskResult = retTaskResult,
            let selectedItems = dataStore.selectedItems
            else {
                XCTAssert(false, "preconditions not met")
                return
        }
        
        // check that the selected items is set in the data store
        XCTAssertEqual(selectedItems.count, 4)
        
        // get the next step
        let step1 = task.step(after: step, with: taskResult)
        XCTAssertNotNil(step1)

        // Get moment in day
        guard let momentStep = step1 as? SBATrackedActivityFormStep , momentStep.trackingType == .activity,
            let momentFormItem = momentStep.formItems?.first else {
                XCTAssert(false, "\(step1) not of expected type")
                return
        }
        
        XCTAssertEqual(momentStep.identifier, "momentInDay")
        XCTAssertEqual(momentFormItem.identifier, "momentInDayFormat")
        XCTAssertEqual(momentStep.formItems!.count, 1)
        
        // Add the moment in day result
        let momentResult = momentStep.instantiateDefaultStepResult([momentFormItem.identifier : "Another time"])
        taskResult.results?.append(momentResult)
        
        // Get next step
        let step2 = task.step(after: step1, with: taskResult)
        XCTAssertNotNil(step2)
        
        guard let timingStep = step2 as? SBATrackedActivityFormStep, timingStep.trackingType == .activity,
            let timingFormItem = timingStep.formItems?.first else {
            XCTAssert(false, "\(step2) not of expected type")
            return
        }
        
        XCTAssertEqual(timingStep.identifier, "medicationActivityTiming")
        XCTAssertEqual(timingFormItem.identifier, "medicationActivityTiming")
        XCTAssertEqual(timingStep.formItems!.count, 1)
        
        // Add timing result
        let timingResult = timingStep.instantiateDefaultStepResult([timingFormItem.identifier : "30-60 minutes ago"])
        taskResult.results?.append(timingResult)
        
        // Get track each step
        let step3 = task.step(after: step2, with: taskResult)
        XCTAssertNotNil(step3)

        guard let timingEachStep = step3 as? SBATrackedActivityPageStep else {
            XCTAssert(false, "\(step3) not of expected type")
            return
        }

        XCTAssertEqual(timingEachStep.identifier, "medicationTrackEach")
        
        // Add timing each result
        let timingEachResult = timingEachStep.instantiateDefaultStepResult(nil)
        taskResult.results?.append(timingEachResult)
        
        // Check that this is the last step
        let step4 = task.step(after: step3, with: taskResult)
        XCTAssertNil(step4)

        guard let momentInDayResults = dataStore.momentInDayResults else {
            XCTAssert(false, "Data store momentInDayResults are nil")
            return
        }
        guard momentInDayResults.count == 3 else {
            XCTAssert(false, "results count does not match expected")
            return
        }
        
        XCTAssertEqual(momentInDayResults[0], momentResult)
        XCTAssertEqual(momentInDayResults[1], timingResult)
        XCTAssertEqual(momentInDayResults[2], timingEachResult)
    }
    
    // Mark: Commit/reset
    
    func testCommitChanges_NoMedication() {
        let dataStore = self.dataStoreForMedicationTracking()
        
        dataStore.selectedItems = []
        
        // --- method under test
        dataStore.commitChanges()
        
        // Changes have been saved and does not have changes
        XCTAssertFalse(dataStore.hasChanges);
        XCTAssertNotNil(dataStore.storedDefaults.object(forKey: "selectedItems"))
        XCTAssertNotNil(dataStore.lastTrackingSurveyDate)
        XCTAssertEqualWithAccuracy(dataStore.lastTrackingSurveyDate?.timeIntervalSinceNow ?? 99.0, 0.0, accuracy: 2)
    }
    
    func testCommitChanges_OtherTrackedResult() {
        let dataStore = self.dataStoreForMedicationTracking()
        
        let result = ORKBooleanQuestionResult(identifier: "trackedQuestion")
        result.booleanAnswer = true
        let stepResult = ORKStepResult(stepIdentifier: "trackedQuestion", results: [result])
        dataStore.updateTrackedData(for: stepResult)
        
        // --- method under test
        dataStore.commitChanges()
        
        // Changes have been saved and does not have changes
        XCTAssertFalse(dataStore.hasChanges);
        XCTAssertNotNil(dataStore.storedDefaults.object(forKey: "results"))
        XCTAssertNotNil(dataStore.lastTrackingSurveyDate)
        XCTAssertEqualWithAccuracy(dataStore.lastTrackingSurveyDate?.timeIntervalSinceNow ?? 99.0, 0.0, accuracy: 2)
    }
    
    func testCommitChanges_WithTrackedMedicationAndMomentInDayResult() {
        let dataStore = self.dataStoreForMedicationTracking()

        let med = SBAMedication(dictionaryRepresentation: ["name": "Levodopa", "tracking": true])
        dataStore.selectedItems = [med]
        let momentInDayResults = createMomentInDayResults()
        dataStore.momentInDayResults = momentInDayResults
        
        // --- method under test
        dataStore.commitChanges()
        
        // Changes have been saved and does not have changes
        XCTAssertFalse(dataStore.hasChanges)
        XCTAssertNotNil(dataStore.storedDefaults.object(forKey: "selectedItems"))
        XCTAssertEqual(dataStore.selectedItems?.count ?? 0, 1)
        XCTAssertEqual(dataStore.selectedItems?.first, med)
        XCTAssertNotNil(dataStore.momentInDayResults);
        XCTAssertEqual(dataStore.momentInDayResults!, momentInDayResults)
    }
    
    func testReset() {
        let dataStore = self.dataStoreForMedicationTracking()
        
        let med = SBAMedication(dictionaryRepresentation: ["name": "Levodopa", "tracking": true])
        dataStore.selectedItems = [med]
        dataStore.commitChanges()
        
        let changedMed = SBAMedication(dictionaryRepresentation: ["name": "Rytary", "tracking": true])
        dataStore.selectedItems = [changedMed]
        
        let momentInDayResults = createMomentInDayResults()
        dataStore.momentInDayResults = momentInDayResults
        
        // --- method under test
        dataStore.reset()
        
        XCTAssertFalse(dataStore.hasChanges)
        XCTAssertEqual(dataStore.selectedItems!, [med])
        XCTAssertNil(dataStore.momentInDayResults)
    }
    
    // Mark: shouldIncludeMomentInDayQuestions
    
    func testShouldIncludeMomentInDayQuestions_LastCompletionNil() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        dataCollection.alwaysIncludeActivitySteps = false
        dataStore.selectedItems = Array(dataCollection.items[2...3])
        dataStore.momentInDayResults = createMomentInDayResults()
        dataStore.commitChanges()
        dataStore.mockLastCompletionDate = nil
        
        // Check assumptions
        XCTAssertNotEqual(dataStore.trackedItems?.count ?? 99, 0)
        XCTAssertFalse(dataStore.hasChanges)
        XCTAssertNotNil(dataStore.momentInDayResults)
        XCTAssertNil(dataStore.lastCompletionDate)
        
        // For a nil date, the collection should show the moment in day questions
        XCTAssertTrue(dataCollection.shouldIncludeMomentInDayQuestions())
    }
    
    func testShouldIncludeMomentInDayQuestions_StashNil() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        dataCollection.alwaysIncludeActivitySteps = false
        dataStore.selectedItems = Array(dataCollection.items[2...3])
        dataStore.commitChanges()
        dataStore.mockLastCompletionDate = Date()
        
        // Check assumptions
        XCTAssertNotEqual(dataStore.trackedItems?.count ?? 99, 0)
        XCTAssertFalse(dataStore.hasChanges)
        XCTAssertNil(dataStore.momentInDayResults)
        XCTAssertNotNil(dataStore.lastCompletionDate)
        
        // For a nil moment in day question set should include
        XCTAssertTrue(dataCollection.shouldIncludeMomentInDayQuestions())
    }

    func testShouldIncludeMomentInDayQuestions_TakesMedication() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        dataCollection.alwaysIncludeActivitySteps = false
        dataStore.selectedItems = Array(dataCollection.items[2...3])
        dataStore.momentInDayResults = createMomentInDayResults()
        dataStore.commitChanges()
        
        // Check assumptions
        XCTAssertNotEqual(dataStore.trackedItems?.count ?? 99, 0)
        XCTAssertFalse(dataStore.hasChanges)
        XCTAssertNotNil(dataStore.momentInDayResults)
        
        // If it has been more than 30 minutes, should ask the question again
        dataStore.mockLastCompletionDate = Date(timeIntervalSinceNow: -30 * 60)
        XCTAssertTrue(dataCollection.shouldIncludeMomentInDayQuestions())
        
        // For a recent time, should NOT include step
        dataStore.mockLastCompletionDate = Date(timeIntervalSinceNow: -2 * 60)
        XCTAssertFalse(dataCollection.shouldIncludeMomentInDayQuestions())
    
        // If should always include the timing questions then should be true
        dataCollection.alwaysIncludeActivitySteps = true
        XCTAssertTrue(dataCollection.shouldIncludeMomentInDayQuestions())
    }
    
    func testShouldIncludeMomentInDayQuestions_NoMedication() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        dataCollection.alwaysIncludeActivitySteps = true
        dataStore.selectedItems = []
        dataStore.momentInDayResults = createMomentInDayResults()
        dataStore.commitChanges()
        dataStore.mockLastCompletionDate = Date(timeIntervalSinceNow: -2 * 60)
        
        // Check assumptions
        XCTAssertEqual(dataStore.trackedItems?.count ?? 99, 0)
        XCTAssertFalse(dataStore.hasChanges)
        XCTAssertNotNil(dataStore.momentInDayResults)
        XCTAssertNotNil(dataStore.lastCompletionDate)
        
        // If no meds, should not be asked the moment in day question
        XCTAssertFalse(dataCollection.shouldIncludeMomentInDayQuestions())
    }
    
    // Mark: shouldIncludeChangedQuestion
    
    func testShouldIncludeChangedQuestion_NO() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        dataCollection.alwaysIncludeActivitySteps = true
        dataStore.selectedItems = []
        dataStore.commitChanges()
        
        // If it has been one day, do not include
        dataStore.lastTrackingSurveyDate = Date(timeIntervalSinceNow: -24 * 60 * 60)
        XCTAssertFalse(dataCollection.shouldIncludeChangedStep())
    }
    
    func testShouldIncludeChangedQuestion_YES() {
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        dataCollection.alwaysIncludeActivitySteps = true
        dataStore.selectedItems = []
        dataStore.commitChanges()
        
        // If it has been over a month, do not include
        dataStore.lastTrackingSurveyDate = Date(timeIntervalSinceNow: -32 * 24 * 60 * 60)

        XCTAssertTrue(dataCollection.shouldIncludeChangedStep())
    }
    
    // Mark: - stepResultForStep:
    
    func testStepResultForStep_SelectedItemsStep() {
        
        // Check shared functionality
        let (retTask, retDataStore, _, retTaskResult) = stepToActivity(["Levodopa", "Carbidopa", "Rytary", "Apokyn"])
        guard let dataStore = retDataStore,
            let selectionStep = retTask?.step?(withIdentifier: "medicationSelection"),
            let selectionResult = retTaskResult?.stepResult(forStepIdentifier: "medicationSelection")
            else {
                XCTAssert(false, "preconditions not met")
                return
        }
        
        // commit the changes
        dataStore.commitChanges()
        
        // --- Rebuild the result from the data store
        guard let storedResult = dataStore.stepResult(for: selectionStep) else {
            XCTAssert(false, "restored result is nil")
            return
        }
        
        // restored result should have equal answers and identifiers but not be identical objects
        XCTAssertFalse(storedResult === selectionResult)

        // Identifier should match
        XCTAssertEqual(storedResult.identifier, selectionResult.identifier)
        
        // And start/end date should match
        XCTAssertEqual(storedResult.startDate, dataStore.lastTrackingSurveyDate)
        XCTAssertEqual(storedResult.endDate, dataStore.lastTrackingSurveyDate)
        
        guard let storedResults = storedResult.results, let selectionResults = selectionResult.results else {
            XCTAssert(false, "results are nil or counts do not match")
            return
        }
        
        XCTAssertEqual(storedResults.count, selectionResults.count)
        
        for expectedResult in selectionResults {
            let result = storedResult.result(forIdentifier: expectedResult.identifier) as! ORKQuestionResult
            XCTAssertNotNil(result, "\(expectedResult.identifier)")
            XCTAssertEqual(result.answer as! NSObject, (expectedResult as! ORKQuestionResult).answer as! NSObject, "\(expectedResult.identifier)")
        }
    }
    
    func testStepResultForStep_OtherTrackedStep_BooleanForm() {
        
        let dataStore = self.dataStoreForMedicationTracking()
        
        // Create the result and commit the changes
        let questionResult = ORKBooleanQuestionResult(identifier: "trackedQuestion")
        questionResult.booleanAnswer = true
        let stepResult = ORKStepResult(stepIdentifier: "trackedStep", results: [questionResult])
        dataStore.updateTrackedData(for: stepResult)
        dataStore.commitChanges()
        
        // Create the step
        let step = ORKFormStep(identifier: "trackedStep")
        step.formItems = [ORKFormItem(identifier: "trackedQuestion", text: nil, answerFormat: ORKAnswerFormat.booleanAnswerFormat())]
        
        // Get the restored result
        let storedResult = dataStore.stepResult(for: step)
        
        XCTAssertNotNil(storedResult)
        
        guard let booleanResult = storedResult?.results?.first as? ORKBooleanQuestionResult else {
            XCTAssert(false, "\(storedResult) results are nil or not expected type")
            return
        }
     
        XCTAssertEqual(storedResult!.identifier, "trackedStep")
        XCTAssertEqual(booleanResult.identifier, "trackedQuestion")
        XCTAssertEqual(booleanResult.booleanAnswer!, questionResult.booleanAnswer!)
    }
    
    func testStepResultForStep_OtherTrackedStep_BooleanQuestion() {
        
        let dataStore = self.dataStoreForMedicationTracking()
        
        // Create the result and commit the changes
        let questionResult = ORKBooleanQuestionResult(identifier: "trackedQuestion")
        questionResult.booleanAnswer = true
        let stepResult = ORKStepResult(stepIdentifier: "trackedQuestion", results: [questionResult])
        dataStore.updateTrackedData(for: stepResult)
        dataStore.commitChanges()
        
        // Create the step
        let step = ORKQuestionStep(identifier: "trackedQuestion", title: nil, answer: ORKAnswerFormat.booleanAnswerFormat())
        
        // Get the restored result
        let storedResult = dataStore.stepResult(for: step)
        
        XCTAssertNotNil(storedResult)
        
        guard let booleanResult = storedResult?.results?.first as? ORKBooleanQuestionResult else {
            XCTAssert(false, "\(storedResult) results are nil or not expected type")
            return
        }
        
        XCTAssertEqual(storedResult!.identifier, "trackedQuestion")
        XCTAssertEqual(booleanResult.identifier, "trackedQuestion")
        XCTAssertEqual(booleanResult.booleanAnswer!, questionResult.booleanAnswer!)
    }
    
    // MARK: ORKTaskResultSource
    
    func testStoredTaskResultSource() {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        let dataStore = self.dataStoreForMedicationTracking()
        dataCollection.dataStore = dataStore
        
        // Setup the data store to have selected items and need to include the changed step
        dataStore.selectedItems = dataCollection.items.filter({ $0.identifier == "Levodopa" })
        dataStore.commitChanges()
        dataStore.lastTrackingSurveyDate = Date(timeIntervalSinceNow: -40*24*60*60)
        
        // Create a task
        let factory = SBASurveyFactory()
        let introStep = ORKInstructionStep(identifier: "intro")
        let surveyStep = dataCollection.transformToStep(with: factory, isLastStep: false)!
        let questionStep = ORKQuestionStep(identifier: "booleanQuestion", title: nil, answer: ORKAnswerFormat.booleanAnswerFormat())
        let conclusionStep = ORKCompletionStep(identifier: "conclusion")
        let task = SBANavigableOrderedTask(identifier: "task", steps: [introStep, surveyStep, questionStep, conclusionStep])
        
        // check assumptions
        let selectionStepIdentifier = "Medication Tracker.medicationSelection"
        let selectionStep = task.step(withIdentifier: selectionStepIdentifier)
        XCTAssertNotNil(selectionStep)
        
        // Check the initial stored result
        let result = task.stepResult(forStepIdentifier: selectionStepIdentifier)
        XCTAssertNotNil(result)
    }
    
    // MARK: convenience methods
    
    func dataStoreForMedicationTracking() -> MockTrackedDataStore {
        return MockTrackedDataStore()
    }
    
    func dataCollectionForMedicationTracking() -> SBATrackedDataObjectCollection? {
        guard let json = self.jsonForResource("MedicationTracking") as? [AnyHashable: Any] else {
            return nil
        }
        return SBATrackedDataObjectCollection(dictionaryRepresentation: json)
    }
    
    func createMomentInDayResults() -> [ORKStepResult] {
        
        let momResult = ORKChoiceQuestionResult(identifier: NSUUID().uuidString)
        momResult.startDate = Date(timeIntervalSinceNow: -2*60)
        momResult.endDate = momResult.startDate.addingTimeInterval(30)
        momResult.questionType = .singleChoice
        momResult.choiceAnswers = ["Another Time"]
        let stepResult = ORKStepResult(stepIdentifier: "momentInDay", results: [momResult])
        return [stepResult]
    }

    func stepToActivity(_ choiceAnswers: [String]) -> (task: ORKTask?, dataStore: SBATrackedDataStore?, selectionStep: ORKStep?, taskResult: ORKTaskResult?) {
        
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return (nil,nil,nil,nil) }
        let dataStore = self.dataStoreForMedicationTracking()
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
                return (nil, nil, nil, nil)
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
        
        // get the next step
        step = task.step(after: step, with: taskResult)
        XCTAssertNotNil(step)
        XCTAssertNotNil(dataStore.selectedItems)
        
        // check that the frequency values are set for the selected items
        for item in dataStore.selectedItems! {
            if (item.usesFrequencyRange) {
                XCTAssertEqual(item.frequency, UInt(item.identifier.characters.count), "\(item.identifier)")
            }
        }
        
        guard let handStep = step as? ORKFormStep, let handFormItem = handStep.formItems?.first else {
            XCTAssert(false, "\(step) not of expected type" )
            return  (nil, nil, nil, nil)
        }
        
        // Add the hand result
        let handQuestionResult = ORKChoiceQuestionResult(identifier: handFormItem.identifier)
        handQuestionResult.choiceAnswers = ["Right hand"]
        let handResult = ORKStepResult(stepIdentifier: handStep.identifier, results: [handQuestionResult])
        taskResult.results?.append(handResult)
        
        return (task, dataStore, step, taskResult)
    }
}
