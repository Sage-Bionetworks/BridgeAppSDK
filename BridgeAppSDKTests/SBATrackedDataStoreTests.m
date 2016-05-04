//
//  SBATrackerDataStoreTests.m
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

#import <XCTest/XCTest.h>
#import "MockTrackedDataStore.h"
#import <ResearchKit/ResearchKit.h>
@import BridgeAppSDK;


NSString  *const kSelectedItemsKey                              = @"selectedItems";
NSString  *const kSkippedSelectionSurveyQuestionKey             = @"skippedSelectionSurveyQuestion";
NSString  *const kMomentInDayResultKey                          = @"momentInDayResult";

NSString  *const kMomentInDayStepIdentifier                     = @"momentInDay";
NSString  *const kMomentInDayFormIdentifier                     = @"momentInDayFormat";
NSString  *const kActivityTimingStepIdentifier                  = @"medicationActivityTiming";

@interface SBATrackedDataStoreTests : XCTestCase

@end

@implementation SBATrackedDataStoreTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSetTrackedMedications_Skipped
{
    SBATrackedDataStore *dataStore = [self createDataStore];
    
    // Setting to nil if the question was skipped
    dataStore.skippedSelectionSurveyQuestion = YES;
    
    // After setting a nil value to the tracked medication, this indicates that
    // the question has been skipped
    XCTAssertTrue(dataStore.hasChanges);
    XCTAssertTrue(dataStore.skippedSelectionSurveyQuestion);
    XCTAssertNil(dataStore.trackedItems);
    
    // Nothing saved yet to defaults
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSkippedSelectionSurveyQuestionKey]);
    
    // The momentInDay should now have a default result set
    NSArray <ORKStepResult *> *stepResults = dataStore.momentInDayResult;
    
    ORKStepResult *momentInDayStepResult = stepResults.firstObject;
    XCTAssertNotNil(momentInDayStepResult);
    XCTAssertEqualObjects(momentInDayStepResult.identifier, kMomentInDayStepIdentifier);
    
    ORKChoiceQuestionResult *midResult = (ORKChoiceQuestionResult *)[momentInDayStepResult.results firstObject];
    XCTAssertNotNil(midResult);
    XCTAssertEqualObjects(midResult.identifier, kMomentInDayFormIdentifier);
    XCTAssertNotNil(midResult.startDate);
    XCTAssertNotNil(midResult.endDate);
    XCTAssertEqualObjects(midResult.choiceAnswers, @[@"Skipped"]);
    XCTAssertEqual(midResult.questionType, ORKQuestionTypeSingleChoice);
    
    ORKStepResult *timingStepResult = stepResults.lastObject;
    XCTAssertNotNil(timingStepResult);
    XCTAssertEqualObjects(timingStepResult.identifier, kActivityTimingStepIdentifier);
    
    ORKChoiceQuestionResult *atResult = (ORKChoiceQuestionResult *)[timingStepResult.results firstObject];
    XCTAssertNotNil(atResult);
    XCTAssertEqualObjects(atResult.identifier, kActivityTimingStepIdentifier);
    XCTAssertNotNil(atResult.startDate);
    XCTAssertNotNil(atResult.endDate);
    XCTAssertEqualObjects(atResult.choiceAnswers, @[@"Skipped"]);
    XCTAssertEqual(atResult.questionType, ORKQuestionTypeSingleChoice);
}

