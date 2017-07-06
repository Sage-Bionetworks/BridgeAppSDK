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
@import ResearchUXFactory;

NS_ASSUME_NONNULL_BEGIN

/*!
 Typedef for SBABridgeManager data methods' completion block.
 
 @param responseObject The JSON object from the response, if any.
 @param error          Any error that occurred.
 */
typedef void (^SBABridgeManagerCompletionBlock)(id _Nullable responseObject, NSError * _Nullable error);

/*!
 The `SBABridgeManager` is a wrapper for accessing BridgeSDK methods. The intention is to consolidate all the methods
 used by this SDK in a single manager in order to facilitate using this SDK as an example for how to use BridgeSDK
 managers directly in your own app, as well as to simplify the access because this SDK is written primarily in Swift
 whereas the access to BridgeSDK is simpier to read if written in objective-c. 
 
 @note syoung 10/05/2017 There are a few instances where `SBBUploadManager` is accessed directly and not through this
 wrapper.
 */
@interface SBABridgeManager : NSObject

/**
 Ensure that the resource bundle for BridgeAppSDK is added to the resources *before* calling into the 
 class map or resource finder.
 */
+ (void)addResourceBundleIfNeeded;

/*!
  Set up the Bridge SDK for the given study and pointing at the production environment.
 Usually you would call this at the beginning of your AppDelegate's application:didFinishLaunchingWithOptions: method.
 
 This will register a default SBBNetworkManager instance conigured correctly for the specified study and appropriate
 server environment. If you register a custom (or custom-configured) NetworkManager yourself, don't call this method.
 
 Caching is turned off if `cacheDaysAhead = 0` AND `cacheDaysBehind = 0`
 
 @param bridgeInfo    Pointer to a model object that supports the bridge info protocol
 @param participant   Pointer to the participant info object
 @param authDelegate  Pointer to the auth delegate (Optional)
 */
+ (void)setupWithBridgeInfo:(id <SBBBridgeInfoProtocol>)bridgeInfo
                participant:(id <SBAParticipantInfo>)participant
               authDelegate:(id <SBBAuthManagerDelegateProtocol> _Nullable)authDelegate NS_SWIFT_NAME(setup(bridgeInfo:participant:authDelegate:));

/*!
 Reset the Bridge SDK temporary session info and study participant object after a failed or incomplete onboarding.
 */
+ (void)resetUserSessionInfo;

/*!
 This method should be called from your app delegate's
 application:handleEventsForBackgroundURLSession:completionHandler: method when the identifier passed in there matches
 kBackgroundSessionIdentifier.
 
 If you are setting up and registering your own custom NetworkManager instance rather than using one of the BridgeSDK's
 +setupWithAppPrefix: methods, you will also need to call this from your app delegate's
 application:didFinishLaunchingWithOptions: method with kBackgroundSessionIdentifier as the identifier, and nil for the
 completion handler.
 
 @param identifier        The session identifier.
 @param completionHandler A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
 */
+ (void)restoreBackgroundSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

/*!
 Sign up for an account using a SignUp record, which is basically a StudyParticipant object with a password field. At minimum, the email and password fields must be filled in; in general, you would also want to fill in any of the following information available at sign-up time: firstName, lastName, sharingScope, externalId (if used), dataGroups, notifyByEmail, and any custom attributes you've defined for the attributes field.
 
 @param signUp A SBBSignUp object representing the participant signing up.
 @param completion A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
 */
+ (void)signUp:(SBBSignUp *)signup
    completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Sign in to an existing account with an email and password.
 
 @param email The email address of the account being signed into. This is used by Bridge as a unique identifier for a participant within a study.
 @param password The password of the account.
 @param completion A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
 */
+ (void)signIn:(NSString *)username
      password:(NSString *)password
    completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Call this when app becomes active to ensure the user is logged in to their account (if any).
 
 @param completion A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
 */
+ (void)ensureSignedInWithCompletion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Request that the password be reset for the account associated with the given email address. An email will be sent
 to that address with instructions for choosing a new password.
 
 @param emailAddress    The email address associated with the account whose password is to be reset.
 @param completion      A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
*/
+ (void)requestPasswordResetForEmail:(NSString*)emailAddress
                          completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Request Bridge to re-send the email verification link to the specified email address.
 
 A 404 Not Found HTTP status indicates there is no pending verification for that email address,
 either because it was not used to sign up for an account, or because it has already been verified.
 
 @param email       The email address for which to re-send the verification link.
 @param completion  A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
*/
+ (void)resendEmailVerification:(NSString*)emailAddress
                     completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Request Bridge to send the forgot password email link to the specified email address.
 
 @param email       The email address for which to send the password reset link.
 @param completion  A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
 */
