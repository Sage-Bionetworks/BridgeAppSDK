//
//  SBATrackedDataStore.h
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

#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>

#import "SBATrackedDataObjectCollection.h"

NS_ASSUME_NONNULL_BEGIN

@class SBATrackedDataObject;

@interface SBATrackedDataStore : NSObject

+ (instancetype)sharedStore NS_REFINED_FOR_SWIFT;

/**
 Timestamp for the last time the tracked data survey questions were asked.
 (ex. What medication, etc.)
 */
@property (nonatomic, copy, nullable) NSDate *lastTrackingSurveyDate;

/**
 Timestamp for the last time the "Moment in Day" survey questions were asked.
 */
@property (nonatomic, copy, nullable) NSDate *lastCompletionDate;

/**
 Selected items from the tracked data survey questions. Assumes only one set of items.
 */
@property (nonatomic, copy, nullable) NSArray<SBATrackedDataObject *> *selectedItems;

/**
 Items from the tracked data survey questions that are *tracked* with "Moment in Day" 
 follow-up. Assumes only one set of items. This is a subset of the selected items that includes 
 only the selected items that are tracked with a follow-up question.
 */
@property (nonatomic, copy, readonly, nullable) NSArray<SBATrackedDataObject *> *trackedItems;

/**
 Steps that map to the "Moment in Day" step results. These are used to determine the default
 result for the case where there are no selected items.
 */
@property (nonatomic, copy, nullable) NSArray<ORKStep *> *momentInDaySteps;

/**
 Results that map to "Moment in Day" steps. These results are stored in memory only.
 */
@property (nonatomic, copy, nullable) NSArray<ORKStepResult *> *momentInDayResults;

/**
 Update the "Moment in Day" result set.
 @param     stepResult  The step result to add/replace in the "Moment in Day" result set.
 */
- (void)updateMomentInDayForStepResult:(ORKStepResult *)stepResult;

/**
 Update the tracked data result set. If this is recognized as including the `selectedItems`
 then that property will be updated from this result.
 @param     stepResult  The step result to use to add/replace the tracked data set
 */
- (void)updateTrackedDataForStepResult:(ORKStepResult *)stepResult;

/**
 Return the step result that is associated with a given step.
 @param     step    The step for which a result is requested.
 @return            The step result for this step (if found in the data store)
 */
- (nullable ORKStepResult *)stepResultForStep:(ORKStep *)step;

#pragma mark - Data storage handling

/**
 By default, the tracked data is saved to the user defaults. This allows a shared user defaults
 to be used by this project.
 */
@property (nonatomic, readonly) NSUserDefaults *storedDefaults;

/**
 Are there changes that need to be commited to the data store?
 */
@property (nonatomic, readonly) BOOL hasChanges;

/**
 Initialize with a user defaults that has a suite name (for sharing defaults across different apps)
 @param suiteName   Optional suite name for the user defaults (if nil, standard defaults are used)
 @return            Tracked data store
 */
- (instancetype)initWithUserDefaultsWithSuiteName:(NSString * _Nullable)suiteName;

/**
 Commit changes to the data store.
 */
- (void)commitChanges;

/**
 Reset the changes without commiting them.
 */
- (void)reset;

/**
 @Deprecated Use sharedStore instead
 */
+ (instancetype)defaultStore __deprecated;

// Keys exposed to keep compatibility with existing implementations
+ (NSString *)keyPrefix;
+ (NSString *)lastTrackingSurveyDateKey;
+ (NSString *)selectedItemsKey;
+ (NSString *)resultsKey;

@end

NS_ASSUME_NONNULL_END
