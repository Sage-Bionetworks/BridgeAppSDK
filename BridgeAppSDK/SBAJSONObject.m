//
//  SBAJSONObject.m
//  BridgeAppSDK
//
//  Created by Shannon Young on 4/4/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "SBAJSONObject.h"


/**
 Sage requires our dates to be in "ISO 8601" format,
 like this:
 
 2015-02-25T16:42:11+00:00
 
 Got the rules from http://en.wikipedia.org/wiki/ISO_8601
 Date-formatting rules from http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
 */
static NSString * const kDateFormatISO8601 = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

@implementation NSString (SBAJSONObject)

- (id)jsonObjectWithFormatter:(NSFormatter * _Nullable) formatter  {
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

- (id)jsonObjectWithFormatter:(NSFormatter * _Nullable) formatter  {
    if ([formatter isKindOfClass:[NSNumberFormatter class]]) {
        return [(NSNumberFormatter *)formatter stringFromNumber:self];
    }
    else {
        return [self copy];
    }
}

@end

@implementation NSNull (SBAJSONObject)

- (id)jsonObjectWithFormatter:(NSFormatter * _Nullable) __unused formatter  {
    return self;
}

@end

@implementation NSDate (SBAJSONObject)

- (id)jsonObjectWithFormatter:(NSFormatter * _Nullable)formatter {
    NSDateFormatter *dateFormatter = [formatter isKindOfClass:[NSDateFormatter class]] ? (NSDateFormatter *)formatter : [self defaultFormatter];
    return [dateFormatter stringFromDate:self];
}

- (NSDateFormatter *)defaultFormatter {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat: kDateFormatISO8601];
    
    /*
     Set the formatter's locale.  Otherwise, the result will
     come out in the user's local language, not in English; and
     we wanna be able to generate it in English, since that's
     how Sage is expecting it.  For the reason to set the POSIX
     locale ("en_US_POSIX"), instead of the simpler "en-US",
     see:  http://blog.gregfiumara.com/archives/245
     */
    [formatter setLocale: [[NSLocale alloc] initWithLocaleIdentifier: @"en_US_POSIX"]];
    
    return formatter;
}

@end

@implementation NSDateComponents (SBAJSONObject)

- (id)jsonObject {
    return [self jsonObjectWithFormatter:nil];
}

- (id)jsonObjectWithFormatter:(NSFormatter * _Nullable)formatter {
    
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

- (id)jsonObjectWithFormatter:(NSFormatter * _Nullable) __unused formatter  {
    return self.UUIDString;
}

@end

id sba_JSONObjectForObject(id object, NSString * key, NSDictionary <NSString *, NSFormatter *> *formatterMap) {
    if ([object respondsToSelector:@selector(jsonObjectWithFormatterMap:)]) {
        return [object jsonObjectWithFormatterMap:formatterMap];
    }
    else if ([object respondsToSelector:@selector(dictionaryRepresentation)]) {
        NSDictionary *dictionary = [object dictionaryRepresentation];
        if ([NSJSONSerialization isValidJSONObject:dictionary]) {
            return dictionary;
        }
        else {
            return [dictionary jsonObjectWithFormatterMap:formatterMap];
        }
    }
    else if ([object respondsToSelector:@selector(jsonObjectWithFormatter:)]) {
        return [object jsonObjectWithFormatter:formatterMap[key]];
    }
    else {
        return [object description];
    }
}

@implementation NSArray (SBAJSONObject)

- (id)jsonObjectWithFormatterMap:(NSDictionary <NSString *, NSFormatter *> * _Nullable)formatterMap {
    
    NSMutableArray *result = [NSMutableArray new];
    
    // Recursively convert objects to valid json objects
    for (id object in self) {
        [result addObject:sba_JSONObjectForObject(object, nil, formatterMap)];
    }
    
    return [result copy];
}

@end

@implementation NSDictionary (SBAJSONObject)

- (id)jsonObjectWithFormatterMap:(NSDictionary <NSString *, NSFormatter *> * _Nullable)formatterMap {
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    // Recursively convert objects to valid json objects
    for (id keyObject in [self allKeys]) {

        // Get the string representation of the key and the object
        NSString *key = [keyObject description];
        id object = self[keyObject];
        
        // Set the value
        result[key] = sba_JSONObjectForObject(object, key, formatterMap);
    }
    
    return [result copy];
}

@end