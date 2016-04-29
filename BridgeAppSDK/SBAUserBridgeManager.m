//
//  SBAUserBridgeManager.m
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

#import "SBAUserBridgeManager.h"

@implementation SBAUserBridgeManager

+ (void) setAuthDelegate:(id <SBBAuthManagerDelegateProtocol>) authDelegate {
    [SBBComponent(SBBAuthManager) setAuthDelegate:authDelegate];
}

+ (void)signUp:(NSString *)email
      password:(NSString *)password
    externalId:(NSString *)externalId
    dataGroups:(NSArray<NSString *> *)dataGroups
    completion:(SBAUserBridgeManagerCompletionBlock _Nullable)completionBlock {
    
    NSParameterAssert(email);
    NSParameterAssert(password);
    [SBBComponent(SBBAuthManager) signUpWithEmail: email
                                         username: externalId ?: email
                                         password: password
                                       dataGroups: dataGroups
                                       completion: ^(NSURLSessionDataTask * __unused task,
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

+ (void)signIn:(NSString *)email password:(NSString *)password completion:(SBAUserBridgeManagerCompletionBlock _Nullable)completionBlock {
    
    NSParameterAssert(email);
    NSParameterAssert(password);
    [SBBComponent(SBBAuthManager) signInWithEmail: email
                                         password: password
                                       completion:^(NSURLSessionDataTask * __unused task,
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
               completion:(SBAUserBridgeManagerCompletionBlock _Nullable)completionBlock
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


+ (void)ensureSignedInWithCompletion:(SBAUserBridgeManagerCompletionBlock _Nullable)completionBlock {
    
    [SBBComponent(SBBAuthManager) ensureSignedInWithCompletion:^(NSURLSessionDataTask * __unused task,
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

+ (void) updateDataGroups:(NSArray<NSString *> *)dataGroups completion:(SBAUserBridgeManagerCompletionBlock _Nullable)completionBlock
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
                                todayOnly:(BOOL)todayOnly
                               completion:(SBAUserBridgeManagerCompletionBlock)completionBlock
{
    // Intended design is to allow for the server to win in getting updates to the current list of scheduled
    // activities, but this will also *send* what is already known and may include a finishedOn date that is
    // more recent than what is available from the server. syoung 04/14/2016
    NSInteger daysBehind = todayOnly ? 0 : 1;
    // Always get max daysAhead (4) so we can update local notifications, and then filter to today if necessary.
    UIApplication *app = [UIApplication sharedApplication];
    [SBBComponent(SBBActivityManager) getScheduledActivitiesForDaysAhead:4 daysBehind:daysBehind cachingPolicy:SBBCachingPolicyFallBackToCached withCompletion:^(NSArray *activitiesList, NSError *error) {
        [app cancelAllLocalNotifications];
        // TODO: emm 2016-04-29 move notification handling into a Swift function that checks permission,
        // allows other schedules/patterns à la mPower, handles localization, etc.
        for (SBBScheduledActivity *sa in activitiesList) {
            UILocalNotification *notif = [UILocalNotification new];
            notif.fireDate = sa.scheduledOn;
            notif.soundName = UILocalNotificationDefaultSoundName;
            // TODO: emm 2016-04-28 make this localizable
            notif.alertBody = [NSString stringWithFormat:@"Time for %@", sa.activity.label];
            [app scheduleLocalNotification:notif];
        }
        if (todayOnly) {
            NSDate *tomorrow = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K < %@",
                                      NSStringFromSelector(@selector(scheduledOn)),
                                      [[NSCalendar currentCalendar] startOfDayForDate:tomorrow]];
            activitiesList = [activitiesList filteredArrayUsingPredicate:predicate];
        }
        completionBlock(activitiesList, error);
    }];
}

+ (void)updateScheduledActivity:(SBBScheduledActivity *)scheduledActivity {
    [SBBComponent(SBBActivityManager) updateScheduledActivities:@[scheduledActivity] withCompletion:nil];
}

@end
