//
//  SBAClassTypeMap.h
//  BridgeAppSDK
//
//  Created by Shannon Young on 4/5/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SBAObjectWithIdentifier <NSObject>

- (id)initWithIdentifier:(NSString *)identifier;

@end

@interface SBAClassTypeMap : NSObject

+ (instancetype)sharedMap;

- (Class _Nullable)classForClassType:(NSString *)classType;

- (id _Nullable)objectWithDictionaryRepresentation:(NSDictionary*)dictionary classType:(NSString *)classType;
- (id _Nullable)objectWithIdentifier:(NSString*)identifier classType:(NSString *)classType;

@end

NS_ASSUME_NONNULL_END