- (void)testSetTrackedMedications_NoMeds
{
    SBATrackedDataStore *dataStore = [self createDataStore];
    
    // Setting to empty set if no tracked meds are taken
    [dataStore setSelectedItems:@[]];
    
    // After setting a nil value to the tracked medication, this indicates that
    // the question has been skipped
    XCTAssertTrue(dataStore.hasChanges);
    XCTAssertFalse(dataStore.skippedSelectionSurveyQuestion);
    XCTAssertNotNil(dataStore.trackedItems);
    XCTAssertEqual(dataStore.trackedItems.count, 0);
    
    // Nothing saved yet to defaults
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSelectedItemsKey]);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSkippedSelectionSurveyQuestionKey]);
    
    // The momentInDay should now have a default result set
    NSArray <ORKStepResult *> *stepResults = dataStore.momentInDayResult;
    
    ORKStepResult *momentInDayStepResult = stepResults.firstObject;
    XCTAssertNotNil(momentInDayStepResult);
    XCTAssertEqualObjects(momentInDayStepResult.identifier, kMomentInDayStepIdentifier);
    
    ORKChoiceQuestionResult *midResult = (ORKChoiceQuestionResult *)[momentInDayStepResult.results firstObject];
    XCTAssertNotNil(midResult);
    XCTAssertEqualObjects(midResult.identifier, kMomentInDayFormIdentifier);
    XCTAssertNotNil(midResult.startDate);
    XCTAssertNotNil(midResult.endDate);
    XCTAssertEqualObjects(midResult.choiceAnswers, @[@"No Tracked Data"]);
    XCTAssertEqual(midResult.questionType, ORKQuestionTypeSingleChoice);
    
    ORKStepResult *timingStepResult = stepResults.lastObject;
    XCTAssertNotNil(timingStepResult);
    XCTAssertEqualObjects(timingStepResult.identifier, kActivityTimingStepIdentifier);
    
    ORKChoiceQuestionResult *atResult = (ORKChoiceQuestionResult *)[timingStepResult.results firstObject];
    XCTAssertNotNil(atResult);
    XCTAssertEqualObjects(atResult.identifier, kActivityTimingStepIdentifier);
    XCTAssertNotNil(atResult.startDate);
    XCTAssertNotNil(atResult.endDate);
    XCTAssertEqualObjects(atResult.choiceAnswers, @[@"No Tracked Data"]);
    XCTAssertEqual(atResult.questionType, ORKQuestionTypeSingleChoice);
}

- (void)testSetMomentInDayResult
{
    SBATrackedDataStore *dataStore = [self createDataStore];
    NSArray <ORKStepResult *> *stepResult = [self createMomentInDayStepResult];
    
    [dataStore setMomentInDayResult:[stepResult copy]];
    
    XCTAssertEqualObjects(dataStore.momentInDayResult, stepResult);
    XCTAssertTrue([dataStore hasChanges]);
}

- (void)testCommitChanges_NoMedication
{
    SBATrackedDataStore *dataStore = [self createDataStore];
    
    // Set tracked medication and commit
    [dataStore setSelectedItems:@[]];
    [dataStore commitChanges];
    
    // Changes have been saved and does not have changes
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil([dataStore.storedDefaults objectForKey:kSelectedItemsKey]);
    XCTAssertNotNil([dataStore.storedDefaults objectForKey:kSkippedSelectionSurveyQuestionKey]);
    
    XCTAssertEqualWithAccuracy(dataStore.lastTrackingSurveyDate.timeIntervalSinceNow, 0.0, 2);
}

- (void)testCommitChanges_WithTrackedMedicationAndMomentInDayResult
{
    SBATrackedDataStore *dataStore = [self createDataStore];
    
    // Set the selected medications and moment in day
    SBAMedication *med = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa",
                                                                                   @"tracking" : @(YES)}];
    dataStore.selectedItems = @[med];
    NSArray <ORKStepResult *> *momentInDayResult = [self createMomentInDayStepResult];
    dataStore.momentInDayResult = momentInDayResult;
    
    // commit the changes
    [dataStore commitChanges];
    
    // Changes have been saved and does not have changes
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil([dataStore.storedDefaults objectForKey:kSelectedItemsKey]);
    XCTAssertNotNil([dataStore.storedDefaults objectForKey:kSkippedSelectionSurveyQuestionKey]);
    XCTAssertEqual(dataStore.selectedItems.count, 1);
    XCTAssertEqualObjects(dataStore.selectedItems.firstObject, med);
    XCTAssertNotNil(dataStore.momentInDayResult);
    XCTAssertEqualObjects(dataStore.momentInDayResult, momentInDayResult);
    
    XCTAssertEqualWithAccuracy(dataStore.lastTrackingSurveyDate.timeIntervalSinceNow, 0.0, 2);
    XCTAssertEqualWithAccuracy(dataStore.lastCompletionDate.timeIntervalSinceNow, 0.0, 2);
}

