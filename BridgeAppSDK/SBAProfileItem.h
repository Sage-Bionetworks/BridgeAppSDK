//
//  SBAProfileItem.h
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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
#import "SBADefines.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * SBAProfileTypeIdentifier NS_EXTENSIBLE_STRING_ENUM;

ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierString;
ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierNumber;
ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierBool;
ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierDate;
ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierHKBiologicalSex;
ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierHKQuantity;
ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierArray;
ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierSet;
ENUM_EXTERN SBAProfileTypeIdentifier const SBAProfileTypeIdentifierDictionary;

typedef NSString *SBAProfileSourceKey NS_EXTENSIBLE_STRING_ENUM;

ENUM_EXTERN SBAProfileSourceKey const SBAProfileSourceKeyGivenName;
ENUM_EXTERN SBAProfileSourceKey const SBAProfileSourceKeyFamilyName;
ENUM_EXTERN SBAProfileSourceKey const SBAProfileSourceKeyFullName;
ENUM_EXTERN SBAProfileSourceKey const SBAProfileSourceKeyPreferredName;


/**
 Implementation should manage adding and removing objects from the keychain.
 */
@protocol SBAKeychainWrapperProtocol <NSObject>

- (BOOL)setObject:(id<NSSecureCoding>)object forKey:(NSString *)key error:(NSError * _Nullable *)error;

- (id<NSSecureCoding>)objectForKey:(NSString *)key error:(NSError * _Nullable *)error;

- (BOOL)removeObjectForKey:(NSString *)key error:(NSError * _Nullable *)error;

- (BOOL)resetKeychainWithError:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
