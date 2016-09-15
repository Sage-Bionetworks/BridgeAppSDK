//
//  SBAAccountTests.swift
//  BridgeAppSDK
//
//  Copyright (c) 2016 Sage Bionetworks. All rights reserved.
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
@testable import BridgeAppSDK

class SBAAccountTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: External ID
    
    func testExternalIdRegistrationStep_Navigation() {
        let registrationStep = SBAExternalIDStep(identifier: "registration")
        
        let taskResult = ORKTaskResult(identifier: "registration")
        
        let firstStep = registrationStep.stepAfterStep(withIdentifier: nil, with: taskResult)
        XCTAssertNotNil(firstStep)
        
        guard let firstStepIdentifier = firstStep?.identifier else { return }
        
        let secondStep = registrationStep.stepAfterStep(withIdentifier: firstStepIdentifier, with: taskResult)
        XCTAssertNotNil(secondStep)
        
        guard let secondStepIdentifier = secondStep?.identifier else { return }
        
        let thirdStep = registrationStep.stepAfterStep(withIdentifier: secondStepIdentifier, with: taskResult)
        XCTAssertNil(thirdStep)
        
        let backStep = registrationStep.stepBeforeStep(withIdentifier: secondStepIdentifier, with: taskResult)
        XCTAssertEqual(backStep?.identifier, firstStepIdentifier)
        
    }
    
    func testExternalIDRegistrationStepViewController_ExternalId_Valid() {
        
        let registrationStep = SBAExternalIDStep(identifier: "registration")
        
        let vc = MockExternalIDRegistrationStepViewController(step: registrationStep)
        vc.firstAnswer = "ABC123"
        vc.secondAnswer = "ABC123"
        
        do {
            let externalId = try vc.externalId()
            XCTAssertEqual(externalId, "ABC123")
        }
        catch let error as NSError {
            XCTAssert(false, "Unexpected error: \(error)")
        }
    }
    
    func testExternalIDRegistrationStepViewController_ExternalId_Invalid() {
        
        let registrationStep = SBAExternalIDStep(identifier: "registration")
        
        let vc = MockExternalIDRegistrationStepViewController(step: registrationStep)
        vc.firstAnswer = "ABC123*"
        vc.secondAnswer = "ABC123*"
        
        do {
            let externalId = try vc.externalId()
            XCTAssert(false, "Should throw error")
            XCTAssertNil(externalId)
        }
        catch SBAExternalIDError.Invalid(let reason) {
            XCTAssertNil(reason)
        }
        catch let error as NSError {
            XCTAssert(false, "Should throw invalid error: \(error)" )
        }
    }
    
    func testExternalIDRegistrationStepViewController_ExternalId_Empty() {
        
        let registrationStep = SBAExternalIDStep(identifier: "registration")
        
        let vc = MockExternalIDRegistrationStepViewController(step: registrationStep)
        vc.firstAnswer = ""
        vc.secondAnswer = ""
        
        do {
            let externalId = try vc.externalId()
            XCTAssert(false, "Should throw error")
            XCTAssertNil(externalId)
        }
        catch SBAExternalIDError.Invalid(let reason) {
            XCTAssertNil(reason)
        }
        catch let error as NSError {
            XCTAssert(false, "Should throw invalid error: \(error)" )
        }
    }
    
    func testExternalIDRegistrationStepViewController_ExternalId_Mismatch() {
        
        let registrationStep = SBAExternalIDStep(identifier: "registration")
        
        let vc = MockExternalIDRegistrationStepViewController(step: registrationStep)
        vc.firstAnswer = "ABC123"
        vc.secondAnswer = "ABC12"
        
        do {
            let externalId = try vc.externalId()
            XCTAssert(false, "Should throw error")
            XCTAssertNil(externalId)
        }
        catch SBAExternalIDError.NotMatching {
            // Expected error
        }
        catch let error as NSError {
            XCTAssert(false, "Should throw invalid error: \(error)" )
        }
    }
    
    // MARK: Permissions
    
    func testPermssionsType_Some() {
        let permissonsStep = SBAPermissionsStep(identifier: "permissions")
        permissonsStep.permissions = [.coremotion, .localNotifications, .microphone]
        
        let expectedItems = [SBAPermissionsType.coremotion.rawValue, SBAPermissionsType.localNotifications.rawValue, SBAPermissionsType.microphone.rawValue].sorted()
        let actualItems = permissonsStep.items as? [UInt]
        
        XCTAssertNotNil(actualItems)
        guard actualItems != nil else { return }
        XCTAssertEqual(actualItems!, expectedItems)
    }
    
    func testPermssionsType_PhotoLibrary() {
        let permissonsStep = SBAPermissionsStep(identifier: "permissions")
        permissonsStep.permissions = [.photoLibrary]
        
        let expectedItems = [SBAPermissionsType.photoLibrary.rawValue].sorted()
        let actualItems = permissonsStep.items as? [UInt]
        
        XCTAssertNotNil(actualItems)
        guard actualItems != nil else { return }
        XCTAssertEqual(actualItems!, expectedItems)
    }

}

class MockExternalIDRegistrationStepViewController : SBAExternalIDStepViewController {
    
    var firstAnswer: String?
    var secondAnswer: String?
    
    override var result: ORKStepResult? {
        
        var results: [ORKResult] = []
        if let first = firstAnswer {
            let firstResult = ORKTextQuestionResult(identifier: "externalId.externalId")
            firstResult.textAnswer = first
            results.append(firstResult)
        }
        if let second = secondAnswer {
            let secondResult = ORKTextQuestionResult(identifier: "externalId.externalId")
            secondResult.textAnswer = second
            results.append(secondResult)
        }
        return ORKStepResult(stepIdentifier: self.step!.identifier, results: results)
    }
}
