//
//  SBADataObject.m
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

#import "SBADataObject.h"

@interface SBADataObject ()

@property (nonatomic, copy, readwrite) NSString * classType;

@end

@implementation SBADataObject

- (instancetype)init {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: @"method unavailable"
                                 userInfo: nil];
    return nil;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    if ((self = [super init])) {
        NSParameterAssert(identifier);
        _identifier = [identifier copy];
    }
    return self;
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)dictionary {
    if ((self = [super init])) {
        [self commonInitWithDictionaryRepresentation:dictionary];
    }
    return self;
}

- (void)commonInitWithDictionaryRepresentation:(NSDictionary *)dictionary {
    for (NSString *key in [self dictionaryRepresentationKeys]) {
        id value = dictionary[key];
        if (value && ![value isKindOfClass:[NSNull class]]) {
            [self setValue:value forKey:key];
        }
    }
    if (_identifier == nil) {
        _identifier = [self defaultIdentifierIfNil];
    }

}

- (void)setValue:(id)value forKey:(NSString *)key {
    [super setValue:[self mapValue:value forKey:key withClassType:nil]
             forKey:key];
}

- (id)mapValue:(id)value forKey:(NSString *)key withClassType:(NSString *)classType {
    if ([value isKindOfClass:[NSDictionary class]]) {
        return [self objectWithDictionaryRepresentation:(NSDictionary*)value classType:classType];
    }
    else if ([value isKindOfClass:[NSArray class]] && [[value firstObject] isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *mappedValues = [NSMutableArray new];
        for (id obj in (NSArray*)value) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                [mappedValues addObject:[self objectWithDictionaryRepresentation:(NSDictionary*)obj classType:classType]];
            }
            else {
                [mappedValues addObject:obj];
            }
        }
        if ([value isKindOfClass:[NSMutableArray class]]) {
            return mappedValues;
        }
        else {
            return [mappedValues copy];
        }
    }
    return value;
}

- (id)objectWithDictionaryRepresentation:(NSDictionary*)dictionary classType:(NSString*)aClassType {
    
    // SBBObjects use type for the class type so check both the property key for this class and the SBBObject property key
    NSString *classType = aClassType ?: dictionary[[[self class] classTypeKey]] ?: dictionary[@"type"];
    if (classType == nil) {
        return dictionary;
    }
    
    // Look to see if the class type map can map this dictionary to an object type
    id mappedValue = [[SBAClassTypeMap sharedMap] objectWithDictionaryRepresentation:dictionary classType:classType];
    if (mappedValue == nil) {
        return dictionary;
    }
    
    return mappedValue;
}

- (NSString *)classType {
    if (_classType == nil) {
        _classType = [[self class] classType];
    }
    return _classType;
}

+ (NSString *)classType {
    return NSStringFromClass([self classForCoder]);
}

+ (NSString *)classTypeKey {
    return NSStringFromSelector(@selector(classType));
}

- (NSString *)defaultIdentifierIfNil {
    return [[NSUUID UUID] UUIDString];
}

- (NSArray <NSString *> *)dictionaryRepresentationKeys {
    return @[NSStringFromSelector(@selector(identifier)),
             [[self class] classTypeKey]];
}

- (NSDictionary *)dictionaryRepresentation {
    return [self dictionaryWithValuesForKeys:[self dictionaryRepresentationKeys]];
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithIdentifier:self.identifier];
    
    for (NSString *key in [self dictionaryRepresentationKeys]) {
        id object = [self valueForKey:key];
        if (object && ![object isKindOfClass:[NSNull class]]) {
            if ([object conformsToProtocol:@protocol(NSCopying)]) {
                [copy setValue:[object copyWithZone:zone] forKey:key];
            }
            else {
                [copy setValue:object forKey:key];
            }
        }
    }
    
    return copy;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        NSDictionary *dictionary = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"dictionary"];
        [self commonInitWithDictionaryRepresentation:dictionary];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self dictionaryRepresentation] forKey:@"dictionary"];
}

- (NSUInteger)hash {
    return [[self dictionaryRepresentation] hash];
}

- (BOOL)isEqual:(id)object {
    return [self isKindOfClass:[object class]] && [[self dictionaryRepresentation] isEqualToDictionary:[object dictionaryRepresentation]];
}

@end