+ (void)forgotPassword:(NSString*)emailAddress
            completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Fetch the StudyParticipant record from cache if caching is turned on, otherwise from the Bridge API.
 
 Note that if BridgeSDK was initialized with caching, the StudyParticipant record will always exist in the cache
 once the client has signed in for the first time, and since StudyParticipant is client-updatable, the cached copy
 would take priority over whatever Bridge responded with, so with caching turned on, this method will never try to
 retrieve the StudyParticipant from Bridge.
 
 Note also that the UserSessionInfo object received from Bridge on signIn is a superset of StudyParticipant, and
 upon successful signIn, any existing StudyParticipant object is deleted from cache and re-created from the
 UserSessionInfo. If any changes are made to the StudyParticipant on the Bridge server that didn't come from this
 client, the client's sessionToken should be invalidated, forcing the client to sign back in and thus update its
 cached StudyParticipant from the server.
 
 @param completion A SBABridgeManagerCompletionBlock to be called upon completion.
  */
+ (void)getParticipantRecordWithCompletion:(SBABridgeManagerCompletionBlock)completionBlock;

/*!
 Update the StudyParticipant record to the Bridge API.
 
 @param participant A client object representing the StudyParticipant record as it should be updated. If caching is enabled and you want to sync changes you've made to the local (cached) SBBStudyParticipant to Bridge, pass nil for this parameter.
 @param completion An SBBParticipantManagerCompletionBlock to be called upon completion.
 */
+ (void)updateParticipantRecord:(id)participant completion:(SBABridgeManagerCompletionBlock)completionBlock;

/*!
 Update the user's dataGroups to the Bridge API.
 
 This method writes a StudyParticipant record consisting of just the dataGroups field to the Bridge server. You may set the dataGroups directly as part of the StudyParticipant record when signing up for a Bridge account, but afterward should always update them via this method or one of the convenience methods that calls it.
 
 @note If using caching, be aware that calling this method (or any of the convenience methods which call it) will remove unexpired, unfinished scheduled activities from the cache. The next call to get scheduled activities will replace them with the correct schedule going forward for the new set of data groups. If you're not using the SDK's built-in caching, you will need to take
 care of this yourself.
 
 @param dataGroups An array of strings representing the dataGroups as they should be updated.
 @param completion  A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
 */
+ (void)updateDataGroups:(NSArray<NSString *> *)dataGroups
              completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Submit the user's "signature" and birthdate to indicate consent to participate in this research project.
 
 @param name                The user's name.
 @param birthDate           The user's birthday in the format "YYYY-MM-DD".
 @param consentImage        Image file of the user's signature. Should be less than 10kb. Optional, can be nil.
 @param sharingScope        The scope of data sharing to which the user has consented.
 @param subpopGuid          The GUID of the subpopulation for which the consent is being signed.
 @param completionBlock     A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
 */
+ (void)sendUserConsented:(NSString *)name
                birthDate:(NSDate *)birthDate
             consentImage:(UIImage * _Nullable)consentImage
             sharingScope:(SBBParticipantDataSharingScope)sharingScope
        subpopulationGuid:(NSString *)subpopGuid
               completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Change the scope of data sharing for this user.
 This is a convenience method that sets the participant record's sharingScope field and updates it to Bridge.
 This should only be done in response to an explicit choice on the part of the user to change the sharing scope.
 
 @param scope       The scope of data sharing to set for this user.
 @param completionBlock  A SBABridgeManagerCompletionBlock to be called upon completion.
 */
+ (void)updateDataSharingScope:(SBBParticipantDataSharingScope)scope
                    completion:(SBABridgeManagerCompletionBlock)completionBlock;

/*!
 Withdraw the user's consent signature previously submitted for a specific subpopulation.
 
 @param subpopGuid The GUID of the subpopulation for which the consent signature is being withdrawn.
 @param reason     A freeform text string entered by the participant describing their reasons for withdrawing from the study. Optional, can be nil or empty.
 @param completionBlock A SBABridgeManagerCompletionBlock to be called upon completion.
*/
+ (void)withdrawConsentForSubpopulation:(NSString *)subpopGuid
                                 reason:(NSString * _Nullable)reason
                             completion:(SBABridgeManagerCompletionBlock)completionBlock;

