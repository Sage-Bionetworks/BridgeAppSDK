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
    // TODO: syoung 04/14/2016 - Erin Mounts: please replace stubbed out implement
    
    // Intended design is to allow for the server to win in getting updates to the current list of scheduled
    // activities, but this will also *send* what is already known and may include a finishedOn date that is
    // more recent than what is available from the server. syoung 04/14/2016
    
    id responseObject = scheduledActivities;
    if (scheduledActivities.count == 0) {
    
        // Add in training
        SBBScheduledActivity *training = [[SBBScheduledActivity alloc] init];
        training.scheduledOn = [NSDate date];
        training.guid = [NSUUID UUID].UUIDString;
        training.activity = [[SBBActivity alloc] init];
        training.activity.label = @"Training Session";
        training.activity.labelDetail = @"15 minutes";
        training.activity.task = [[SBBTaskReference alloc] init];
        training.activity.task.identifier = @"1-Combo-295f81EF-13CB-4DB4-8223-10A173AA0780";
    
        // Add in medication tracker task
        SBBScheduledActivity *medTracking = [[SBBScheduledActivity alloc] init];
        medTracking.scheduledOn = [NSDate date];
        medTracking.guid = [NSUUID UUID].UUIDString;
        medTracking.activity = [[SBBActivity alloc] init];
        medTracking.activity.label = @"Medication Tracker";
        medTracking.activity.labelDetail = @"5 minutes";
        medTracking.activity.task = [[SBBTaskReference alloc] init];
        medTracking.activity.task.identifier = @"1-MedicationTracker-20EF8ED2-E461-4C20-9024-F43FCAAAF4C3";
        
        // Add in session 1
        SBBScheduledActivity *activity1 = [[SBBScheduledActivity alloc] init];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
        NSDate *tomorrow = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
        activity1.scheduledOn = [calendar dateBySettingHour:10 minute:0 second:0 ofDate:tomorrow options:0];
        activity1.guid = [NSUUID UUID].UUIDString;
        activity1.activity = [[SBBActivity alloc] init];
        activity1.activity.label = @"Activity Session 1";
        activity1.activity.labelDetail = @"15 minutes";
        activity1.activity.task = [[SBBTaskReference alloc] init];
        activity1.activity.task.identifier = @"1-Combo-295f81EF-13CB-4DB4-8223-10A173AA0780";
        
        // Add in session 2
        SBBScheduledActivity *activity2 = [[SBBScheduledActivity alloc] init];
        activity2.scheduledOn = [activity1.scheduledOn dateByAddingTimeInterval:2*60*60];
        activity2.guid = [NSUUID UUID].UUIDString;
        activity2.activity = [[SBBActivity alloc] init];
        activity2.activity.label = @"Activity Session 2";
        activity2.activity.labelDetail = @"15 minutes";
        activity2.activity.task = [[SBBTaskReference alloc] init];
        activity2.activity.task.identifier = @"1-Combo-295f81EF-13CB-4DB4-8223-10A173AA0780";
        
        // Add in session 3
        SBBScheduledActivity *activity3 = [[SBBScheduledActivity alloc] init];
        activity3.scheduledOn = [activity2.scheduledOn dateByAddingTimeInterval:2*60*60];
        activity3.guid = [NSUUID UUID].UUIDString;
        activity3.activity = [[SBBActivity alloc] init];
        activity3.activity.label = @"Activity Session 3";
        activity3.activity.labelDetail = @"15 minutes";
        activity3.activity.task = [[SBBTaskReference alloc] init];
        activity3.activity.task.identifier = @"1-Combo-295f81EF-13CB-4DB4-8223-10A173AA0780";
        
        // Add in session 3
        SBBScheduledActivity *activity4 = [[SBBScheduledActivity alloc] init];
        activity4.scheduledOn = [activity3.scheduledOn dateByAddingTimeInterval:2*60*60];
        activity4.guid = [NSUUID UUID].UUIDString;
        activity4.activity = [[SBBActivity alloc] init];
        activity4.activity.label = @"Activity Session 4";
        activity4.activity.labelDetail = @"15 minutes";
        activity4.activity.task = [[SBBTaskReference alloc] init];
        activity4.activity.task.identifier = @"1-Combo-295f81EF-13CB-4DB4-8223-10A173AA0780";
        
        responseObject = @[training, medTracking, activity1, activity2, activity3, activity4];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(responseObject, nil);
    });
}

@end
