//
//  SBATrackedDataStore.m
//  BridgeAppSDK
//
// Copyright (c) 2016, Sage Bionetworks. All rights reserved.
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

#import "SBATrackedDataStore.h"
#import "SBATrackedDataObject.h"
#import <BridgeAppSDK/BridgeAppSDK-Swift.h>

NSString * kSkippedAnswer           = @"Skipped";
NSString * kNoTrackedData           = @"No Tracked Data";

//
//    elapsed time delay before asking the user tracking questions again
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowMomentInDaySurvey         = 20.0 * 60.0;

//
//    elapsed time delay before asking the user if their tracked data has changed
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowMedChangedSurvey         = 30.0 * 24.0 * 60.0 * 60.0;

@interface SBATrackedDataStore ()

@property (nonatomic) NSMutableDictionary *changesDictionary;
@property (nonatomic, copy, readwrite) NSArray * momentInDayResultDefaultIdMap;
@property (nonatomic, copy, readwrite) NSDictionary * momentInDayResultTrackEachMap;

@end

@implementation SBATrackedDataStore

+ (instancetype)defaultStore {
    static id __instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[self alloc] init];
    });
    return __instance;
}

- (instancetype)init {
    return [self initWithUserDefaultsWithSuiteName:nil];
}

- (instancetype)initWithUserDefaultsWithSuiteName:(NSString * _Nullable)suiteName {
    if ((self = [super init])) {
        _storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        _changesDictionary = [NSMutableDictionary new];
    }
    return self;
}

+ (NSString *)keyPrefix {
    return @"";
}

+ (NSString *)momentInDayResultKey {
    return [NSString stringWithFormat:@"%@momentInDayResult", [self keyPrefix]];
}

+ (NSString *)skippedSelectionSurveyQuestionKey {
    return [NSString stringWithFormat:@"%@skippedSelectionSurveyQuestion", [self keyPrefix]];
}

+ (NSString *)lastTrackingSurveyDateKey {
    return [NSString stringWithFormat:@"%@lastTrackingSurveyDate", [self keyPrefix]];
}

+ (NSString *)selectedItemsKey {
    return [NSString stringWithFormat:@"%@selectedItems", [self keyPrefix]];
}

+ (NSString *)noTrackedItemsAnswer {
    return kNoTrackedData;
}

+ (NSString *)skippedAnswer {
    return kSkippedAnswer;
}

@synthesize momentInDayResult = _momentInDayResult;

- (NSArray<ORKStepResult *> *)momentInDayResult {
    NSString *momentInDayResultKey = [[self class] momentInDayResultKey];
    NSArray<ORKStepResult *> *momentInDayResult = [self.changesDictionary objectForKey:momentInDayResultKey] ?: _momentInDayResult;
    if (momentInDayResult == nil) {
        NSString *defaultAnswer = nil;
        if (self.skippedSelectionSurveyQuestion) {
            defaultAnswer = [[self class] skippedAnswer];
        }
        else if (self.hasNoTrackedItems) {
            defaultAnswer = [[self class] noTrackedItemsAnswer];
        }
        NSArray *idMap = self.momentInDayResultDefaultIdMap;
        if ((defaultAnswer != nil) && (idMap != nil)) {
            NSMutableArray *results = [NSMutableArray new];
            NSDate *startDate = [NSDate date];
            for (NSArray *map in idMap) {
                ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:map.lastObject];
                input.startDate = startDate;
                input.endDate = startDate;
                input.questionType = ORKQuestionTypeSingleChoice;
                if ([self.momentInDayResultTrackEachMap[map.firstObject] boolValue]) {
                    // if tracking each then use an empty array
                    input.choiceAnswers = @[];
                }
                else {
                    // Only include the default answer if *not* trackEach
                    input.choiceAnswers = @[defaultAnswer];
                }
                ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:map.firstObject
                                                                                  results:@[input]];
                [results addObject:stepResult];
            }
            momentInDayResult = [results copy];
            self.changesDictionary[momentInDayResultKey] = momentInDayResult;
        }
    }
    return momentInDayResult;
}

- (void)setMomentInDayResult:(NSArray<ORKStepResult *> *)momentInDayResult {
    [self.changesDictionary setValue:[momentInDayResult copy] forKey:[[self class] momentInDayResultKey]];
}

- (NSArray <NSString *> *)trackedItemDataObjects {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = YES", NSStringFromSelector(@selector(tracking))];
    NSArray *selectedItems = [self selectedItems];
    return [selectedItems filteredArrayUsingPredicate:predicate];
}

- (NSArray <NSString *> *)trackedItems {
    return [[self trackedItemDataObjects] valueForKey:NSStringFromSelector(@selector(shortText))];
}

