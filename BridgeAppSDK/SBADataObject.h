//
//  SBADataObject.h
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

#import <Foundation/Foundation.h>
#import "SBAJSONObject.h"
#import "SBAClassTypeMap.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBADataObject : NSObject <NSSecureCoding, NSCopying, SBAJSONDictionaryRepresentableObject>

/**
 * Unique identifier for this object
 */
@property (nonatomic, copy) NSString * identifier;

/**
 * Class type to use for this object. By default, this method returns classType for the class method.
 */
@property (nonatomic, copy, readonly) NSString * classType;

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a new data object initialized with the specified identifier.
 
 @param identifier   The unique identifier
 
 @return A new data object.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

/**
 Returns a new data object initialized with the specified dictionary representation.
 
 @param dictionary   The dictionary representation
 
 @return A new data object.
 */
- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/**
 Returns a new data object initialized with the specified dictionary representation.
 
 @param aDecoder    Coder from which to initialize.
 
 @return A new data object.
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 * Mapping name for the type of object class. By Default, this is the coderForClass.
 */
+ (NSString *)classType;

/**
 * String for the class type key for the dictionary representation of this object. By default, returns "classType".
 */
+ (NSString *)classTypeKey;

/**
 * Overrideable method for mapping a setter to a different class type
 */
- (id _Nullable)mapValue:(id _Nullable)value forKey:(NSString *)key withClassType:(NSString * _Nullable)classType;

/**
 * Dictionary representation for this data object
 */
- (NSDictionary *)dictionaryRepresentation;

#pragma mark - Subclasses should override the following methods and provide implementation

/**
 * Identifier to assign to this object if the dictionaryRepresentation does not include one.
 * Default = UUID generated
 */
- (NSString *)defaultIdentifierIfNil;

/**
 * Keys used to represent this dictionary item.
 */
- (NSArray <NSString *> *)dictionaryRepresentationKeys;

@end

NS_ASSUME_NONNULL_END
