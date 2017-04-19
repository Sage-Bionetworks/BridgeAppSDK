//
//  SBAOnboardingAppDelegate.h
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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
#import "SBADefines.h"

NS_ASSUME_NONNULL_BEGIN

@class SBAOnboardingManager;

typedef NS_ENUM(NSUInteger, SBAOnboardingTaskType) {
    SBAOnboardingTaskTypeSignup,
    SBAOnboardingTaskTypeLogin,
    SBAOnboardingTaskTypeReconsent,
};

@protocol SBAOnboardingAppDelegate <NSObject>

/**
 The onboarding manager to use with this application. By default, this is built using a
 json file named "Onboarding" that is included in the main bundle and uses the same onboarding
 manager for login, sign up, and re-consent.
 
 @param     onboardingTaskType  The onboarding type
 */
- (SBAOnboardingManager *)onboardingManagerForOnboardingTaskType:(SBAOnboardingTaskType)onboardingTaskType NS_SWIFT_NAME(onboardingManager(for:));

/**
 Show the appropriate view controller for the current onboarding state. This method should look at the 
 current state of the onboarding flow and display the view controller appropriate to the current state.
 */
- (void)showAppropriateViewControllerAnimated:(BOOL)animated NS_SWIFT_NAME(showAppropriateViewController(animated:));

/**
 Method for showing the study overview (onboarding) for a user who is not signed in.
 By default, this method looks for a storyboard named "StudyOverview" that is included
 in the main bundle and instantiates the initial view controller.
 
 @param animated  Should the transition be animated
 */
- (void)showStudyOverviewViewControllerAnimated:(BOOL)animated NS_SWIFT_NAME(showStudyOverviewViewController(animated:));

/**
 Method for showing the sign up view controller for signing up a new user. By default,
 this method looks for a storyboard named "SignUp" that is included in the main bundle
 and instantiates the initial view controller.
 
 @param animated  Should the transition be animated
 */
- (void)showSignUpViewControllerAnimated:(BOOL)animated NS_SWIFT_NAME(showSignUpViewController(animated:));

/**
 Method for showing the main view controller for a user who signed in.
 By default, this method looks for a storyboard named "Main" that is included
 in the main bundle.
 
 @param animated  Should the transition be animated
 */
- (void)showMainViewControllerAnimated:(BOOL)animated NS_SWIFT_NAME(showMainViewController(animated:));

@end

NS_ASSUME_NONNULL_END
