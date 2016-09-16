//
//  SBAUserTests.swift
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

import XCTest
import BridgeSDK
import BridgeAppSDK

class SBAUserTests: XCTestCase {
    
    var authMock: MockAuthManager!
    var consentMock: MockConsentManager!
    
    override func setUp() {
        super.setUp()

        // register mocks for components
        authMock = MockAuthManager()
        consentMock = MockConsentManager()
        SBBComponentManager.registerComponent(authMock, for: SBBAuthManager().classForCoder)
        SBBComponentManager.registerComponent(consentMock, for: SBBConsentManager().classForCoder)
    }
    
    override func tearDown() {
        SBBComponentManager.reset()
        super.tearDown()
    }
    
    func testEmailFormat() {
        let bridgeInfo = MockBridgeInfo()
        let emailFormat = bridgeInfo.emailFormatForLoginViaExternalId
        XCTAssertEqual(emailFormat, "test+%@@sagebase.org")
    }
}

class MockBridgeInfo : NSObject, SBABridgeInfo {
    var studyIdentifier: String! = "study"
    var cacheDaysAhead: Int = 0
    var cacheDaysBehind: Int = 0
    var environment: SBBEnvironment = .staging
    var appStoreLinkURLString: String?
    var emailForLoginViaExternalId: String? = "test@sagebase.org"
    var passwordFormatForLoginViaExternalId: String?
    var testUserDataGroup: String?
    var taskMap: [NSDictionary]?
    var schemaMap: [NSDictionary]?
    var filenameMap: NSDictionary?
    var certificateName: String?
    var newsfeedURLString: String?
    var logoImageName: String?
    var appUpdateURLString: String?
    var disableTestUserCheck: Bool = false
}

class MockAuthManager: NSObject, SBBAuthManagerProtocol {
    weak var authDelegate: SBBAuthManagerDelegateProtocol?
    
    func signUp(withEmail email: String, username: String, password: String, dataGroups: [String]?, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }
    
    func signUp(withEmail email: String, username: String, password: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }
    
    func resendEmailVerification(_ email: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }
    
    func signIn(withEmail email: String, password: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }
    
    func signOut(completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func ensureSignedIn(completion: SBBNetworkManagerCompletionBlock?) {
        
    }
    
    func requestPasswordReset(forEmail email: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func resetPassword(toNewPassword password: String, resetToken token: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func addAuthHeader(toHeaders headers: NSMutableDictionary) {
        
    }
}

class MockConsentManager: NSObject, SBBConsentManagerProtocol {
    
    func consentSignature(_ name: String, birthdate date: Date, signatureImage: UIImage?, dataSharing scope: SBBUserDataSharingScope, completion: SBBConsentManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func consentSignature(_ name: String, forSubpopulationGuid subpopGuid: String, birthdate date: Date, signatureImage: UIImage?, dataSharing scope: SBBUserDataSharingScope, completion: SBBConsentManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func retrieveConsentSignature(completion: SBBConsentManagerRetrieveCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func getConsentSignature(forSubpopulation subpopGuid: String, completion: SBBConsentManagerGetCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func withdrawConsent(withReason reason: String?, completion: SBBConsentManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func withdrawConsent(forSubpopulation subpopGuid: String, withReason reason: String?, completion: SBBConsentManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }

    func emailConsent(forSubpopulation subpopGuid: String, completion: SBBConsentManagerCompletionBlock?) -> URLSessionTask {
        return URLSessionDataTask()
    }
    
}