- (NSArray<SBATrackedDataObject *> *)selectedItems {
    NSArray *result = self.changesDictionary[[[self class] selectedItemsKey]];
    if (result == nil) {
        NSData *data = [self.storedDefaults objectForKey:[[self class] selectedItemsKey]];
        if (data != nil) {
            result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
    }
    return result;
}

- (void)setSelectedItems:(NSArray<SBATrackedDataObject *> *)selectedItems {
    [self.changesDictionary setValue:selectedItems forKey:[[self class] selectedItemsKey]];
    [self.changesDictionary setValue:@(selectedItems == nil) forKey:[[self class] skippedSelectionSurveyQuestionKey]];
}

- (void)updateSelectedItems:(NSArray<SBATrackedDataObject *> *)items
             stepIdentifier:(NSString *)stepIdentifier
                     result:(ORKTaskResult*)result {

    ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:stepIdentifier];
    ORKChoiceQuestionResult *selectionResult = (ORKChoiceQuestionResult *)[stepResult.results firstObject];
    
    if (selectionResult == nil) {
        return;
    }
    if (![selectionResult isKindOfClass:[ORKChoiceQuestionResult class]]) {
        NSAssert(NO, @"The Medication selection result was not of the expected class of ORKChoiceQuestionResult");
        return;
    }
    
    // If skipped return nil
    if ((selectionResult.choiceAnswers == nil) ||
        ([selectionResult.choiceAnswers isEqualToArray:@[kSkippedAnswer]])) {
        self.selectedItems = nil;
        return;
    }
    
    // Get the selected ids
    NSArray *selectedIds = selectionResult.choiceAnswers;
    
    // Get the selected meds by filtering this list
    NSString *identifierKey = NSStringFromSelector(@selector(identifier));
    NSPredicate *idsPredicate = [NSPredicate predicateWithFormat:@"%K IN %@", identifierKey, selectedIds];
    NSArray *sort = @[[NSSortDescriptor sortDescriptorWithKey:identifierKey ascending:YES]];
    NSArray *selectedItems = [[items filteredArrayUsingPredicate:idsPredicate] sortedArrayUsingDescriptors:sort];
    if (selectedItems.count > 0) {
        // Map frequency from the previously stored results
        NSPredicate *frequencyPredicate = [NSPredicate predicateWithFormat:@"%K > 0", NSStringFromSelector(@selector(frequency))];
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[frequencyPredicate, idsPredicate]];
        NSArray *previousItems = [[self.selectedItems filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:sort];
        
        if (previousItems.count > 0) {
            // If there are frequency results to map, then map them into the returned results
            // (which may be a different object from the med list in the data store)
            NSEnumerator *enumerator = [previousItems objectEnumerator];
            SBATrackedDataObject *previousItem = [enumerator nextObject];
            for (SBATrackedDataObject *item in selectedItems) {
                if ([previousItem.identifier isEqualToString:item.identifier]) {
                    item.frequency = previousItem.frequency;
                    previousItem = [enumerator nextObject];
                    if (previousItem == nil) { break; }
                }
            }
        }
    }
    
    self.selectedItems = selectedItems;
}

- (void)updateFrequencyForStepIdentifier:(NSString *)stepIdentifier
                                  result:(ORKTaskResult *)result {
    
    ORKStepResult *frequencyResult = (ORKStepResult *)[result resultForIdentifier:stepIdentifier];
    
    if (frequencyResult != nil) {

        // Get the selected items array
        NSArray *selectedItems = self.selectedItems;
        
        // If there are frequency results to map, then map them into the returned results
        // (which may be a different object from the med list in the data store)
        for (SBATrackedDataObject *item in selectedItems) {
            ORKScaleQuestionResult *scaleResult = (ORKScaleQuestionResult *)[frequencyResult resultForIdentifier:item.identifier];
            if ([scaleResult isKindOfClass:[ORKScaleQuestionResult class]]) {
                item.frequency = [scaleResult.scaleAnswer unsignedIntegerValue];
            }
        }
        
        // Set it back to the selected Items
        self.selectedItems = selectedItems;
    }
}

- (void)updateMomentInDayForStepResult:(ORKStepResult * _Nullable)stepResult {
    
    NSString *stepIdentifier = stepResult.identifier;
    if (stepResult == nil) {
        return;
    }
    
    // Look for previous result
    NSString *momentInDayResultKey = [[self class] momentInDayResultKey];
    NSArray *previous = [self.changesDictionary objectForKey:momentInDayResultKey] ?: _momentInDayResult ?: @[];
    
    // Remove previous result
    NSMutableArray *momentInDayResults = [previous mutableCopy];
    NSString *identifierKey = NSStringFromSelector(@selector(identifier));
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", identifierKey, stepIdentifier];
    NSPredicate *notPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:predicate];
    [momentInDayResults filterUsingPredicate:notPredicate];
    
    // Add new result
    [momentInDayResults addObject:stepResult];
    
    self.momentInDayResult = momentInDayResults;
}

