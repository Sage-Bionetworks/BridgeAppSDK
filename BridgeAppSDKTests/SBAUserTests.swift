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
    var cacheTest: NSObject!
    var objectTest: SBBObjectManager!
    
    override func setUp() {
        super.setUp()

        // register mocks for components
        authMock = MockAuthManager()
        consentMock = MockConsentManager()
        SBBComponentManager.registerComponent(authMock, for: SBBAuthManager().classForCoder)
        SBBComponentManager.registerComponent(consentMock, for: SBBConsentManager().classForCoder)
        
        // register a test cache manager with our mock auth manager
        cacheTest = BridgeSDKTestable.registerTestBridgeCacheManager(authMock)
        
        // ...and register a fresh object manager with our cache manager
        objectTest = SBBObjectManager()
        objectTest.setValue(cacheTest, forKey: "cacheManager")
        SBBComponentManager.registerComponent(objectTest, for: objectTest.classForCoder)
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
    
    func testLoginUser_NoDataSharing() {
        
        // Set up the mock auth manager
        let email = "test+1002@sagebase.org"
        let password = "abcd1234"
        authMock.responseObject = createLoginResponseObject(dataSharing: false, sharingScope: "no_sharing", email: email)
        
        // --- method under test
        let user = MockUser()
        authMock.authDelegate = user
        user.loginUser(email: email, password: password, completion: nil)
        
        // Verify the login
        XCTAssertEqual(authMock.loginEmail, email)
        XCTAssertEqual(authMock.loginPassword, password)
        XCTAssertTrue(authMock.signIn_called)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.password, password)
        XCTAssertEqual(user.subpopulationGuid, "sample-study")
        XCTAssertTrue(user.isConsentVerified)
        XCTAssertEqual(user.dataGroups!, ["test_user","group_afternoon"])
        XCTAssertEqual(user.dataSharingScope, SBBParticipantDataSharingScope.none)
        XCTAssertFalse(user.isDataSharingEnabled)
        XCTAssertEqual(user.name, "Jane")
        XCTAssertEqual(user.familyName, "Doe")
    }
    
    func testLoginUser_SharingAll() {
        
        // Set up the mock auth manager
        let email = "test+1002@sagebase.org"
        let password = "abcd1234"
        authMock.responseObject = createLoginResponseObject(dataSharing: true, sharingScope: "all_qualified_researchers", email: email)
        
        // --- method under test
        let user = MockUser()
        authMock.authDelegate = user
        user.loginUser(email: email, password: password, completion: nil)
        
        // Verify the login
        XCTAssertEqual(authMock.loginEmail, email)
        XCTAssertEqual(authMock.loginPassword, password)
        XCTAssertTrue(authMock.signIn_called)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.password, password)
        XCTAssertEqual(user.subpopulationGuid, "sample-study")
        XCTAssertTrue(user.isConsentVerified)
        XCTAssertEqual(user.dataGroups!, ["test_user","group_afternoon"])
        XCTAssertEqual(user.dataSharingScope, SBBParticipantDataSharingScope.all)
        XCTAssertTrue(user.isDataSharingEnabled)
        XCTAssertEqual(user.name, "Jane")
        XCTAssertEqual(user.familyName, "Doe")
    }
    
    func testLoginUser_ExternalId() {
        
        // Set up the mock auth manager
        let email = "test+1002@sagebase.org"
        let password = "1002"
        authMock.responseObject = createLoginResponseObject(dataSharing: true, sharingScope: "all_qualified_researchers", email: email)
        
        // --- method under test
        let user = MockUser()
        authMock.authDelegate = user
        user.loginUser(externalId: "1002", completion: nil)
        
        // Verify the login
        XCTAssertEqual(authMock.loginEmail, email)
        XCTAssertEqual(authMock.loginPassword, password)
        XCTAssertTrue(authMock.signIn_called)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.password, password)
        XCTAssertEqual(user.subpopulationGuid, "sample-study")
        XCTAssertTrue(user.isConsentVerified)
        XCTAssertEqual(user.dataGroups!, ["test_user","group_afternoon"])
        XCTAssertEqual(user.dataSharingScope, SBBParticipantDataSharingScope.all)
        XCTAssertTrue(user.isDataSharingEnabled)
        XCTAssertEqual(user.name, "Jane")
        XCTAssertEqual(user.familyName, "Doe")
    }
    
    // MARK: helper methods
    
    func createLoginResponseObject(dataSharing: Bool, sharingScope: String, email: String) -> NSDictionary {
        
        let dictionary: NSDictionary = [
            "notifyByEmail" : true,
            "languages" : ["en"],
            "roles" : [],
            "status" : "enabled",
            "createdOn" : "2016-08-09T04:47:52.169Z",
            "signedMostRecentConsent" : true,
            "sessionToken" : "217ee580-8950-4f37-98bb-2f770d9a331c",
            "id" : "3LglxfsJ3Moo9NymdS6qem",
            "type" : "UserSessionInfo",
            "authenticated" : true,
            "dataGroups" : ["test_user","group_afternoon"],
            "consentStatuses" : [
                "sample-study" : [
                    "signedMostRecentConsent" : true,
                    "consented" : true,
                    "type" : "ConsentStatus",
                    "name" : "Default Consent Group",
                    "required" : true,
                    "subpopulationGuid" : "sample-study"
                ]
            ],
            "dataSharing" : dataSharing,
            "consented" : true,
            "username" : email,
            "attributes" : [:],
            "environment" : "production",
            "email" : email,
            "sharingScope" : sharingScope,
            "firstName" : "Jane",
            "lastName" : "Doe"
        ]
        return dictionary
    }
}

