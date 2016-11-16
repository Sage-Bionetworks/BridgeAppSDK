//
//  SBAJSONObject.m
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

#import "SBAJSONObject.h"
@import BridgeSDK;

@implementation NSString (SBAJSONObject)

- (id<NSSecureCoding>)jsonObject {
    return [self jsonObjectWithFormatter:nil];
}

- (id<NSSecureCoding>)jsonObjectWithFormatter:(NSFormatter * _Nullable) formatter  {
    if ([formatter isKindOfClass:[NSNumberFormatter class]]) {
        return [(NSNumberFormatter *)formatter numberFromString:self];
    }
    else {
        return [self copy];
    }
}

- (NSNumber *)boolNumber {
    if ([self compare: @"no" options: NSCaseInsensitiveSearch] == NSOrderedSame ||
        [self compare: @"false" options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        return @(NO);
    }
    
    else if ([self compare: @"yes" options: NSCaseInsensitiveSearch] == NSOrderedSame ||
             [self compare: @"true" options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        return @(YES);
    }
    
    return nil;
}

- (NSNumber *)intNumber {
    NSInteger itemAsInt = [self integerValue];
    NSString *verificationString = [NSString stringWithFormat: @"%d", (int) itemAsInt];
    
    // Here, we use -isValidJSONObject: to make sure the int isn't
    // NaN or infinity.  According to the JSON rules, those will
    // break the serializer.
    if ([verificationString isEqualToString: self] && [NSJSONSerialization isValidJSONObject: @[verificationString]])
    {
        return @(itemAsInt);
    }
    
    return nil;
}

@end

@implementation NSNumber (SBAJSONObject)

- (id<NSSecureCoding>)jsonObject {
    return [self jsonObjectWithFormatter:nil];
}

- (id<NSSecureCoding>)jsonObjectWithFormatter:(NSFormatter * _Nullable) formatter  {
    if ([formatter isKindOfClass:[NSNumberFormatter class]]) {
        return [(NSNumberFormatter *)formatter stringFromNumber:self];
    }
    else {
        return [self copy];
    }
}

@end

@implementation NSNull (SBAJSONObject)

- (id<NSSecureCoding>)jsonObject {
    return self;
}

@end

@implementation NSDate (SBAJSONObject)

- (id<NSSecureCoding>)jsonObject {
    return [self jsonObjectWithFormatter:nil];
}

- (id<NSSecureCoding>)jsonObjectWithFormatter:(NSFormatter * _Nullable)formatter {
    if ([formatter isKindOfClass:[NSDateFormatter class]]) {
        return [(NSDateFormatter*)formatter stringFromDate:self];
    }
    else {
        return [self ISO8601String];
    }
}

@end

@implementation NSDateComponents (SBAJSONObject)

- (id<NSSecureCoding>)jsonObject {
    return [self jsonObjectWithFormatter:nil];
}

- (id<NSSecureCoding>)jsonObjectWithFormatter:(NSFormatter * _Nullable)formatter {
    
    NSDateFormatter *dateFormatter = [formatter isKindOfClass:[NSDateFormatter class]] ? (NSDateFormatter *)formatter : [self defaultFormatter];
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *date = [gregorianCalendar dateFromComponents:self];
    
    return [dateFormatter stringFromDate:date];
}

- (NSDateFormatter *)defaultFormatter {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    if ((self.year == 0) && (self.month == 0) && (self.day == 0)) {
        // If the year and month and day are not used, then return
        // Joda-parsible time if no year, month, day
        [formatter setDateFormat:@"HH:mm:ss"];
    }
    else {
        // Else, assume that the time of day is ignored and return
        // the relavent components to the year/month/day
        NSMutableString *formatString = [NSMutableString new];
        if (self.year != 0) {
            [formatString appendString:@"yyyy"];
        }
        if (self.month != 0) {
            if (formatString.length > 0) {
                [formatString appendString:@"-"];
            }
            [formatString appendString:@"MM"];
        }
        if (self.day != 0) {
            if (formatString.length > 0) {
                [formatString appendString:@"-"];
            }
            [formatString appendString:@"dd"];
        }
        
        [formatter setDateFormat:formatString];
    }
    
    return formatter;
}

@end

@implementation NSUUID (SBAJSONObject)

- (id<NSSecureCoding>)jsonObject {
    return self.UUIDString;
}

@end

id SBAJSONObjectForObject(id <NSObject> object) {
    if ([object conformsToProtocol:@protocol(SBAJSONObject) ]) {
        // If this is an objec that conforms to the jsonObject protocol then return that
        return [(id <SBAJSONObject>)object jsonObject];
    }
    else if ([object respondsToSelector:@selector(dictionaryRepresentation)]) {
        // Otherwise, if this has a dictionary representation then return that
        NSDictionary *dictionary = [(id)object dictionaryRepresentation];
        if ([NSJSONSerialization isValidJSONObject:dictionary]) {
            return dictionary;
        }
        else {
            return [dictionary jsonObject];
        }
    }
    else {
        // Finally, drop through to the description but throw an assert
        NSLog(@"jsonObject method not implemented for class %@", NSStringFromClass([object class]));
        assert(false);
        return [object description];
    }
}

@implementation NSArray (SBAJSONObject)

- (id<NSSecureCoding>)jsonObject {

    NSMutableArray *result = [NSMutableArray new];
    
    // Recursively convert objects to valid json objects
    for (id object in self) {
        [result addObject:SBAJSONObjectForObject(object)];
    }
    
    return [result copy];
}

@end

@implementation NSDictionary (SBAJSONObject)

- (id<NSSecureCoding>)jsonObject {

    NSMutableDictionary *result = [NSMutableDictionary new];
    
    // Recursively convert objects to valid json objects
    for (id keyObject in [self allKeys]) {

        // Get the string representation of the key and the object
        NSString *key = [keyObject description];
        id object = self[keyObject];
        
        // Set the value
        result[key] = SBAJSONObjectForObject(object);
    }
    
    return [result copy];
}

@end
