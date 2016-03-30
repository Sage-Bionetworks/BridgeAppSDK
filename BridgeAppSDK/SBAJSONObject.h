//
//  SBAJSONObject.h
//  BridgeAppSDK
//
//  Created by Shannon Young on 4/4/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BridgeSDK/BridgeSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SBAJSONObject <NSObject>

- (id)jsonObjectWithFormatter:(NSFormatter * _Nullable)formatter;

@end

@protocol SBAJSONDictionaryRepresentableObject <NSObject>

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

@end

@interface NSArray (SBAJSONObject)

- (id)jsonObjectWithFormatterMap:(NSDictionary <NSString *, NSFormatter *> * _Nullable)formatterMap;

@end

@interface NSDictionary (SBAJSONObject)

- (id)jsonObjectWithFormatterMap:(NSDictionary <NSString *, NSFormatter *> * _Nullable)formatterMap;

@end

@interface NSString (SBAJSONObject) <SBAJSONObject>

- (NSNumber * _Nullable)boolNumber;
- (NSNumber * _Nullable)intNumber;

@end

@interface NSNumber (SBAJSONObject) <SBAJSONObject>
@end

@interface NSNull (SBAJSONObject) <SBAJSONObject>
@end

@interface NSDate (SBAJSONObject) <SBAJSONObject>
@end

@interface NSDateComponents (SBAJSONObject) <SBAJSONObject>
@end

NS_ASSUME_NONNULL_END