class MockAuthManager: NSObject, SBBAuthManagerProtocol {
    
    var responseObject: Any?
    var responseError: Error?
    
    var signUpStudyParticipant_called: Bool = false
    var signUp: SBBSignUp?
    
    var signIn_called: Bool = false
    var loginEmail: String?
    var loginPassword: String?
    
    var userSessionInfo: SBBUserSessionInfo?
    
    weak var authDelegate: SBBAuthManagerDelegateProtocol?

    public func signUpStudyParticipant(_ signUp: SBBSignUp, completion: SBBNetworkManagerCompletionBlock? = nil) -> URLSessionTask {
        let session = URLSessionDataTask()
        signUpStudyParticipant_called = true
        self.signUp = signUp
        completion?(session, responseObject, responseError)
        return session
    }
    
    func savedPassword() -> String? {
        return self.loginPassword
    }
    
    func isAuthenticated() -> Bool {
        return self.signIn_called
    }

    func signIn(withEmail email: String, password: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        let session = URLSessionDataTask()
        self.loginEmail = email
        self.loginPassword = password
        signIn_called = true
        
        let response = responseObject as? [AnyHashable: Any]!
        if response != nil &&
            authDelegate != nil &&
            authDelegate!.responds(to: #selector(SBBAuthManagerDelegateProtocol.authManager(_:didReceiveUserSessionInfo:))) {
            if let participantManager = SBBComponentManager.component(SBBParticipantManager.self) as? SBBParticipantManager {
                // this is a BridgeSDK-internal method
                let clearSelector = NSSelectorFromString("clearUserInfoFromCache")
                participantManager.perform(clearSelector)
            }
            self.userSessionInfo = SBBUserSessionInfo(dictionaryRepresentation: response!)
            authDelegate!.authManager!(self, didReceiveUserSessionInfo: userSessionInfo)
        }
        completion?(session, responseObject, responseError)
        return session
    }
    
    func resendEmailVerification(_ email: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        assertionFailure("Not implemented")
        return URLSessionDataTask()
    }
    
    func resetUserSessionInfo() {
        userSessionInfo = SBBUserSessionInfo()
        userSessionInfo?.studyParticipant = SBBStudyParticipant()
        if authDelegate != nil &&
            authDelegate!.responds(to: #selector(SBBAuthManagerDelegateProtocol.authManager(_:didReceiveUserSessionInfo:))) {
            authDelegate!.authManager!(self, didReceiveUserSessionInfo: userSessionInfo)
        }
    }
    
    func signOut(completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        assertionFailure("Not implemented")
        return URLSessionDataTask()
    }

    func ensureSignedIn(completion: SBBNetworkManagerCompletionBlock?) {
        assertionFailure("Not implemented")
    }
    
    func requestPasswordReset(forEmail email: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        assertionFailure("Not implemented")
        return URLSessionDataTask()
    }

    func resetPassword(toNewPassword password: String, resetToken token: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        assertionFailure("Not implemented")
        return URLSessionDataTask()
    }

    func addAuthHeader(toHeaders headers: NSMutableDictionary) {
        // doesn't need to do anything for the mock
        return
    }
    
    // MARK: deprecated methods
    
    func signUp(withEmail email: String, username: String, password: String, dataGroups: [String]?, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        assertionFailure("Deprecated method. Do not use.")
        return URLSessionDataTask()
    }
    
    func signUp(withEmail email: String, username: String, password: String, completion: SBBNetworkManagerCompletionBlock?) -> URLSessionTask {
        assertionFailure("Deprecated method. Do not use.")
        return URLSessionDataTask()
    }
}

class MockConsentManager: NSObject, SBBConsentManagerProtocol {

    public func consentSignature(_ name: String, forSubpopulationGuid subpopGuid: String, birthdate date: Date, signatureImage: UIImage?, dataSharing scope: SBBParticipantDataSharingScope, completion: SBBConsentManagerCompletionBlock? = nil) -> URLSessionTask {
        return URLSessionDataTask()
    }

    public func consentSignature(_ name: String, birthdate date: Date, signatureImage: UIImage?, dataSharing scope: SBBParticipantDataSharingScope, completion: SBBConsentManagerCompletionBlock? = nil) -> URLSessionTask {
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
