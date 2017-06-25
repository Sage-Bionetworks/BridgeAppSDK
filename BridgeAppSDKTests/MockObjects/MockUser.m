//
//  MockUser.m
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

#import "MockUser.h"

@implementation MockUser

@synthesize sessionToken;
@synthesize name;
@synthesize email;
@synthesize externalId;
@synthesize password;
@synthesize subpopulationGuid;
@synthesize consentSignature;
@synthesize dataGroups;
@synthesize isRegistered;
@synthesize isLoginVerified;
@synthesize isConsentVerified;
@synthesize isDataSharingEnabled;
@synthesize isTestUser;
@synthesize dataSharingScope;
@synthesize onboardingStepIdentifier;
@synthesize gender;
@synthesize birthdate;
@synthesize profileImage;

- (instancetype)init {
    if (self = [super init]) {
        _mockBridgeInfo = [[MockBridgeInfo alloc] init];
        _storedAnswers = [NSMutableDictionary new];
        _createdOn = [NSDate date];
    }
    return self;
}

- (id <SBABridgeInfo>) bridgeInfo {
    return _mockBridgeInfo;
}

- (void)logout {
    _logout_called_count++;
}

- (nullable NSString *)sessionTokenForAuthManager:(nonnull id<SBBAuthManagerProtocol>)authManager {
    return self.sessionToken;
}

- (void)authManager:(id<SBBAuthManagerProtocol>)authManager didGetSessionToken:(NSString *)aSessionToken forEmail:(NSString *)aEmail andPassword:(NSString *)aPassword {
    _sessionToken_called_count++;
    self.email = aEmail;
    self.password = aPassword;
    self.sessionToken = aSessionToken;
}

- (void)authManager:(nullable id<SBBAuthManagerProtocol>)authManager didReceiveUserSessionInfo:(nullable id)sessionInfo {
    SBBUserSessionInfo *info = (SBBUserSessionInfo *)sessionInfo;
    if (![info isKindOfClass:[SBBUserSessionInfo class]]) {
        return;
    }
    //self.updateFromUserSessionInfo(info) <-- TODO emm 2017-06-20
    [SBAStudyParticipantProfileItem setStudyParticipant:info.studyParticipant];
    
    // the real SBAUser gets these from the StudyParticipant directly, it doesn't copy them to itself
    self.name = info.studyParticipant.firstName;
    self.familyName = info.studyParticipant.lastName;
}

- (NSString *)emailForAuthManager:(id<SBBAuthManagerProtocol>)authManager {
    return self.email;
}

- (NSString *)passwordForAuthManager:(id<SBBAuthManagerProtocol>)authManager {
    return self.password;
}

- (void)resetStoredUserData {
    self.sessionToken = nil;
    self.name = nil;
    self.email = nil;
    self.externalId = nil;
    self.password = nil;
    self.subpopulationGuid = nil;
    self.consentSignature = nil;
    self.profileImage = nil;
    self.dataGroups = nil;
    self.isRegistered = NO;
    self.isLoginVerified = NO;
    self.isConsentVerified = NO;
    self.isDataSharingEnabled = NO;
    self.dataSharingScope = 0;
    self.onboardingStepIdentifier = nil;
    self.gender = 0;
    self.birthdate = nil;
    self.createdOn = [NSDate date];
}
    
- (void)setStoredAnswer:(id)storedAnswer forKey:(NSString *)key {
    [self setValue:storedAnswer forKey:key];
}
    
- (id)storedAnswerForKey:(NSString *)key {
    return [self valueForKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key {
    return _storedAnswers[key];
}
    
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if (value) {
        _storedAnswers[key] = value;
    }
    else {
        [_storedAnswers removeObjectForKey:key];
    }
}
   

@end
