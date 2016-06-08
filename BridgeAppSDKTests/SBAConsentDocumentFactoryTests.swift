//
//  SBAConsentDocumentFactoryTests.swift
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

class SBAConsentDocumentFactoryTests: ResourceTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBuildConsentFactory() {
        guard let consentFactory = createConsentFactory() else { return }
        
        XCTAssertNotNil(consentFactory.steps)
        guard let steps = consentFactory.steps else { return }
        
        let expectedSteps: [ORKStep] = [SBADirectNavigationStep(identifier: "reconsentIntroduction"),
                                   ORKVisualConsentStep(identifier: "consentVisual"),
                                   SBASurveySubtaskStep(identifier: "consentQuiz"),
                                   SBADirectNavigationStep(identifier: "consentFailedQuiz"),
                                   ORKInstructionStep(identifier: "consentPassedQuiz"),
                                   ORKConsentSharingStep(identifier: "consentSharingOptions"),
                                   SBAConsentReviewStep(identifier: "consentReview"),
                                   SBARegistrationStep(identifier: "registration"),
                                   ORKInstructionStep(identifier: "consentCompletion")]
        XCTAssertEqual(steps.count, expectedSteps.count)
        for (idx, expectedStep) in expectedSteps.enumerate() {
            if idx < steps.count {
                XCTAssertEqual(steps[idx].identifier, expectedStep.identifier)
                let stepClass = NSStringFromClass(steps[idx].classForCoder)
                let expectedStepClass = NSStringFromClass(expectedStep.classForCoder)
                XCTAssertEqual(stepClass, expectedStepClass)
            }
        }

        if (steps.count < expectedSteps.count) { return }
    }
    
    func testReconsentSteps() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let reconsentSteps = consentFactory.reconsentSteps()
        XCTAssertNotNil(reconsentSteps)
        guard let steps = reconsentSteps else { return }
        
        let expectedSteps: [ORKStep] = [SBADirectNavigationStep(identifier: "reconsentIntroduction"),
                                        ORKVisualConsentStep(identifier: "consentVisual"),
                                        SBASurveySubtaskStep(identifier: "consentQuiz"),
                                        SBADirectNavigationStep(identifier: "consentFailedQuiz"),
                                        ORKInstructionStep(identifier: "consentPassedQuiz"),
                                        ORKConsentSharingStep(identifier: "consentSharingOptions"),
                                        SBAConsentReviewStep(identifier: "consentReview"),
                                        ORKInstructionStep(identifier: "consentCompletion")]
        XCTAssertEqual(steps.count, expectedSteps.count)
        for (idx, expectedStep) in expectedSteps.enumerate() {
            if idx < steps.count {
                XCTAssertEqual(steps[idx].identifier, expectedStep.identifier)
                let stepClass = NSStringFromClass(steps[idx].classForCoder)
                let expectedStepClass = NSStringFromClass(expectedStep.classForCoder)
                XCTAssertEqual(stepClass, expectedStepClass)
            }
        }
        
        if (steps.count < expectedSteps.count) { return }
    }
    
    func testRegistrationSteps() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let registrationSteps = consentFactory.registrationSteps()
        XCTAssertNotNil(registrationSteps)
        guard let steps = registrationSteps else { return }
        
        let expectedSteps: [ORKStep] = [ORKVisualConsentStep(identifier: "consentVisual"),
                                        SBASurveySubtaskStep(identifier: "consentQuiz"),
                                        SBADirectNavigationStep(identifier: "consentFailedQuiz"),
                                        ORKInstructionStep(identifier: "consentPassedQuiz"),
                                        ORKConsentSharingStep(identifier: "consentSharingOptions"),
                                        SBAConsentReviewStep(identifier: "consentReview"),
                                        SBARegistrationStep(identifier: "registration"),
                                        ORKInstructionStep(identifier: "consentCompletion")]
        XCTAssertEqual(steps.count, expectedSteps.count)
        for (idx, expectedStep) in expectedSteps.enumerate() {
            if idx < steps.count {
                XCTAssertEqual(steps[idx].identifier, expectedStep.identifier)
                let stepClass = NSStringFromClass(steps[idx].classForCoder)
                let expectedStepClass = NSStringFromClass(expectedStep.classForCoder)
                XCTAssertEqual(stepClass, expectedStepClass)
            }
        }
        
        if (steps.count < expectedSteps.count) { return }
    }
    
    func createConsentFactory() -> SBAConsentDocumentFactory? {
        guard let input = jsonForResource("Consent") else { return nil }
        return SBAConsentDocumentFactory(dictionary: input)
    }

}
