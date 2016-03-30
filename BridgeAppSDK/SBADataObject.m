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
    [NSException exceptionWithName: NSInternalInconsistencyException
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
        [self setValuesForKeysWithDictionary:dictionary];
        if (_identifier == nil) {
            _identifier = [self defaultIdentifierIfNil];
        }
    }
    return self;
}

- (NSString *)classType {
    if (_classType == nil) {
        _classType = [self classType];
    }
    return _classType;
}

+ (NSString *)classType {
    return NSStringFromClass([self classForCoder]);
}

- (NSString *)defaultIdentifierIfNil {
    return [[NSUUID UUID] UUIDString];
}

- (NSArray <NSString *> *)dictionaryRepresentationKeys {
    return @[NSStringFromSelector(@selector(identifier)),
             NSStringFromSelector(@selector(classType))];
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
    NSDictionary *dictionary = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"dictionary"];
    return [self initWithDictionaryRepresentation:dictionary];
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
