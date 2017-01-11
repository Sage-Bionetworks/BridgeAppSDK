//
//  MockUser.h
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
@import BridgeAppSDK;
@import BridgeSDK;

#import "MockBridgeInfo.h"

@interface MockUser : NSObject <SBAUserWrapper>

@property (nonatomic, readonly, strong) MockBridgeInfo * _Nonnull mockBridgeInfo;

@property (nonatomic, copy) NSString * _Nullable sessionToken;
@property (nonatomic, copy) NSString * _Nullable name;
@property (nonatomic, copy) NSString * _Nullable familyName;
@property (nonatomic, copy) NSString * _Nullable email;
@property (nonatomic, copy) NSString * _Nullable externalId;
@property (nonatomic, copy) NSString * _Nullable password;
@property (nonatomic, copy) NSString * _Nullable subpopulationGuid;
@property (nonatomic) HKBiologicalSex gender;
@property (nonatomic, copy) NSDate * _Nullable birthdate;
@property (nonatomic, strong) id <SBAConsentSignatureWrapper> _Nullable consentSignature;
@property (nonatomic, strong) UIImage * _Nullable profileImage;
@property (nonatomic, copy) NSArray<NSString *> * _Nullable dataGroups;
@property (nonatomic) BOOL isRegistered;
@property (nonatomic) BOOL isLoginVerified;
@property (nonatomic) BOOL isConsentVerified;
@property (nonatomic) BOOL isDataSharingEnabled;
@property (nonatomic) SBBParticipantDataSharingScope dataSharingScope;
@property (nonatomic, copy) NSString * _Nullable onboardingStepIdentifier;

@property (nonatomic, readonly) NSUInteger logout_called_count;

@end
