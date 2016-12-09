//
//  SBAUserProfileControllerTests.swift
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

class SBAUserProfileControllerTests: ResourceTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRegistrationStep() {
        let input: NSDictionary = [
            "identifier"    : "registration",
            "type"          : "registration",
            "title"         : "Registration",
            "items"         : ["email", "password", "externalID", "name", "birthdate", "gender", "bloodType", "fitzpatrickSkinType", "wheelchairUse"]
        ]
        let step = SBARegistrationStep(inputItem: input)
        
        let birthdate = Date().addingNumberOfDays(-4000)
        let result = step.instantiateDefaultStepResult(["email" : "doe@foo.com",
                                                        "password" : "abcd1234",
                                                        "confirmation" : "abcd1234",
                                                        "externalID" : "000111",
                                                        "name" : "Jane Doe",
                                                        "birthdate" : birthdate,
                                                        "gender" : "HKBiologicalSexFemale",
                                                        "bloodType" : "HKBloodTypeBPositive",
                                                        "fitzpatrickSkinType" : NSNumber(value: HKFitzpatrickSkinType.III.rawValue),
                                                        "wheelchairUse" : NSNumber(value: true),
            ])
        
        let stepVC = step.instantiateStepViewController(with: result)
        
        XCTAssertEqual(stepVC.email, "doe@foo.com")
        XCTAssertEqual(stepVC.password, "abcd1234")
        XCTAssertEqual(stepVC.externalID, "000111")
        XCTAssertEqual(stepVC.name, "Jane Doe")
        XCTAssertEqual(stepVC.birthdate, birthdate)
        XCTAssertEqual(stepVC.gender, HKBiologicalSex.female)
        XCTAssertEqual(stepVC.bloodType, HKBloodType.bPositive)
        XCTAssertEqual(stepVC.fitzpatrickSkinType, HKFitzpatrickSkinType.III)
        XCTAssertEqual(stepVC.wheelchairUse, true)
    }
    
    func testConsentReviewStep() {
        guard let consentFactory = createConsentFactory() else {
            XCTAssert(false, "Could not create consent factory")
            return
        }

        let input: NSDictionary = [
            "identifier"    : "consentReview",
            "type"          : "consentReview",
            "items"         : ["externalID", "name", "birthdate"]
        ]
        
        let step = SBAConsentReviewStep(inputItem: input, inDocument: consentFactory.consentDocument, factory: consentFactory)
        
        let birthdate = Date().addingNumberOfDays(-4000)
        let result = step.instantiateDefaultStepResult(["externalID" : "000111",
                                                        "name" : "Jane Doe",
                                                        "birthdate" : birthdate,
                                                        ])
        
        let stepVC = step.instantiateStepViewController(with: result)
        
        XCTAssertEqual(stepVC.externalID, "000111")
        XCTAssertEqual(stepVC.name, "Jane Doe")
        XCTAssertEqual(stepVC.birthdate, birthdate)
    }
    
    func testChangeEmailStep() {

        let step = SBAChangeEmailStep(identifier: "changeEmail")
        
        let result = step.instantiateDefaultStepResult(["email" : "doe@foo.com"])
        let stepVC = step.instantiateStepViewController(with: result)
        
        guard let profileController = stepVC as? SBAUserProfileController else {
            XCTAssert(false, "Step view controller does not match expected casting")
            return
        }
        
        XCTAssertEqual(profileController.email, "doe@foo.com")
    }
    
    func testLoginStep() {

        let step = SBALoginStep(identifier: "login")
        
        let result = step.instantiateDefaultStepResult(["email" : "doe@foo.com",
                                                        "password" : "abcd1234"])
        
        let stepVC = step.instantiateStepViewController(with: result)
        
        XCTAssertEqual(stepVC.email, "doe@foo.com")
        XCTAssertEqual(stepVC.password, "abcd1234")
    }
        
    func createConsentFactory() -> SBAConsentDocumentFactory? {
        guard let input = jsonForResource("Consent") else { return nil }
        return SBAConsentDocumentFactory(dictionary: input)
    }
    
}