- (void)testReset
{
    SBATrackedDataStore *dataStore = [self createDataStore];
    
    // Set tracked medication and reset
    [dataStore setSelectedItems:@[]];
    [dataStore reset];
    
    // Changes have been cleared
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSelectedItemsKey]);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSkippedSelectionSurveyQuestionKey]);
}

- (void)testShouldIncludeMomentInDayStep_LastCompletionNil
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    dataStore.selectedItems = @[[[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa",
                                                                                          @"tracking" : @(YES)}]];
    dataStore.momentInDayResult = [self createMomentInDayStepResult];
    [dataStore commitChanges];
    dataStore.mockLastCompletionDate = nil;
    
    // Check assumptions
    XCTAssertNotEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil(dataStore.momentInDayResult);
    XCTAssertNil(dataStore.lastCompletionDate);
    
    // For a nil date, the moment in day step should be included
    XCTAssertTrue([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_StashNil
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    dataStore.selectedItems = @[[[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa",
                                                                                          @"tracking" : @(YES)}]];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertNotEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNil(dataStore.momentInDayResult);
    
    // Even if the time is very recent, should include moment in day step
    // if the stashed result is nil.
    dataStore.mockLastCompletionDate = [NSDate date];
    XCTAssertTrue([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_TakesMedication
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    dataStore.selectedItems = @[[[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa",
                                                                                          @"tracking" : @(YES)}]];
    dataStore.momentInDayResult = [self createMomentInDayStepResult];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertNotEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil(dataStore.momentInDayResult);
    
    // For a recent time, should NOT include step
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
    
    // If it has been more than 30 minutes, should ask the question again
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-30*60];
    XCTAssertTrue([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_NoMedication
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    dataStore.selectedItems = @[[[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Carbidopa"}]];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    
    // If no meds, should not be asked the moment in day question
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-30*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_SkipMedsQuestion
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    dataStore.skippedSelectionSurveyQuestion = YES;
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    
    // If the medication survey question was skipped, then skip the moment in day step
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-30*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMedicationChangedQuestion_NO
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    [dataStore setSelectedItems:@[]];
    [dataStore commitChanges];
    dataStore.lastTrackingSurveyDate = [NSDate dateWithTimeIntervalSinceNow:-24*60*60];
    
    XCTAssertFalse(dataStore.shouldIncludeChangedQuestion);
}

- (void)testShouldIncludeMedicationChangedQuestion_YES
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    [dataStore setSelectedItems:@[]];
    [dataStore commitChanges];
    dataStore.lastTrackingSurveyDate = [NSDate dateWithTimeIntervalSinceNow:-32*24*60*60];
    
    XCTAssertTrue(dataStore.shouldIncludeChangedQuestion);
}

- (void)testUpdateSelectedItems
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    
    // Create task result
    ORKStepResult *introStepResult = [[ORKStepResult alloc] initWithIdentifier:@"instruction"];
    
    NSString *selectionIdentifier = @"selection";
    ORKChoiceQuestionResult *questionResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:selectionIdentifier];
    questionResult.choiceAnswers = @[@"Carbidopa"];
    ORKStepResult *selectionStepResult = [[ORKStepResult alloc] initWithStepIdentifier:selectionIdentifier results:@[questionResult]];

    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:@"test"];
    result.results = @[introStepResult, selectionStepResult];
    
    // Create list of possible answers
    
    SBAMedication *levodopa = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa"}];
    SBAMedication *carbidopa = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Carbidopa"}];
    SBAMedication *rytary = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Rytary"}];
    NSArray *items = @[levodopa, carbidopa, rytary];
    
    // -- call method under test
    [dataStore updateSelectedItems:items
                    stepIdentifier:selectionIdentifier
                            result:result];
    
    SBAMedication *item = (SBAMedication *)dataStore.selectedItems.firstObject;
    XCTAssertEqual(dataStore.selectedItems.count, 1);
    XCTAssertEqual(item.identifier, @"Carbidopa");
    XCTAssertEqual(item, carbidopa);
}

- (void)testUpdateSelectedItemsCalledWithNoResult
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:@"test"];
    
    SBAMedication *levodopa = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa"}];
    SBAMedication *carbidopa = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Carbidopa"}];
    SBAMedication *rytary = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Rytary"}];
    NSArray *items = @[levodopa, carbidopa, rytary];
    
    // -- call method under test
    [dataStore updateSelectedItems:items
                    stepIdentifier:@"selection"
                            result:result];
    
    XCTAssertEqual(dataStore.selectedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
}

- (void)testUpdateFrequencyItems
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    
    SBAMedication *levodopa = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa"}];
    SBAMedication *carbidopa = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Carbidopa"}];
    SBAMedication *apokyn = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Apokyn", @"injection" : @(YES)}];
    dataStore.selectedItems = @[levodopa, carbidopa, apokyn];
    
    // Create task result
    ORKStepResult *introStepResult = [[ORKStepResult alloc] initWithIdentifier:@"instruction"];
    ORKChoiceQuestionResult *questionResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"selection"];
    questionResult.choiceAnswers = @[@"Levodopa", @"Carbidopa", @"Apokyn"];
    ORKStepResult *selectionStepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"selection" results:@[questionResult]];
    
    
    // Add frequency question result
    ORKScaleQuestionResult *levodopaResult = [[ORKScaleQuestionResult alloc] initWithIdentifier:@"Levodopa"];
    levodopaResult.scaleAnswer = @(4);
    ORKScaleQuestionResult *symmetrelResult = [[ORKScaleQuestionResult alloc] initWithIdentifier:@"Carbidopa"];
    symmetrelResult.scaleAnswer = @(7);
    ORKStepResult *frequencyStepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"frequency"
                                                                               results:@[levodopaResult, symmetrelResult]];
    
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:@"test"];
    result.results = @[introStepResult, selectionStepResult, frequencyStepResult];
    
    // -- call method under test
    [dataStore updateFrequencyForStepIdentifier:@"frequency"
                                         result:result];
    
    NSDictionary *expectedItems = @{ @"Levodopa"    : @(4),
                                     @"Carbidopa"   : @(7),
                                     @"Apokyn"      : @(0)};
    
    NSArray *selectedItems = dataStore.selectedItems;
    XCTAssertEqual(selectedItems.count, 3);
    for (SBAMedication *med in selectedItems) {
        XCTAssertEqual(med.frequency, [expectedItems[med.identifier] unsignedIntegerValue], @"%@", med.identifier);
    }
    
}

