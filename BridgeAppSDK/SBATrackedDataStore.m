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

@interface SBATrackedDataStore ()

@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSDictionary *> * _Nullable managedResults;

@property (nonatomic) NSMutableDictionary *changesDictionary;

@end

@implementation SBATrackedDataStore

+ (instancetype)defaultStore {
    return [self sharedStore];
}

+ (instancetype)sharedStore {
    static id __instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[self alloc] init];
    });
    return __instance;
}

- (instancetype)init {
    NSString *suiteName = nil;
    id appDelegate = [[UIApplication sharedApplication] delegate];
    if ([appDelegate conformsToProtocol:@protocol(SBAAppInfoDelegate)]) {
        suiteName = [[appDelegate bridgeInfo] appGroupIdentifier];
    }
    return [self initWithUserDefaultsWithSuiteName:suiteName];
}

- (instancetype)initWithUserDefaultsWithSuiteName:(NSString * _Nullable)suiteName {
    if ((self = [super init])) {
        _storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        _changesDictionary = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - Keys

+ (NSString *)keyPrefix {
    return @"";
}

+ (NSString *)lastTrackingSurveyDateKey {
    return [NSString stringWithFormat:@"%@lastTrackingSurveyDate", [self keyPrefix]];
}

+ (NSString *)selectedItemsKey {
    return [NSString stringWithFormat:@"%@selectedItems", [self keyPrefix]];
}

+ (NSString *)resultsKey {
    return [NSString stringWithFormat:@"%@results", [self keyPrefix]];
}

+ (NSString *)momentInDayResultsKey {
    return [NSString stringWithFormat:@"%@momentInDayResults", [self keyPrefix]];
}

#pragma mark - Tracked and Stored Accessors

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
}

- (NSArray <SBATrackedDataObject*> *)trackedItems {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = YES", NSStringFromSelector(@selector(tracking))];
    NSArray *selectedItems = [self selectedItems];
    return [selectedItems filteredArrayUsingPredicate:predicate];
}

- (NSDate *)lastTrackingSurveyDate {
    return [self.storedDefaults objectForKey:[[self class] lastTrackingSurveyDateKey]];
}

- (void)setLastTrackingSurveyDate:(NSDate *)lastTrackingSurveyDate {
    [self.storedDefaults setValue:lastTrackingSurveyDate forKey:[[self class] lastTrackingSurveyDateKey]];
}

- (NSDictionary<NSString *, NSDictionary *> *)managedResults {
    NSDictionary *managedResults = self.changesDictionary[[[self class] resultsKey]];
    if (managedResults == nil) {
        NSData *data = [self.storedDefaults objectForKey:[[self class] resultsKey]];
        if (data != nil) {
            id obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                managedResults = obj;
            }
        }
    }
    return managedResults;
}

- (void)setManagedResults:(NSDictionary<NSString *, NSDictionary *> *)managedResults {
    [self.changesDictionary setValue:managedResults forKey:[[self class] resultsKey]];
}

// Moment in day results are only stored in memory.
@synthesize momentInDayResults = _momentInDayResults;

- (NSArray<ORKStepResult *> *)momentInDayResults {
    NSString *momentInDayResultsKey = [[self class] momentInDayResultsKey];
    NSArray *momentInDayResults = [self.changesDictionary objectForKey:momentInDayResultsKey] ?: _momentInDayResults;
    if ((momentInDayResults == nil) && (self.momentInDaySteps.count > 0) && (self.trackedItems.count == 0)) {
        // Only set the default result if the selected items set is empty
        NSMutableArray *results = [NSMutableArray new];
        for (ORKStep *step in self.momentInDaySteps) {
            [results addObject:[step defaultStepResult]];
        }
        momentInDayResults = [results copy];
    }
    return momentInDayResults;
}

- (void)setMomentInDayResults:(NSArray<ORKStepResult *> *)momentInDayResults {
    [self.changesDictionary setValue:[momentInDayResults copy] forKey:[[self class] momentInDayResultsKey]];
}

#pragma mark - Results Handling

