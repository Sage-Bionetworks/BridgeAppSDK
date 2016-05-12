//
//  ORKResult+SBAExtension.m
//  BridgeAppSDK
//
//  Created by Erin Mounts on 5/11/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "ORKResult+SBAExtension.h"
#import "SBALog.h"

//
//    ORK Result Base Class property keys
//
static NSString * const kIdentifierKey              = @"identifier";
static NSString * const kStartDateKey               = @"startDate";
static NSString * const kEndDateKey                 = @"endDate";
static NSString * const kUserInfoKey                = @"userInfo";

//
//    General-Use Dictionary Keys
//
static  NSString  *const  kItemKey                  = @"item";
//
//    Interval Tapping Dictionary Keys
//
static  NSString  *const  kTappingViewSizeKey       = @"TappingViewSize";
static  NSString  *const  kButtonRectLeftKey        = @"ButtonRectLeft";
static  NSString  *const  kButtonRectRightKey       = @"ButtonRectRight";
static  NSString  *const  kTappingSamplesKey        = @"TappingSamples";
static  NSString  *const  kTappedButtonIdKey        = @"TappedButtonId";
static  NSString  *const  kTappedButtonNoneKey      = @"TappedButtonNone";
static  NSString  *const  kTappedButtonLeftKey      = @"TappedButtonLeft";
static  NSString  *const  kTappedButtonRightKey     = @"TappedButtonRight";
static  NSString  *const  kTapTimeStampKey          = @"TapTimeStamp";
static  NSString  *const  kTapCoordinateKey         = @"TapCoordinate";
//
//    Spatial Span Memory Dictionary Keys — Game Status
//
static  NSString   *const  kSpatialSpanMemoryGameStatusKey              = @"MemoryGameStatus";
static  NSString   *const  kSpatialSpanMemoryGameStatusUnknownKey       = @"MemoryGameStatusUnknown";
static  NSString   *const  kSpatialSpanMemoryGameStatusSuccessKey       = @"MemoryGameStatusSuccess";
static  NSString   *const  kSpatialSpanMemoryGameStatusFailureKey       = @"MemoryGameStatusFailure";
static  NSString   *const  kSpatialSpanMemoryGameStatusTimeoutKey       = @"MemoryGameStatusTimeout";
//
//    Spatial Span Memory Dictionary Keys — Summary
//
static  NSString  *const  kSpatialSpanMemorySummaryNumberOfGamesKey     = @"MemoryGameNumberOfGames";
static  NSString  *const  kSpatialSpanMemorySummaryNumberOfFailuresKey  = @"MemoryGameNumberOfFailures";
static  NSString  *const  kSpatialSpanMemorySummaryOverallScoreKey      = @"MemoryGameOverallScore";
static  NSString  *const  kSpatialSpanMemorySummaryGameRecordsKey       = @"MemoryGameGameRecords";
static  NSString  *const  kSpatialSpanMemorySummaryFilenameKey          = @"MemoryGameResults.json";
//
//    Spatial Span Memory Dictionary Keys — Game Records
//
static  NSString   *const  kSpatialSpanMemoryGameRecordSeedKey          = @"MemoryGameRecordSeed";
static  NSString   *const  kSpatialSpanMemoryGameRecordSequenceKey      = @"MemoryGameRecordSequence";
static  NSString   *const  kSpatialSpanMemoryGameRecordGameSizeKey      = @"MemoryGameRecordGameSize";
static  NSString   *const  kSpatialSpanMemoryGameRecordTargetRectsKey   = @"MemoryGameRecordTargetRects";
static  NSString   *const  kSpatialSpanMemoryGameRecordTouchSamplesKey  = @"MemoryGameRecordTouchSamples";
static  NSString   *const  kSpatialSpanMemoryGameRecordGameScoreKey     = @"MemoryGameRecordGameScore";
//
//    Spatial Span Memory Dictionary Keys — Touch Samples
//
static  NSString  *const  kSpatialSpanMemoryTouchSampleTimeStampKey     = @"MemoryGameTouchSampleTimestamp";
static  NSString  *const  kSpatialSpanMemoryTouchSampleTargetIndexKey   = @"MemoryGameTouchSampleTargetIndex";
static  NSString  *const  kSpatialSpanMemoryTouchSampleLocationKey      = @"MemoryGameTouchSampleLocation";
static  NSString  *const  kSpatialSpanMemoryTouchSampleIsCorrectKey     = @"MemoryGameTouchSampleIsCorrect";


