//
//  SBABridgeManager.m
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

#import "SBABridgeManager.h"

@implementation SBABridgeManager

+ (void) setAuthDelegate:(id <SBBAuthManagerDelegateProtocol>) authDelegate {
    [SBBComponent(SBBAuthManager) setAuthDelegate:authDelegate];
}

+ (void)restoreBackgroundSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    [SBBComponent(SBBBridgeNetworkManager) restoreBackgroundSession:identifier completionHandler:completionHandler];
}

+ (void)signUp:(NSString *)email
      password:(NSString *)password
    externalId:(NSString *)externalId
    dataGroups:(NSArray<NSString *> *)dataGroups
    completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock {
    
    NSParameterAssert(email);
    NSParameterAssert(password);
    [SBBComponent(SBBAuthManager) signUpWithEmail: email
                                         username: externalId ?: email
                                         password: password
                                       dataGroups: dataGroups
                                       completion: ^(NSURLSessionTask * __unused task,
                                                     id responseObject,
                                                     NSError *error)
     {
         if (!error) {
             NSLog(@"User Signed Up");
         }
#if DEBUG
         else {
             NSLog(@"Error with signup: %@", error);
         }
#endif
         if (completionBlock) {
             completionBlock(responseObject, error);
         }
     }];
}

+ (void)signIn:(NSString *)email password:(NSString *)password completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock {
    
    NSParameterAssert(email);
    NSParameterAssert(password);
    [SBBComponent(SBBAuthManager) signInWithEmail: email
                                         password: password
                                       completion:^(NSURLSessionTask * __unused task,
                                                    id responseObject,
                                                    NSError *error) {
#if DEBUG
        if (error != nil) {
            NSLog(@"Error with signup: %@", error);
        }
#endif
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}

+ (void)sendUserConsented:(NSString *)name
                birthDate:(NSDate *)birthDate
             consentImage:(UIImage * _Nullable)consentImage
             sharingScope:(SBBUserDataSharingScope)sharingScope
        subpopulationGuid:(NSString *)subpopGuid
               completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock
{
    NSParameterAssert(name);
    NSParameterAssert(birthDate);
    NSParameterAssert(subpopGuid);
    [SBBComponent(SBBConsentManager) consentSignature:name
                                 forSubpopulationGuid:subpopGuid
                                            birthdate:birthDate
                                       signatureImage:consentImage
                                          dataSharing:sharingScope
                                           completion:^(id responseObject, NSError * error) {
#if DEBUG
                                               if (error != nil) {
                                                   NSLog(@"Error with sending user consent: %@", error);
                                               }
#endif
                                               if (completionBlock) {
                                                   completionBlock(responseObject, error);
                                               }
                                           }];
}


+ (void)ensureSignedInWithCompletion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock {
    
    [SBBComponent(SBBAuthManager) ensureSignedInWithCompletion:^(NSURLSessionTask * __unused task,
                                                                 id responseObject,
                                                                 NSError *error) {
#if DEBUG
        if (error != nil) {
            NSLog(@"Error with signup: %@", error);
        }
#endif
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}

+ (void) updateDataGroups:(NSArray<NSString *> *)dataGroups completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock
{
    SBBDataGroups *groups = [SBBDataGroups new];
    groups.dataGroups = [NSSet setWithArray:dataGroups];
    
    [SBBComponent(SBBUserManager) updateDataGroupsWithGroups:groups
                                                  completion: ^(id responseObject,
                                                                NSError *error) {
#if DEBUG
         if (error != nil) {
             NSLog(@"Error with updating data groups: %@", error);
         }
#endif
         if (completionBlock) {
             completionBlock(responseObject, error);
         }
     }];
}

+ (void)fetchChangesToScheduledActivities:(NSArray <SBBScheduledActivity *> *)scheduledActivities
                                daysAhead:(NSInteger)daysAhead
                               daysBehind:(NSInteger)daysBehind
                               completion:(SBABridgeManagerCompletionBlock)completionBlock
{
    // Intended design is to allow for the server to win in getting updates to the current list of scheduled
    // activities, but this will also *send* what is already known and may include a finishedOn date that is
    // more recent than what is available from the server. syoung 04/14/2016
    [SBBComponent(SBBActivityManager) getScheduledActivitiesForDaysAhead:daysAhead daysBehind:daysBehind cachingPolicy:SBBCachingPolicyFallBackToCached withCompletion:^(NSArray *activitiesList, NSError *error) {
        completionBlock(activitiesList, error);
    }];
}

+ (void)updateScheduledActivities:(NSArray <SBBScheduledActivity *> *)scheduledActivities completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock {
    [SBBComponent(SBBActivityManager) updateScheduledActivities:scheduledActivities withCompletion:^(id responseObject, NSError *error) {
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}

+ (void)requestPasswordResetForEmail:(NSString*)emailAddress completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock {
    [SBBComponent(SBBAuthManager) requestPasswordResetForEmail: emailAddress
                                                    completion: ^(NSURLSessionTask * __unused task,
                                                              id responseObject,
                                                              NSError *error) {
                                                        if (completionBlock) {
                                                            completionBlock(responseObject, error);
                                                        }
                                                    }];
}

+ (NSURLSessionTask *)loadSurvey:(SBBSurveyReference *)surveyReference completion:(SBABridgeManagerCompletionBlock)completionBlock {
    return [SBBComponent(SBBSurveyManager) getSurveyByRef:surveyReference.href completion:^(id survey, NSError *error) {
        completionBlock(survey, error);
    }];
}

@end