- (void)testUpdateFrequencyItemsCalledWithNoResult
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:@"test"];
    
    // -- call method under test
    [dataStore updateFrequencyForStepIdentifier:@"frequency"
                                         result:result];
    
    XCTAssertFalse(dataStore.hasChanges);
}

- (void)testUpdateMomentInDayForStepIdentifier_NoInitialResults {

    MockTrackedDataStore *dataStore = [self createDataStore];
    
    ORKStepResult *introStepResult = [[ORKStepResult alloc] initWithIdentifier:@"instruction"];
    ORKStepResult *stepResult = [[self createMomentInDayStepResult] firstObject];
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:@"test"];
    result.results = @[introStepResult, stepResult];
    
    [dataStore updateMomentInDayForStepIdentifier:@"momentInDay"
                                           result:result];
    
    NSArray *momentInDayResults = dataStore.momentInDayResult;
    ORKStepResult *first = momentInDayResults.firstObject;
    XCTAssertEqual(first, stepResult);
}

- (void)testUpdateMomentInDayForStepIdentifier_ChangeResults {
    
    MockTrackedDataStore *dataStore = [self createDataStore];
    dataStore.momentInDayResult = [self createMomentInDayStepResult];
    [dataStore commitChanges];
    
    ORKStepResult *introStepResult = [[ORKStepResult alloc] initWithIdentifier:@"instruction"];
    ORKStepResult *stepResult = [[self createMomentInDayStepResultWithAnswers:@[@"After Parkinson medication", @"0-30 minutes"]] firstObject];
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:@"test"];
    result.results = @[introStepResult, stepResult];
    
    [dataStore updateMomentInDayForStepIdentifier:@"momentInDay"
                                           result:result];
    
    NSArray *momentInDayResults = dataStore.momentInDayResult;
    ORKStepResult *stored = nil;
    for (ORKStepResult *sr in momentInDayResults) {
        if ([sr.identifier isEqualToString:@"momentInDay"]) {
            stored = sr; break;
        }
    }
    XCTAssertEqual(stored, stepResult);
}

