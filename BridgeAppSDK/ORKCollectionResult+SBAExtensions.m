//
//  ORKCollectionResult+SBAExtensions.m
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


#import "ORKCollectionResult+SBAExtensions.h"

@implementation ORKCollectionResult (SBAExtensions)

- (void)validateParameters {
    NSArray *uniqueIdentifiers = [self.results valueForKeyPath:@"@distinctUnionOfObjects.identifier"];
    BOOL itemsHaveNonUniqueIdentifiers = ( self.results.count != uniqueIdentifiers.count );
    
    if (itemsHaveNonUniqueIdentifiers) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Each result should have a unique identifier" userInfo:nil];
    }
}

- (BOOL)hasResults {
    return self.results.count > 0;
}

- (void)addResult:(ORKResult*)result {
    
    NSMutableArray *results = [self.results mutableCopy] ?: [NSMutableArray new];
    
    __block NSUInteger index = NSNotFound;
    [self.results enumerateObjectsUsingBlock:^(ORKResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:result.identifier]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    if (index != NSNotFound) {
        [results replaceObjectAtIndex:index withObject:result];
    }
    else {
        [results addObject:result];
    }
    
    self.results = results;
}

@end

@implementation ORKTaskResult (SBAExtensions)

- (NSArray <ORKStepResult *> *)consolidatedResults {
    
    // Exit early if all are unique
    
    NSArray *uniqueIdentifiers = [self.results valueForKeyPath:@"@distinctUnionOfObjects.identifier"];
    if (self.results.count == uniqueIdentifiers.count) {
        return self.results ?: @[];
    }
    
    NSMutableDictionary <NSString *, NSNumber *> *stepIdentifierCount = [NSMutableDictionary new];
    NSMutableDictionary <NSString *, ORKStepResult *> *stepResultMap = [NSMutableDictionary new];
    NSMutableArray <ORKStepResult *> *results = [NSMutableArray new];
    
    [self.results enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ORKResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ORKStepResult *stepResult = (ORKStepResult *)[obj copy];
        NSNumber *identifierCount = stepIdentifierCount[stepResult.identifier];
        if (identifierCount == nil) {
            // This is the first instance. Add the step result.
            [results insertObject:stepResult atIndex:0];
            stepResultMap[stepResult.identifier] = stepResult;
        }
        else if (stepResult.results.count) {
            // This is a duplicate. Add to existing step result.
            ORKStepResult *previousResult = stepResultMap[stepResult.identifier];
            NSMutableArray *stepResults = [previousResult.results mutableCopy] ?: [NSMutableArray new];
            for (ORKResult *result in stepResult.results) {
                if (![stepResults containsObject:result]) {
                    result.identifier = [NSString stringWithFormat:@"%@_dup%@", result.identifier, identifierCount];
                    [stepResults addObject:result];
                }
            }
            previousResult.results = stepResults;
        }
        stepIdentifierCount[stepResult.identifier] = @(identifierCount.integerValue + 1);
    }];
    
    return [results copy];
}

@end
