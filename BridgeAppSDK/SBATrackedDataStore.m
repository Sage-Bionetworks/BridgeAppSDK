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
                input.choiceAnswers = @[defaultAnswer];
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
