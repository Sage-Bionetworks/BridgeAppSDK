//
//  SBAUserWrapper.swift
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

import Foundation

// Wrapper support for reverse compatiblility to AppCore. syoung 03/28/2016
@objc
public protocol SBAUserWrapper: SBAParticipantInfo, SBBAuthManagerDelegateProtocol {
    
    var bridgeInfo: SBABridgeInfo? { get }

    /**
     * SessionToken is stored in memory only
     */
    var sessionToken: String? { get set }

    /**
     * Email is stored in the keychain.
     */
    var email: String? { get set }

    /**
     * ExternalId is stored in the keychain.
     */
    var externalId: String? { get set }

    /**
     * Password is stored in the keychain
     */
    var password: String? { get set }

    /**
     * Subpopulation GUID is used for tracking by certain apps. Stored in the keychain.
     */
    var subpopulationGuid: String? { get set }

    /**
     * Date when the user was created (initially enrolled) in the study.
     */
    var createdOn: Date { get set }
    
    /**
     * Consent signature should be stored in keychain.
     */
    var consentSignature: SBAConsentSignatureWrapper? { get set }
    
    /**
     * Data groups associated with this user.
     */
    var dataGroups: [String]? { get set }

    /**
     * The user has registered locally or the server has returned confirmation that the
     * user registered on a different device.
     */
    var isRegistered: Bool { get set }   // signedUp

    /**
     * User email/password login has been verified on the server.
     */
    var isLoginVerified: Bool { get set }   // signedIn

    /**
     * The user's consent has been verified by the server.
     */
    var isConsentVerified: Bool { get set }

    /**
     * The user has "paused" their participation in the study and their data should *not*
     * be sent to the server.
     */
    var isDataSharingEnabled: Bool { get set }

    /**
     * The sharing scope set by the user during consent
     */
    var dataSharingScope: SBBParticipantDataSharingScope { get set }
    
    /**
     * Tracking that can be set by the app to track the user's onboarding progress
     */
    var onboardingStepIdentifier: String? { get set }
    
    /**
     Reset the user's keychain
     */
    func resetStoredUserData()
    
}

extension SBAUserWrapper {
    
    public var appDelegate: SBABridgeAppSDKDelegate? {
        // emm 2017-09-28 This hack is necessary because as of Xcode 9/iOS 11 SDK, attempting to
        // access the UIApplication.shared.delegate from other than the main thread causes
        // an assert to fail.
        return SBAUser.mainQueueAppDelegate
    }
    
    // With Xcode 8 and iOS 10, the keychain entitlement is required and is *not* reverse-compatible
    // to previous versions of the app that did not require this. Because of this, it is possible to
    // have the flags set for registered and verified without an accessible email/password. Because
    // of this, we need to logout the user, but we want to keep their data that locally cached.
    // syoung 09/19/2016
    func resetUserKeychainIfNeeded() {
        if ((isRegistered || isLoginVerified) && email == nil) {
            resetStoredUserData()
        }
    }
}

