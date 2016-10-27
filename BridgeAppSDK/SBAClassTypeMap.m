//
//  SBAClassTypeMap.m
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

#import "SBAClassTypeMap.h"
#import "SBAJSONObject.h"
#import <BridgeAppSDK/BridgeAppSDK-Swift.h>

static NSString * const kClassTypeMapPListName = @"ClassTypeMap";

@interface SBAClassTypeMap ()

@property (nonatomic) NSMutableDictionary *map;

@end

@implementation SBAClassTypeMap

+ (instancetype)sharedMap {
    static id _defaultInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultInstance = [[self alloc] init];
    });
    return _defaultInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        // Look in all the bundles that we know about
        [self addObjectsFromPList:[[NSBundle mainBundle] pathForResource:kClassTypeMapPListName ofType:@"plist"]];
        [self addObjectsFromPList:[[NSBundle bundleForClass:[self class]] pathForResource:kClassTypeMapPListName ofType:@"plist"]];
        id <SBABridgeAppSDKDelegate> appDelegate = (id <SBABridgeAppSDKDelegate>) [[UIApplication sharedApplication] delegate];
        if ([appDelegate conformsToProtocol:@protocol(SBABridgeAppSDKDelegate)]) {
            [self addObjectsFromPList:[appDelegate pathForResource:kClassTypeMapPListName ofType:@"plist"]];
            [self addObjectsFromPList:[[appDelegate resourceBundle] pathForResource:kClassTypeMapPListName ofType:@"plist"]];
        }
    }
    return self;
}

- (void)addObjectsFromPList:(NSString *)path {
    if (path == nil) return;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    if (dictionary == nil) return;
    
    if (_map == nil) {
        _map = [dictionary mutableCopy];
    }
    else {
        [_map addEntriesFromDictionary:dictionary];
    }
}

- (Class)classForClassType:(NSString *)classType {
    NSString *className = _map[classType] ?: classType;
    return NSClassFromString(className);
}

- (id)objectWithDictionaryRepresentation:(NSDictionary*)dictionary {
    NSString *classType = dictionary[@"classType"];
    if (![classType isKindOfClass:[NSString class]]) {
        return nil;
    }
    return [self objectWithDictionaryRepresentation:dictionary classType:classType];
}

- (id)objectWithDictionaryRepresentation:(NSDictionary*)dictionary classType:(NSString *)classType {
    id allocatedObject = [[self classForClassType:classType] alloc];
    if (![allocatedObject respondsToSelector:@selector(initWithDictionaryRepresentation:)]) {
        return nil;
    }
    return [allocatedObject initWithDictionaryRepresentation:dictionary];
}

- (id)objectWithIdentifier:(NSString*)identifier classType:(NSString *)classType {
    id allocatedObject = [[self classForClassType:classType] alloc];
    if (![allocatedObject respondsToSelector:@selector(initWithIdentifier:)]) {
        return nil;
    }
    return [allocatedObject initWithIdentifier:identifier];
}

@end
