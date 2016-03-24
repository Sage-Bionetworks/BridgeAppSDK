//
//  SBAUserWrapper.h
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

#ifndef SBAUserWrapper_h
#define SBAUserWrapper_h

#import <BridgeSDK/BridgeSDK.h>
#import <ResearchKit/ResearchKit.h>

@protocol SBAConsentSignatureWrapper <NSObject, NSSecureCoding>

/**
 * Age verification stored with consent
 */
@property (nonatomic) NSDate * _Nullable signatureBirthdate;

/**
 * Name used to sign consent
 */
@property (nonatomic) NSString * _Nullable signatureName;

/**
 * UIImage representation of consent signature
 */
@property (nonatomic) UIImage * _Nullable signatureImage;

@end

@protocol SBAUserWrapper <NSObject>

/**
 * SessionToken is stored in memory only
 */
@property (nonatomic) NSString * _Nullable sessionToken;

/**
 * Name is stored in the keychain
 */
@property (nonatomic) NSString * _Nullable name;

/**
 * Email is stored in the keychain. Can be nil if user is registered using a userId rather
 * than via email.
 */
@property (nonatomic) NSString * _Nullable email;

/**
 * UserId is stored in the keychain. Returns either a unique identifier associated with
 * the current signed in account, or the hashed email.
 */
@property (nonatomic) NSString * _Nullable userId;

/**
 * Password is stored in the keychain
 */
@property (nonatomic) NSString * _Nullable password;

/**
 * Subpopulation GUID is used for tracking by certain apps. Stored in the keychain.
 */
@property (nonatomic) NSString * _Nullable subpopulationGuid;

/**
 * Consent signature should be stored in keychain.
 */
@property (nonatomic) id <SBAConsentSignatureWrapper> _Nullable consentSignature;

/**
 * Data groups associated with this user.
 */
@property (nonatomic) NSArray <NSString *> * _Nullable dataGroups;

/**
 * The user has registered locally or the server has returned confirmation that the 
 * user registered on a different device.
 */
@property (nonatomic) BOOL hasRegistered;   // signedUp

/**
 * User email/password login has been verified on the server.
 */
@property (nonatomic) BOOL loginVerified;   // signedIn

/**
 * The user's consent has been verified by the server.
 */
@property (nonatomic) BOOL consentVerified;

/**
 * The user has "paused" their participation in the study and their data should *not*
 * be sent to the server.
 */
@property (nonatomic) BOOL paused;

/**
 * The sharing scope set by the user during consent
 */
@property (nonatomic) SBBUserDataSharingScope dataSharingScope;

/**
 * Log the user out and reset
 */
- (void)logout;

@end

#endif /* SBAUserWrapper_h */
