//
//  SBABridgeManager.h
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

@import Foundation;
@import BridgeSDK;

NS_ASSUME_NONNULL_BEGIN

/*!
 *  Typedef for SBBNetworkManager data methods' completion block.
 *
 *  @param task           The NSURLSessionDataTask.
 *  @param responseObject The JSON object from the response, if any.
 *  @param error          Any error that occurred.
 */
typedef void (^SBABridgeManagerCompletionBlock)(id _Nullable responseObject, NSError * _Nullable error);

@interface SBABridgeManager : NSObject

+ (void)setAuthDelegate:(id <SBBAuthManagerDelegateProtocol>) authDelegate;

+ (void)restoreBackgroundSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

+ (void)signUp:(NSString *)email
      password:(NSString *)password
    externalId:(NSString * _Nullable)externalId
    dataGroups:(NSArray<NSString *> * _Nullable)dataGroups
    completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

+ (void)signIn:(NSString *)username
      password:(NSString *)password
    completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

+ (void)sendUserConsented:(NSString *)name
                birthDate:(NSDate *)birthDate
             consentImage:(UIImage * _Nullable)consentImage
             sharingScope:(SBBUserDataSharingScope)sharingScope
        subpopulationGuid:(NSString *)subpopGuid
               completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

+ (void)ensureSignedInWithCompletion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

+ (void)updateDataGroups:(NSArray<NSString *> *)dataGroups
              completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

+ (void)fetchChangesToScheduledActivities:(NSArray <SBBScheduledActivity *> *)scheduledActivities
                                daysAhead:(NSInteger)daysAhead
                               daysBehind:(NSInteger)daysBehind
                               completion:(SBABridgeManagerCompletionBlock)completionBlock;

+ (void)updateScheduledActivities:(NSArray <SBBScheduledActivity *> *)scheduledActivities
                       completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

+ (void)requestPasswordResetForEmail:(NSString*)emailAddress
                          completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

+ (void)resendEmailVerification:(NSString*)emailAddress
                     completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;
    
+ (void)withdrawConsentForSubpopulation:(NSString *)subpopGuid
                                 reason:(NSString * _Nullable)reason
                             completion:(SBABridgeManagerCompletionBlock)completionBlock;
    
+ (void)updateDataSharingScope:(SBBUserDataSharingScope)scope
                    completion:(SBABridgeManagerCompletionBlock)completionBlock;
    
+ (void)getUserProfileWithCompletion:(SBABridgeManagerCompletionBlock)completionBlock;
    
+ (void)updateUserProfile:(id)profile completion:(SBABridgeManagerCompletionBlock)completionBlock;

+ (NSURLSessionTask *)loadSurvey:(SBBSurveyReference *)surveyReference completion:(SBABridgeManagerCompletionBlock)completionBlock;
    

@end

NS_ASSUME_NONNULL_END