- (void)testUpdateMomentInDayCalledWithNoResult
{
    MockTrackedDataStore *dataStore = [self createDataStore];
    
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:@"test"];
    
    // -- call method under test
    [dataStore updateMomentInDayForStepIdentifier:@"momentInDay"
                                           result:result];
    
    XCTAssertFalse(dataStore.hasChanges);
}

#pragma mark - helper methods

- (MockTrackedDataStore *)createDataStore
{
    MockTrackedDataStore *dataStore = [MockTrackedDataStore new];
    dataStore.momentInDayResultDefaultIdMap  =
        @[@[@"momentInDay", @"momentInDayFormat"],
          @[@"medicationActivityTiming", @"medicationActivityTiming"]];
    
    // Check assumptions
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertFalse(dataStore.skippedSelectionSurveyQuestion);
    XCTAssertNil(dataStore.trackedItems);
    XCTAssertNil(dataStore.momentInDayResult);
    XCTAssertNotNil(dataStore.momentInDayResultDefaultIdMap);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSelectedItemsKey]);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSkippedSelectionSurveyQuestionKey]);
    
    return dataStore;
}

- (NSArray <ORKStepResult *> *)createMomentInDayStepResult
{
    return [self createMomentInDayStepResultWithAnswers:@[@"Immediately before Parkinson medication", @"0-30 minutes"]];
}

- (NSArray <ORKStepResult *> *)createMomentInDayStepResultWithAnswers:(NSArray*)answers
{
    ORKChoiceQuestionResult *inputA = [[ORKChoiceQuestionResult alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]];
    inputA.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    inputA.endDate = [inputA.startDate dateByAddingTimeInterval:30];
    inputA.questionType = ORKQuestionTypeSingleChoice;
    inputA.choiceAnswers = @[answers.firstObject];
    ORKStepResult *stepResultA = [[ORKStepResult alloc] initWithStepIdentifier:@"momentInDay" results:@[inputA]];
    
    ORKChoiceQuestionResult *inputB = [[ORKChoiceQuestionResult alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]];
    inputB.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    inputB.endDate = [inputB.startDate dateByAddingTimeInterval:30];
    inputB.questionType = ORKQuestionTypeSingleChoice;
    inputB.choiceAnswers = @[answers.lastObject];
    ORKStepResult *stepResultB = [[ORKStepResult alloc] initWithStepIdentifier:@"activityTiming" results:@[inputB]];
    
    return @[stepResultA, stepResultB];
}

@end