- (void)updateMomentInDayForStepResult:(ORKStepResult *)stepResult {
    NSString *stepIdentifier = stepResult.identifier;
    if (stepResult == nil) {
        return;
    }

    NSMutableArray *momentInDayResults = [self.momentInDayResults mutableCopy] ?: [NSMutableArray new];
    ORKStepResult *previousResult = [self momentInDayResultWithStepIdentifier:stepIdentifier];
    
    if (previousResult != nil) {
        // If found in the moment in day results then replace that result
        NSUInteger idx = [momentInDayResults indexOfObject:previousResult];
        [momentInDayResults replaceObjectAtIndex:idx withObject:stepResult];
    }
    else {
        // Otherwise add to the set
        [momentInDayResults addObject:stepResult];
    }
    
    self.momentInDayResults = momentInDayResults;
}

- (void)updateTrackedDataForStepResult:(ORKStepResult *)stepResult {
    
    NSString *stepIdentifier = stepResult.identifier;
    if (stepResult == nil) {
        return;
    }
    
    // Check if this step result has a selected items result
    __block NSArray *selectedItems = nil;
    [stepResult.results enumerateObjectsUsingBlock:^(ORKResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([result isKindOfClass:[SBATrackedDataSelectionResult class]]) {
            selectedItems = ((SBATrackedDataSelectionResult *)result).selectedItems;
            *stop = YES;
        }
    }];
    
    if (selectedItems != nil) {
        // If the selected Items are found then that is the only result that needs to be set
        self.selectedItems = selectedItems;
    }
    else {
        // Otherwise, add to a general-purpose result set
        NSMutableDictionary *managedResults = [self.managedResults mutableCopy] ?: [NSMutableDictionary new];
        managedResults[stepIdentifier] = [stepResult bridgeData:stepIdentifier].result;
        self.managedResults = managedResults;
    }
}

- (nullable ORKStepResult *)stepResultForStep:(ORKStep *)step {
    
    // Check the moment in day results set for a result that matches the step identifier
    ORKStepResult *momentInDayResult = [self momentInDayResultWithStepIdentifier:step.identifier];
    if (momentInDayResult != nil) {
        return momentInDayResult;
    }
    
    // Check if the step can be built from the selected items
    if ([step conformsToProtocol:@protocol(SBATrackedDataSelectedItemsProtocol)]) {
        NSArray *selectedItems = self.selectedItems;
        if (selectedItems != nil) {
            ORKStepResult *stepResult =  [(id <SBATrackedDataSelectedItemsProtocol>)step stepResultWithSelectedItems:selectedItems];
            stepResult.startDate = self.lastTrackingSurveyDate;
            stepResult.endDate = stepResult.startDate;
            return stepResult;
        }
        else {
            return nil;
        }
    }
    
    NSDictionary *storedResult = self.managedResults[step.identifier];
    if ([storedResult isKindOfClass:[NSDictionary class]]) {
        return [step stepResultWithBridgeDictionary:storedResult];
    }
    
    return nil;
}

- (ORKStepResult *)momentInDayResultWithStepIdentifier:(NSString *)stepIdentifier {
    NSString *identifierKey = NSStringFromSelector(@selector(identifier));
    NSPredicate *identifierPredicate = [NSPredicate predicateWithFormat:@"%K = %@", identifierKey, stepIdentifier];
    
    NSArray *momentInDayResults = self.momentInDayResults;
    ORKStepResult *result = [[momentInDayResults filteredArrayUsingPredicate:identifierPredicate] firstObject];
    return result;
}


#pragma mark - changes management

- (BOOL)hasChanges {
    return (self.changesDictionary.count > 0);
}

- (void)commitChanges {

    // store the moment in day result in memory
    NSArray *momentInDayResults = [self.changesDictionary objectForKey:[[self class] momentInDayResultsKey]];
    if (momentInDayResults != nil) {
        _lastCompletionDate = [NSDate date];
        _momentInDayResults = momentInDayResults;
    }
    
    // store the tracked results in the stored defaults
    NSArray *selectedItems = self.changesDictionary[[[self class] selectedItemsKey]];
    NSDictionary *managedResults = self.changesDictionary[[[self class] resultsKey]];
    if ((selectedItems != nil) || (managedResults != nil)) {
        self.lastTrackingSurveyDate = [NSDate date];
        if (selectedItems != nil) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selectedItems];
            [self.storedDefaults setValue:data forKey:[[self class] selectedItemsKey]];
        }
        if (managedResults != nil) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:managedResults];
            [self.storedDefaults setValue:data forKey:[[self class] resultsKey]];
        }
    }
    
    // clear temp storage
    [self.changesDictionary removeAllObjects];
}

- (void)reset {
    [self.changesDictionary removeAllObjects];
}

@end