- (void)updateMomentInDayIdMap:(NSArray <ORKStep *> *)activitySteps {
    NSMutableArray *idMap = [NSMutableArray new];
    NSMutableDictionary *trackEachMap = [NSMutableDictionary new];
    for (ORKFormStep *step in activitySteps) {
        if ([step isKindOfClass:[ORKFormStep class]]) {
            ORKFormItem *formItem = [step.formItems firstObject];
            if (formItem != nil) {
                if ([step isKindOfClass:[SBATrackedFormStep class]]) {
                    trackEachMap[step.identifier] = @(((SBATrackedFormStep*)step).trackEach);
                }
                [idMap addObject:@[step.identifier, formItem.identifier]];
            }
        }
    }
    self.momentInDayResultDefaultIdMap = idMap;
    self.momentInDayResultTrackEachMap = trackEachMap;
}

- (NSDate *)lastTrackingSurveyDate {
    return [self.storedDefaults objectForKey:[[self class] lastTrackingSurveyDateKey]];
}

- (void)setLastTrackingSurveyDate:(NSDate *)lastTrackingSurveyDate {
    if (lastTrackingSurveyDate != nil) {
        [self.storedDefaults setObject:lastTrackingSurveyDate forKey:[[self class] lastTrackingSurveyDateKey]];
    }
}

- (BOOL)skippedSelectionSurveyQuestion {
    NSString *key = [[self class] skippedSelectionSurveyQuestionKey];
    id obj = [self.changesDictionary objectForKey:key] ?: [self.storedDefaults objectForKey:key];
    return [obj boolValue];
}

- (void)setSkippedSelectionSurveyQuestion:(BOOL)skippedSelectionSurveyQuestion {
    if (skippedSelectionSurveyQuestion) {
        self.selectedItems = nil;
    }
    else {
        [self.changesDictionary setValue:@(NO) forKey:[[self class] skippedSelectionSurveyQuestionKey]];
    }
}

- (BOOL)hasNoTrackedItems {
    NSArray *trackedObjects = self.trackedItemDataObjects;
    return (trackedObjects != nil) && (trackedObjects.count == 0);
}

- (BOOL)hasSelectedOrSkipped {
    return self.skippedSelectionSurveyQuestion || (self.selectedItems != nil);
}

- (BOOL)shouldIncludeMomentInDayStep {
    if (self.trackedItemDataObjects.count == 0) {
        return NO;
    }
    
    if (self.lastCompletionDate == nil || self.momentInDayResult == nil) {
        return YES;
    }
    
    NSTimeInterval numberOfSecondsSinceTaskCompletion = [[NSDate date] timeIntervalSinceDate: self.lastCompletionDate];
    NSTimeInterval minInterval = kMinimumAmountOfTimeToShowMomentInDaySurvey;
    
    return (numberOfSecondsSinceTaskCompletion > minInterval);
}

- (BOOL)shouldIncludeChangedQuestion {
    if (!self.hasSelectedOrSkipped) {
        // Chould not ask if there has been a change if the question has never been asked
        return NO;
    }
    NSTimeInterval numberOfSecondsSinceTaskCompletion = [[NSDate date] timeIntervalSinceDate: self.lastTrackingSurveyDate];
    NSTimeInterval minInterval = kMinimumAmountOfTimeToShowMedChangedSurvey;
    
    return (numberOfSecondsSinceTaskCompletion > minInterval);
}

- (BOOL)hasChanges {
    return (self.changesDictionary.count > 0);
}

- (void)commitChanges {

    // store the moment in day result in memeory
    NSArray *momentInDayResult = [self.changesDictionary objectForKey:[[self class] momentInDayResultKey]];
    if (momentInDayResult != nil) {
        self.lastCompletionDate = [NSDate date];
        _momentInDayResult = momentInDayResult;
    }
    
    // store the tracked items and skip result in user defaults
    id skipped = self.changesDictionary[[[self class] skippedSelectionSurveyQuestionKey]];
    if (skipped != nil) {
        self.lastTrackingSurveyDate = [NSDate date];
        [self.storedDefaults setValue:skipped forKey:[[self class] skippedSelectionSurveyQuestionKey]];
        if ([skipped boolValue]) {
            [self.storedDefaults removeObjectForKey:[[self class] selectedItemsKey]];
        }
        else {
            NSArray *selectedMeds = self.changesDictionary[[[self class] selectedItemsKey]];
            if (selectedMeds != nil) {
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selectedMeds];
                [self.storedDefaults setValue:data
                                       forKey:[[self class] selectedItemsKey]];
            }
        }
    }
    
    // clear temp storage
    [self.changesDictionary removeAllObjects];
}

- (void)reset {
    [self.changesDictionary removeAllObjects];
}

@end