@interface ORKResult (SBAInternal)

- (NSData *)dataFromFile:(NSURL *)fileURL;
- (NSData *)dataFromDictionary:(NSDictionary *)dictionary;

@end

@implementation ORKResult (SBAInternal)

- (NSData *)dataFromFile:(NSURL *)fileURL
{
    return [NSData dataWithContentsOfURL:fileURL];
}

- (NSData *)dataFromDictionary:(NSDictionary *)dictionary
{
    NSError * serializationError;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&serializationError];
    
    if (jsonData == nil) {
        SBALogError2(serializationError);
        NSAssert(NO, @"Failed to serialize JSON dictionary");
    }
    
    return jsonData;
}

@end

@implementation ORKResult (SBAExtension)

// public methods not implemented here; each subclass must implement either directly or in a category

@end

@implementation ORKFileResult (SBAExtension)

- (NSData *)sba_bridgeData
{
    return [self dataFromFile:self.fileURL];
}

@end

@implementation ORKTappingIntervalResult (SBAExtension)

- (NSData *)sba_bridgeData
{
    NSMutableDictionary  *rawTappingResults = [NSMutableDictionary dictionary];
    
    NSString  *tappingViewSize = NSStringFromCGSize(self.stepViewSize);
    rawTappingResults[kTappingViewSizeKey] = tappingViewSize;
    
    rawTappingResults[kStartDateKey] = self.startDate;
    rawTappingResults[kEndDateKey]   = self.endDate;
    
    NSString  *leftButtonRect = NSStringFromCGRect(self.buttonRect1);
    rawTappingResults[kButtonRectLeftKey] = leftButtonRect;
    
    NSString  *rightButtonRect = NSStringFromCGRect(self.buttonRect2);
    rawTappingResults[kButtonRectRightKey] = rightButtonRect;
    
    NSArray  *samples = self.samples;
    NSMutableArray  *sampleResults = [NSMutableArray array];
    for (ORKTappingSample *sample  in  samples) {
        NSMutableDictionary  *aSampleDictionary = [NSMutableDictionary dictionary];
        
        aSampleDictionary[kTapTimeStampKey]     = @(sample.timestamp);
        
        aSampleDictionary[kTapCoordinateKey]   = NSStringFromCGPoint(sample.location);
        
        if (sample.buttonIdentifier == ORKTappingButtonIdentifierNone) {
            aSampleDictionary[kTappedButtonIdKey] = kTappedButtonNoneKey;
        } else if (sample.buttonIdentifier == ORKTappingButtonIdentifierLeft) {
            aSampleDictionary[kTappedButtonIdKey] = kTappedButtonLeftKey;
        } else if (sample.buttonIdentifier == ORKTappingButtonIdentifierRight) {
            aSampleDictionary[kTappedButtonIdKey] = kTappedButtonRightKey;
        }
        [sampleResults addObject:aSampleDictionary];
    }
    rawTappingResults[kTappingSamplesKey] = sampleResults;
    rawTappingResults[kItemKey] = [self.identifier stringByAppendingString:@".json"];
    
    return [self dataFromDictionary:rawTappingResults];
}

@end

@implementation ORKSpatialSpanMemoryResult (SBAExtension)

