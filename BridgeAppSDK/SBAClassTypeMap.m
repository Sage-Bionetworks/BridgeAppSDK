//
//  SBAClassTypeMap.m
//  BridgeAppSDK
//
//  Created by Shannon Young on 4/5/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "SBAClassTypeMap.h"
#import "SBAJSONObject.h"
#import "SBABridgeAppSDKDelegate.h"

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