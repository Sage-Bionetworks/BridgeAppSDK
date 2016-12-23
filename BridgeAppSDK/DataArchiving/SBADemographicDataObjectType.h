//
//  SBADemographicDataObjectType.h
//  BridgeAppSDK
//
// Copyright © 2016 Sage Bionetworks. All rights reserved.
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
#import <BridgeAppSDK/SBADefines.h>

// ===== WORK IN PROGRESS =====
// TODO: WIP syoung 12/06/2016 This is unfinished but b/c it is wrapped up with the profile
// and onboarding stuff, I don't want the branch lingering unmerged. This is ported from
// AppCore and is still untested and *not* intended for production use.
// ============================

NS_ASSUME_NONNULL_BEGIN

typedef NSString * SBADemographicDataIdentifier NS_EXTENSIBLE_STRING_ENUM;

ENUM_EXTERN SBADemographicDataIdentifier const SBADemographicDataIdentifierCurrentAge;
ENUM_EXTERN SBADemographicDataIdentifier const SBADemographicDataIdentifierBiologicalSex;
ENUM_EXTERN SBADemographicDataIdentifier const SBADemographicDataIdentifierHeightInches;
ENUM_EXTERN SBADemographicDataIdentifier const SBADemographicDataIdentifierWeightPounds;
ENUM_EXTERN SBADemographicDataIdentifier const SBADemographicDataIdentifierWakeUpTime;
ENUM_EXTERN SBADemographicDataIdentifier const SBADemographicDataIdentifierSleepTime;

@interface SBADemographicDataObjectType: NSObject

@property (nonatomic, copy, readonly) SBADemographicDataIdentifier identifier;
@property (nonatomic, readonly) id <NSSecureCoding> value;

- (instancetype)initWithIdentifier:(SBADemographicDataIdentifier)identifier value:(id<NSSecureCoding>)value NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
