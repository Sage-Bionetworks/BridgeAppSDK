//
//  MockBridgeInfo.h
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

@interface MockBridgeInfo : NSObject <SBABridgeInfo>

@property (nonatomic, readwrite, copy) NSString * _Null_unspecified studyIdentifier;
@property (nonatomic, readwrite) NSInteger cacheDaysAhead;
@property (nonatomic, readwrite) NSInteger cacheDaysBehind;
@property (nonatomic, readwrite) SBBEnvironment environment;
@property (nonatomic, readwrite, copy) NSString * _Nullable appStoreLinkURLString;
@property (nonatomic, readwrite, copy) NSString * _Nullable emailForLoginViaExternalId;
@property (nonatomic, readwrite, copy) NSString * _Nullable passwordFormatForLoginViaExternalId;
@property (nonatomic, readwrite, copy) NSString * _Nullable testUserDataGroup;
@property (nonatomic, readwrite, copy) NSArray<NSDictionary *> * _Nullable schemaMap;
@property (nonatomic, readwrite, copy) NSArray<NSDictionary *> * _Nullable taskMap;
@property (nonatomic, readwrite, copy) NSString * _Nullable certificateName;
@property (nonatomic, readwrite, copy) NSString * _Nullable news;
@property (nonatomic, readwrite, copy) NSString * _Nullable newsfeedURLString;
@property (nonatomic, readwrite, copy) NSString * _Nullable logoImageName;
@property (nonatomic, readwrite, copy) NSString * _Nullable appUpdateURLString;
@property (nonatomic, readwrite) BOOL disableTestUserCheck;
@property (nonatomic, readonly, copy) NSArray * _Nullable permissionTypeItems;
@property (nonatomic, readonly, copy) NSString * _Nullable keychainService;
@property (nonatomic, readonly, copy) NSString * _Nullable keychainAccessGroup;
@property (nonatomic, readonly, copy) NSString * _Nullable appGroupIdentifier;

@end