/*!
 Gets all available, started, or scheduled activities for a user. The "daysAhead" parameter allows you to retrieve activities that are scheduled in the future for the indicated number of days past today. This allows certain kinds of UIs (e.g. "You have N activities tomorrow" or "You have completed N of X activities today", even when the activities are not yet to be performed). A "daysBehind" parameter allows you to retain previously-cached activities that have not yet been completed that expired within the indicated number of days in the past. This allows UIs that say, e.g., "You left N activities uncompleted yesterday." Scheduled activities will be returned in the timezone of the device at the time of the request. Once a task is finished, or expires (the time has passed for it to be started), or becomes invalid due to a schedule change on the server, it will be removed from the list of scheduled activities returned from Bridge, and (except for previously-fetched but unfinished tasks within daysBehind) will also be removed from the list passed to this method's completion handler.
 

@note Both `daysAhead` and `daysBehind` are limited by the caching that is initially set up and by the server. For the case where the number of days ahead being requested is greater than 4, this value will return a limit of 4 schedules. For example, if an activity is scheduled 4 times per day over the week, then only 4 days ahead will be returned by the server. If the activity is scheduled once per month, then the next 4 schedules (4 months) will be returned.

@param daysAhead   A number of days in the future for which to retrieve available/started/scheduled activities.
@param daysBehind  A number of days in the past for which to include previously-cached but expired and unfinished activities (ignored if the SDK was initialized with useCache=NO).
@param completionBlock  A SBABridgeManagerCompletionBlock to be called upon completion.
*/
+ (void)fetchChangesToScheduledActivities:(NSArray <SBBScheduledActivity *> *)scheduledActivities
                                daysAhead:(NSInteger)daysAhead
                               daysBehind:(NSInteger)daysBehind
                               completion:(SBABridgeManagerCompletionBlock)completionBlock;

/**
 Gets all scheduled activities for a user. This returns a consolidated list that includes activities that are
 future and past. The activities are returned for a given date range.
 
 @param scheduledFrom   The earlier end of the desired date range for activities to be retrieved.
 @param scheduledTo     The later end of the desired date range for activities to be retrieved.
 @param completionBlock  A SBABridgeManagerCompletionBlock to be called upon completion.
 */
+ (void)fetchScheduledActivitiesFrom:(NSDate *)scheduledFrom to:(NSDate *)scheduledTo
                          completion:(SBABridgeManagerCompletionBlock)completionBlock;

/**
 Gets all scheduled activities for a user that are currently in the local cache.
 
 @param completionBlock  A SBABridgeManagerCompletionBlock to be called upon completion.
 */
+ (void)fetchAllCachedScheduledActivitiesWithCompletion:(SBABridgeManagerCompletionBlock)completionBlock;

/*!
 Update multiple scheduled activities' statuses with the API at one time.
 
 Only the startedOn and finishedOn fields of ScheduledActivity are user-writable, so only changes to those fields will have any effect on the server state.
 
 @param scheduledActivities     The list of ScheduledActivity objects whose statuses are to be updated to the API.
 @param completionBlock              A SBABridgeManagerCompletionBlock to be called upon completion. Optional.
 */
+ (void)updateScheduledActivities:(NSArray <SBBScheduledActivity *> *)scheduledActivities
                       completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;

/*!
 Fetch a survey from the Bridge API via an activityRef (href).
 
 @param surveyReference     The href identifying the desired survey, obtained e.g. from the Schedules or Activities API.
 @param completionBlock          A SBABridgeManagerCompletionBlock to be called upon completion.
 
 @return An NSURLSessionTask object so you can cancel or suspend/resume the request.
 */
+ (NSURLSessionTask *)loadSurvey:(SBBSurveyReference *)surveyReference completion:(SBABridgeManagerCompletionBlock)completionBlock;


/*!
 Add an external identifier for a participant.
 
 @param externalID  An external identifier to allow this participant to be tracked outside of the Bridge-specific study.
 @param completionBlock  A SBABridgeManagerCompletionBlock to be called upon completion.
 
 */
+ (void)setExternalIdentifier:(NSString *)externalID completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock;


#pragma mark - deprecated

+ (void)setAuthDelegate:(id <SBBAuthManagerDelegateProtocol>) authDelegate __attribute__((deprecated("Use setupWithStudy:cacheDaysAhead:cacheDaysBehind:environment:authDelegate: instead.")));

+ (void)signUp:(NSString *)email
      password:(NSString *)password
    externalId:(NSString * _Nullable)externalId
    dataGroups:(NSArray<NSString *> * _Nullable)dataGroups
    completion:(SBABridgeManagerCompletionBlock _Nullable)completionBlock __attribute__((deprecated("Use +signUp:completion: instead.")));

+ (void)getUserProfileWithCompletion:(SBABridgeManagerCompletionBlock)completionBlock __attribute__((deprecated("Use +getParticipantRecordWithCompletion: instead.")));

+ (void)updateUserProfile:(id)profile completion:(SBABridgeManagerCompletionBlock)completionBlock __attribute__((deprecated("Use +updateParticipantRecord:copmletion: instead.")));

+ (void)setupWithStudy:(NSString *)study
        cacheDaysAhead:(NSInteger)cacheDaysAhead
       cacheDaysBehind:(NSInteger)cacheDaysBehind
           environment:(SBBEnvironment)environment
          authDelegate:(id <SBBAuthManagerDelegateProtocol>) authDelegate  __attribute__((deprecated("Use +setupWithBridgeInfo:participant: instead.")));

@end

NS_ASSUME_NONNULL_END
