//
//  SBATrackedDataObjectCollection.m
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

#import "SBATrackedDataObjectCollection.h"
#import "SBATrackedDataStore.h"

static NSString *kTrackedItemsKey = @"items";

@implementation SBATrackedDataObjectCollection

- (NSString *)taskIdentifier {
    if (_taskIdentifier == nil) {
        _taskIdentifier = [[NSUUID UUID] UUIDString];
    }
    return _taskIdentifier;
}

- (NSString *)schemaIdentifier {
    if (_schemaIdentifier == nil) {
        _schemaIdentifier = self.taskIdentifier;
    }
    return _schemaIdentifier;
}

- (SBATrackedDataStore *)dataStore {
    if (_dataStore == nil) {
        _dataStore = [SBATrackedDataStore sharedStore];
    }
    return _dataStore;
}

- (NSNumber *)trackingSurveyRepeatTimeInterval {
    if (_trackingSurveyRepeatTimeInterval == nil) {
        _trackingSurveyRepeatTimeInterval = @(30 * 24 * 60 * 60);   // Every 30 days by default
    }
    return _trackingSurveyRepeatTimeInterval;
}

- (NSNumber *)momentInDayRepeatTimeInterval {
    if (_momentInDayRepeatTimeInterval == nil) {
        _momentInDayRepeatTimeInterval = @(20 * 60);   // Every 20 minutes by default
    }
    return _momentInDayRepeatTimeInterval;
}

- (NSString *)defaultIdentifierIfNil {
    return self.schemaIdentifier;
}

- (NSArray<NSString *> *)dictionaryRepresentationKeys {
    NSMutableArray *superKeys = [[super dictionaryRepresentationKeys] mutableCopy];
    [superKeys removeObject:NSStringFromSelector(@selector(identifier))];
    NSArray *subkeys = @[NSStringFromSelector(@selector(taskIdentifier)),
                         NSStringFromSelector(@selector(schemaIdentifier)),
                         NSStringFromSelector(@selector(alwaysIncludeActivitySteps)),
                         NSStringFromSelector(@selector(trackingSurveyRepeatTimeInterval)),
                         NSStringFromSelector(@selector(momentInDayRepeatTimeInterval)),
                         NSStringFromSelector(@selector(itemsClassType)),
                         kTrackedItemsKey,
                         NSStringFromSelector(@selector(steps))];
    return [subkeys arrayByAddingObjectsFromArray:superKeys];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:kTrackedItemsKey] && [value isKindOfClass:[NSArray class]]) {
        NSMutableArray *items = [value mutableCopy];
        for (NSUInteger ii=0; ii < items.count; ii++) {
            if (![items[ii] isKindOfClass:[SBATrackedDataObject class]]) {
                id replacement = [self mapValue:items[ii] forKey:key withClassType:self.itemsClassType];
                if (replacement) {
                    [items replaceObjectAtIndex:ii withObject:replacement];
                }
            }
        }
        _items = [items copy];
    }
    else {
        [super setValue:value forKey:key];
    }
}

@end
