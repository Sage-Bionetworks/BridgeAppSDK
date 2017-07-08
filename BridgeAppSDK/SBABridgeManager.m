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
#import <BridgeAppSDK/BridgeAppSDK-Swift.h>
@import ResearchUXFactory;

@implementation SBABridgeManager

+ (void)addResourceBundleIfNeeded {
    // Add this bundle to the resource bundles
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBAInfoManager *infoManager = [SBAInfoManager sharedManager];
        NSMutableArray *bundles = [infoManager.resourceBundles mutableCopy];
        NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
        if (![bundles containsObject:thisBundle]) {
            NSUInteger idx = bundles.count > 0 ? 1 : 0;
            [bundles insertObject:thisBundle atIndex:idx];
            infoManager.resourceBundles = bundles;
        }
    });
}

+ (void)setupWithBridgeInfo:(id <SBBBridgeInfoProtocol>)bridgeInfo
                participant:(id <SBAParticipantInfo>)participant
               authDelegate:(id <SBBAuthManagerDelegateProtocol>) authDelegate {
    
    // Add the resource bundle (if needed)
    [self addResourceBundleIfNeeded];
    
    // Set the participant
    [SBAInfoManager sharedManager].currentParticipant = participant;
    
    // Setup the Bridge study
    [BridgeSDK setupWithBridgeInfo:bridgeInfo];
    [BridgeSDK setAuthDelegate:authDelegate];
}

+ (void)setupWithStudy:(NSString *)study
        cacheDaysAhead:(NSInteger)cacheDaysAhead
       cacheDaysBehind:(NSInteger)cacheDaysBehind
           environment:(SBBEnvironment)environment
          authDelegate:(id <SBBAuthManagerDelegateProtocol>) authDelegate {
    
    [self addResourceBundleIfNeeded];
    
    // If the auth delegate is also the current user then set that
    if ([authDelegate conformsToProtocol:@protocol(SBAParticipantInfo)]) {
        [SBAInfoManager sharedManager].currentParticipant = (id <SBAParticipantInfo>)authDelegate;
    }
    
    // Finally setup bridge
    [BridgeSDK setupWithStudy:study cacheDaysAhead:cacheDaysAhead cacheDaysBehind:cacheDaysBehind environment:environment];
    [SBBComponent(SBBAuthManager) setAuthDelegate:authDelegate];
}

+ (void)setAuthDelegate:(id <SBBAuthManagerDelegateProtocol>) authDelegate {
    [SBBComponent(SBBAuthManager) setAuthDelegate:authDelegate];
}

+ (void)resetUserSessionInfo
{
    [SBBComponent(SBBAuthManager) resetUserSessionInfo];
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
    
    SBBSignUp *signup = [[SBBSignUp alloc] init];
    signup.email = email;
    signup.password = password;
    signup.externalId = externalId;
    if (dataGroups != nil) {
        signup.dataGroups = [NSSet setWithArray:dataGroups];
    }
    
    [self signUp:signup completion:completionBlock];
}

