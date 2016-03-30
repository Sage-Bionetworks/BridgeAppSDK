//
//  SBAMedication.m
//  BridgeAppSDK
//
//  Created by Shannon Young on 4/4/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "SBAMedication.h"

@implementation SBAMedication

+ (NSString *)classType {
    return @"Medication";
}

- (BOOL)usesFrequencyRange {
    return !self.injection;
}

- (NSString *)defaultIdentifierIfNil {
    return self.brand ?: self.name;
}

- (NSArray <NSString *> *)dictionaryRepresentationKeys {
    NSArray *additionalKeys = @[NSStringFromSelector(@selector(name)),
                                NSStringFromSelector(@selector(brand)),
                                NSStringFromSelector(@selector(detail)),
                                NSStringFromSelector(@selector(injection))];
    return [[super dictionaryRepresentationKeys] arrayByAddingObjectsFromArray:additionalKeys];
}

- (NSString *)text {
    NSMutableString *result = [self.name mutableCopy];
    if (self.detail.length > 0) {
        [result appendFormat:@" %@", self.detail];
    }
    if (self.brand.length > 0) {
        [result appendFormat:@" (%@)", self.brand];
    }
    return result;
}

- (NSString *)shortText {
    return self.brand ?: self.name;
}

@end
