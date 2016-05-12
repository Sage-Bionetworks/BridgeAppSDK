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
        SBBComponentManager.registerComponent(authMock, forClass: SBBAuthManager().classForCoder)
        SBBComponentManager.registerComponent(consentMock, forClass: SBBConsentManager().classForCoder)
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
    var useCache: Bool = false
    var environment: SBBEnvironment! = .Staging
    var appStoreLinkURLString: String?
    var emailForLoginViaExternalId: String? = "test@sagebase.org"
    var passwordFormatForLoginViaExternalId: String?
    var testUserDataGroup: String?
    var taskMap: [NSDictionary]?
    var schemaMap: [NSDictionary]?
}

class MockAuthManager: NSObject, SBBAuthManagerProtocol {
    weak var authDelegate: SBBAuthManagerDelegateProtocol?
    
    func signUpWithEmail(email: String, username: String, password: String, dataGroups: [String]?, completion: SBBNetworkManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }
    
    func signUpWithEmail(email: String, username: String, password: String, completion: SBBNetworkManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }
    
    func resendEmailVerification(email: String, completion: SBBNetworkManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }
    
    func signInWithEmail(email: String, password: String, completion: SBBNetworkManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }
    
    func signOutWithCompletion(completion: SBBNetworkManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func ensureSignedInWithCompletion(completion: SBBNetworkManagerCompletionBlock?) {
        
    }
    
    func requestPasswordResetForEmail(email: String, completion: SBBNetworkManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func resetPasswordToNewPassword(password: String, resetToken token: String, completion: SBBNetworkManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func addAuthHeaderToHeaders(headers: NSMutableDictionary) {
        
    }
}

class MockConsentManager: NSObject, SBBConsentManagerProtocol {
    
    func consentSignature(name: String, birthdate date: NSDate, signatureImage: UIImage?, dataSharing scope: SBBUserDataSharingScope, completion: SBBConsentManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func consentSignature(name: String, forSubpopulationGuid subpopGuid: String, birthdate date: NSDate, signatureImage: UIImage?, dataSharing scope: SBBUserDataSharingScope, completion: SBBConsentManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func retrieveConsentSignatureWithCompletion(completion: SBBConsentManagerRetrieveCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func getConsentSignatureForSubpopulation(subpopGuid: String, completion: SBBConsentManagerGetCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func withdrawConsentWithReason(reason: String?, completion: SBBConsentManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func withdrawConsentForSubpopulation(subpopGuid: String, withReason reason: String?, completion: SBBConsentManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }

    func emailConsentForSubpopulation(subpopGuid: String, completion: SBBConsentManagerCompletionBlock?) -> NSURLSessionDataTask {
        return NSURLSessionDataTask()
    }
    
}