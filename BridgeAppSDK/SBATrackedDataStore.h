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

@interface SBATrackedDataStore : NSObject

+ (instancetype)defaultStore;

@property (nonatomic, copy) NSDate * _Nullable lastCompletionDate;
@property (nonatomic, copy) NSArray <ORKStepResult *> * _Nullable momentInDayResult;
@property (nonatomic, copy) NSDate * _Nullable lastTrackingSurveyDate;
@property (nonatomic, copy) NSArray <SBATrackedDataObject*> * _Nullable selectedItems;
@property (nonatomic) BOOL skippedSelectionSurveyQuestion;

@property (nonatomic, readonly) NSArray <NSString*> * _Nullable trackedItems;
@property (nonatomic, readonly) BOOL hasNoTrackedItems;
@property (nonatomic, readonly) BOOL hasSelectedOrSkipped;
@property (nonatomic, readonly) BOOL shouldIncludeChangedQuestion;
@property (nonatomic, readonly) BOOL shouldIncludeMomentInDayStep;
@property (nonatomic, readonly) BOOL hasChanges;

@property (nonatomic, readonly) NSUserDefaults *storedDefaults;
@property (nonatomic, copy, readonly) NSArray * _Nullable momentInDayResultDefaultIdMap;

/**
 * Initialize with a user defaults that has a suite name (for sharing defaults across different apps)
 */
- (instancetype)initWithUserDefaultsWithSuiteName:(NSString * _Nullable)suiteName;

- (void)updateSelectedItems:(NSArray<SBATrackedDataObject *> *)items
             stepIdentifier:(NSString *)stepIdentifier
                     result:(ORKTaskResult*)result;

- (void)updateFrequencyForStepIdentifier:(NSString *)stepIdentifier
                                  result:(ORKTaskResult *)result;

- (void)updateMomentInDayForStepResult:(ORKStepResult * _Nullable)result;

- (void)updateMomentInDayIdMap:(NSArray <ORKStep *> *)activitySteps;

- (void)commitChanges;
- (void)reset;

// Keys exposed to keep compatibility with existing implementations
+ (NSString *)keyPrefix;
+ (NSString *)momentInDayResultKey;
+ (NSString *)skippedSelectionSurveyQuestionKey;
+ (NSString *)lastTrackingSurveyDateKey;
+ (NSString *)selectedItemsKey;
+ (NSString *)noTrackedItemsAnswer;
+ (NSString *)skippedAnswer;

@end

NS_ASSUME_NONNULL_END