+ (void)signUp:(SBBSignUp *)signup
    completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock {
    
    [SBBComponent(SBBAuthManager) signUpStudyParticipant:signup
                                              completion: ^(NSURLSessionTask * __unused task,
                                                            id responseObject,
                                                            NSError *error) {
#if DEBUG
         if (!error) {
             NSLog(@"User Signed Up");
         }
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
             sharingScope:(SBBParticipantDataSharingScope)sharingScope
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
    [SBBComponent(SBBParticipantManager) updateDataGroupsWithGroups:[NSSet setWithArray:dataGroups]
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

+ (void)setExternalIdentifier:(NSString *)externalID completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock {
    [SBBComponent(SBBParticipantManager) setExternalIdentifier:externalID completion:^(id  _Nullable responseObject, NSError * _Nullable error) {
#if DEBUG
        if (error != nil) {
            NSLog(@"Error with setting the external identifier: %@", error);
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

+ (void)fetchScheduledActivitiesFrom:(NSDate *)scheduledFrom to:(NSDate *)scheduledTo
                          completion:(SBABridgeManagerCompletionBlock)completionBlock {
    // make sure the dates are in ascending order
    NSDate *startTime = scheduledFrom;
    NSDate *endTime = scheduledTo;
    NSComparisonResult order = [scheduledFrom compare:scheduledTo];
    if (order == NSOrderedDescending) {
        startTime = scheduledTo;
        endTime = scheduledFrom;
    }
    
    // pin the startTime and endTime to be no earlier than the start of the day the participant joined the study
    NSDate *participantStartDate = SBAAppDelegate.shared.currentUser.createdOn;
    NSDate *earliestDate = [[NSCalendar currentCalendar] startOfDayForDate:participantStartDate];
    startTime = ([startTime compare:earliestDate] == NSOrderedAscending) ? earliestDate : startTime;
    endTime = ([endTime compare:earliestDate] == NSOrderedAscending) ? earliestDate : endTime;
    
    [SBBComponent(SBBActivityManager) getScheduledActivitiesFrom:startTime to:endTime cachingPolicy:SBBCachingPolicyFallBackToCached withCompletion:^(NSArray * _Nullable activitiesList, NSError * _Nullable error) {
        completionBlock(activitiesList, error);
    }];
}

+ (void)fetchAllCachedScheduledActivitiesWithCompletion:(SBABridgeManagerCompletionBlock)completionBlock {
    [SBBComponent(SBBActivityManager) getScheduledActivitiesFrom:NSDate.distantPast to:NSDate.distantFuture cachingPolicy:SBBCachingPolicyCachedOnly withCompletion:^(NSArray * _Nullable activitiesList, NSError * _Nullable error) {
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

+ (void)resendEmailVerification:(NSString*)emailAddress
                     completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock{
    [SBBComponent(SBBAuthManager) resendEmailVerification:emailAddress completion:^(NSURLSessionTask *task, id responseObject, NSError *error) {
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}

+ (void)forgotPassword:(NSString*)emailAddress
            completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock{
    [SBBComponent(SBBAuthManager) requestPasswordResetForEmail:emailAddress completion:^(NSURLSessionTask *task, id responseObject, NSError *error) {
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}

+ (NSURLSessionTask *)loadSurvey:(SBBSurveyReference *)surveyReference completion:(SBABridgeManagerCompletionBlock)completionBlock {
    return [SBBComponent(SBBSurveyManager) getSurveyByRef:surveyReference.href
                                               completion:^(id survey, NSError *error) {
        completionBlock(survey, error);
    }];
}
    
+ (void)withdrawConsentForSubpopulation:(NSString *)subpopGuid reason:(NSString * _Nullable)reason completion:(SBABridgeManagerCompletionBlock)completionBlock {
    [SBBComponent(SBBConsentManager) withdrawConsentForSubpopulation:subpopGuid withReason:reason completion:^(id responseObject, NSError *error) {
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}

+ (void)getParticipantRecordWithCompletion:(SBABridgeManagerCompletionBlock)completionBlock {
    [SBBComponent(SBBParticipantManager) getParticipantRecordWithCompletion:^(id  _Nullable studyParticipant, NSError * _Nullable error) {
        if (completionBlock) {
            completionBlock(studyParticipant, error);
        }
    }];
}

+ (void)updateParticipantRecord:(id)participant completion:(SBABridgeManagerCompletionBlock)completionBlock {
    [SBBComponent(SBBParticipantManager) updateParticipantRecordWithRecord:participant completion:^(id  _Nullable responseObject, NSError * _Nullable error) {
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}
    
+ (void)updateDataSharingScope:(SBBParticipantDataSharingScope)scope
                    completion:(SBABridgeManagerCompletionBlock)completionBlock {
    [SBBComponent(SBBParticipantManager) setSharingScope:scope completion:^(id responseObject, NSError *error) {
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}
    
+ (void)getUserProfileWithCompletion:(SBABridgeManagerCompletionBlock)completionBlock {
    [SBBComponent(SBBUserManager) getUserProfileWithCompletion:^(id responseObject, NSError *error) {
        if (completionBlock) {
            completionBlock(responseObject, error);
        }
    }];
}
    
+ (void)updateUserProfile:(id)profile completion:(SBABridgeManagerCompletionBlock)completionBlock {
    [SBBComponent(SBBUserManager) updateUserProfileWithProfile: profile
                                                    completion: ^(id responseObject, NSError *error) {
         if (completionBlock) {
             completionBlock(responseObject, error);
         }
     }];
}

@end
