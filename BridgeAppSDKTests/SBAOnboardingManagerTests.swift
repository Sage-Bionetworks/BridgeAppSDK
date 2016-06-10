//
//  SBAOnboardingManagerTests.swift
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
import BridgeAppSDK

class SBAOnboardingManagerTests: ResourceTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCreateManager() {
        let manager = SBAOnboardingManager(jsonNamed: "Onboarding")
        XCTAssertNotNil(manager)
        XCTAssertNotNil(manager?.sections)
        guard let sections = manager?.sections else { return }
        
        XCTAssertEqual(sections.count, 6)
    }
    
//    func testEligibilitySection() {
//        let manager = SBAOnboardingManager(jsonNamed: "Onboarding")
//        let section = manager?.sectionForOnboardingSectionType(.Base(.Eligibility))
//        XCTAssertNotNil(section)
//        guard section != nil else { return }
//        
//        
//        
//        let factory = manager?.factoryForSection(section!)
//        XCTAssertNotNil(factory?.steps)
//        guard let steps = factory?.steps else { return }
//        
//        let expectedSteps: [ORKStep] = [SBASurveyFormStep(identifier: "inclusionCriteria"),
//                                        ORKInstructionStep(identifier: "ineligibleInstruction"),
//                                        SBADirectNavigationStep(identifier: "shareApp"),
//                                        ORKInstructionStep(identifier: "eligibleInstruction")]
//        XCTAssertEqual(steps.count, expectedSteps.count)
//        for (idx, expectedStep) in expectedSteps.enumerate() {
//            if idx < steps.count {
//                XCTAssertEqual(steps[idx].identifier, expectedStep.identifier)
//                let stepClass = NSStringFromClass(steps[idx].classForCoder)
//                let expectedStepClass = NSStringFromClass(expectedStep.classForCoder)
//                XCTAssertEqual(stepClass, expectedStepClass)
//            }
//        }
//    }
//    
//    func testConsentSection() {
//        let manager = SBAOnboardingManager(jsonNamed: "Onboarding")
//        let section = manager?.sectionForOnboardingSectionType(.Base(.Consent))
//        XCTAssertNotNil(section)
//        guard section != nil else { return }
//        
//        let factory = manager?.factoryForSection(section!)
//        XCTAssertNotNil(factory?.steps)
//        guard let steps = factory?.steps else { return }
//        XCTAssertEqual(steps.count, 9)
//    }
//    
//    func testPasscodeSection() {
//        let manager = SBAOnboardingManager(jsonNamed: "Onboarding")
//        let section = manager?.sectionForOnboardingSectionType(.Base(.Passcode))
//        XCTAssertNotNil(section)
//        guard section != nil else { return }
//        
//        let factory = manager?.factoryForSection(section!)
//        XCTAssertNotNil(factory?.steps)
//        guard let steps = factory?.steps else { return }
//        XCTAssertEqual(steps.count, 1)
//        
//        guard let step = steps.first as? ORKPasscodeStep else {
//            XCTAssert(false, "\(steps.first) not of expected type")
//            return
//        }
//        
//        XCTAssertEqual(step.identifier, "passcode")
//        XCTAssertEqual(step.passcodeType, ORKPasscodeType.Type6Digit)
//        XCTAssertEqual(step.title, "Identification")
//        XCTAssertEqual(step.text, "Select a 6-digit passcode. Setting up a passcode will help provide quick and secure access to this application.")
//    }
//    
//    func testLoginSection() {
//        let manager = SBAOnboardingManager(jsonNamed: "Onboarding")
//        let section = manager?.sectionForOnboardingSectionType(.Base(.Login))
//        XCTAssertNotNil(section)
//        guard section != nil else { return }
//        
//        let factory = manager?.factoryForSection(section!)
//        XCTAssertNotNil(factory?.steps)
//        guard let steps = factory?.steps else { return }
//        XCTAssertEqual(steps.count, 1)
//    }
//    
//    func testEmailVerificationSection() {
//        let manager = SBAOnboardingManager(jsonNamed: "Onboarding")
//        let section = manager?.sectionForOnboardingSectionType(.Base(.EmailVerification))
//        XCTAssertNotNil(section)
//        guard section != nil else { return }
//        
//        let factory = manager?.factoryForSection(section!)
//        XCTAssertNotNil(factory?.steps)
//        guard let steps = factory?.steps else { return }
//        XCTAssertEqual(steps.count, 1)
//    }
//    
//    func testCompletionSection() {
//        let manager = SBAOnboardingManager(jsonNamed: "Onboarding")
//        let section = manager?.sectionForOnboardingSectionType(.Base(.Completion))
//        XCTAssertNotNil(section)
//        guard section != nil else { return }
//        
//        let factory = manager?.factoryForSection(section!)
//        XCTAssertNotNil(factory?.steps)
//        guard let steps = factory?.steps else { return }
//        XCTAssertEqual(steps.count, 1)
//        
//        guard let step = steps.first as? ORKCompletionStep else {
//            XCTAssert(false, "\(steps.first) not of expected type")
//            return
//        }
//        
//        XCTAssertEqual(step.identifier, "onboardingCompletion")
//    }
    
    func testSortSections() {
        
    }

}