- (NSData *)sba_bridgeData
{
    NSString  *gameStatusKeys[] = { kSpatialSpanMemoryGameStatusUnknownKey, kSpatialSpanMemoryGameStatusSuccessKey, kSpatialSpanMemoryGameStatusFailureKey, kSpatialSpanMemoryGameStatusTimeoutKey };
    
    NSMutableDictionary  *memoryGameResults = [NSMutableDictionary dictionary];
    
    //
    //    ORK Result
    //
    memoryGameResults[kIdentifierKey] = self.identifier;
    memoryGameResults[kStartDateKey]  = self.startDate;
    memoryGameResults[kEndDateKey]    = self.endDate;
    //
    //    ORK ORKSpatialSpanMemoryResult
    //
    memoryGameResults[kSpatialSpanMemorySummaryNumberOfGamesKey]    = @(self.numberOfGames);
    memoryGameResults[kSpatialSpanMemorySummaryNumberOfFailuresKey] = @(self.numberOfFailures);
    memoryGameResults[kSpatialSpanMemorySummaryOverallScoreKey]     = @(self.score);
    
    //
    //    Memory Game Records
    //
    NSMutableArray   *gameRecords = [NSMutableArray arrayWithCapacity:[self.gameRecords count]];
    
    for (ORKSpatialSpanMemoryGameRecord  *aRecord  in  self.gameRecords) {
        
        NSMutableDictionary  *aGameRecord = [NSMutableDictionary dictionary];
        
        aGameRecord[kSpatialSpanMemoryGameRecordSeedKey]      = @(aRecord.seed);
        aGameRecord[kSpatialSpanMemoryGameRecordGameSizeKey]  = @(aRecord.gameSize);
        aGameRecord[kSpatialSpanMemoryGameRecordGameScoreKey] = @(aRecord.score);
        aGameRecord[kSpatialSpanMemoryGameRecordSequenceKey]  = aRecord.sequence;
        aGameRecord[kSpatialSpanMemoryGameStatusKey]          = gameStatusKeys[aRecord.gameStatus];
        
        NSArray  *touchSamples = [self makeTouchSampleRecords:aRecord.touchSamples];
        aGameRecord[kSpatialSpanMemoryGameRecordTouchSamplesKey] = touchSamples;
        
        NSArray  *rectangles = [self makeTargetRectangleRecords:aRecord.targetRects];
        aGameRecord[kSpatialSpanMemoryGameRecordTargetRectsKey] = rectangles;
        
        [gameRecords addObject:aGameRecord];
    }
    memoryGameResults[kSpatialSpanMemorySummaryGameRecordsKey] = gameRecords;
    memoryGameResults[kItemKey] = [self.identifier stringByAppendingString:@".json"];
    return [self dataFromDictionary:memoryGameResults];
}


- (NSArray *)makeTouchSampleRecords:(NSArray *)touchSamples
{
    NSMutableArray  *samples = [NSMutableArray array];
    
    for (ORKSpatialSpanMemoryGameTouchSample  *sample  in  touchSamples) {
        
        NSMutableDictionary  *aTouchSample = [NSMutableDictionary dictionary];
        
        aTouchSample[kSpatialSpanMemoryTouchSampleTimeStampKey]   = @(sample.timestamp);
        aTouchSample[kSpatialSpanMemoryTouchSampleTargetIndexKey] = @(sample.targetIndex);
        aTouchSample[kSpatialSpanMemoryTouchSampleLocationKey]    = NSStringFromCGPoint(sample.location);
        aTouchSample[kSpatialSpanMemoryTouchSampleIsCorrectKey]   = @(sample.isCorrect);
        
        [samples addObject:aTouchSample];
    }
    return  samples;
}

- (NSArray *)makeTargetRectangleRecords:(NSArray *)targetRectangles
{
    NSMutableArray  *rectangles = [NSMutableArray array];
    
    for (NSValue  *value  in  targetRectangles) {
        CGRect  rectangle = [value CGRectValue];
        NSString  *stringified = NSStringFromCGRect(rectangle);
        [rectangles addObject:stringified];
    }
    return  rectangles;
}

@end
