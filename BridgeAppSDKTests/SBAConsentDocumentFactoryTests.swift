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
    
    func testConsentReview_NoNameOrSignature() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"   : "consentReview",
            "type"         : "consentReview",
            "items"        : []
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let reviewStep = step as? SBAConsentReviewStep else {
            XCTAssert(false, "\(step) not of expected type")
            return
        }
        
        XCTAssertNotNil(reviewStep.reasonForConsent)
        XCTAssertNotNil(reviewStep.signature)
        XCTAssertTrue(reviewStep.formItems == nil || reviewStep.formItems!.count == 0, "There should be no formItems for this review step")
        
        if let signature = reviewStep.signature {        
            XCTAssertFalse(signature.requiresName)
            XCTAssertFalse(signature.requiresSignatureImage)
        }
    }
    
    func testConsentReview_Default() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"   : "consentReview",
            "type"         : "consentReview"
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let reviewStep = step as? SBAConsentReviewStep else {
            XCTAssert(false, "\(step) not of expected type")
            return
        }
        
        XCTAssertNotNil(reviewStep.reasonForConsent)
        XCTAssertNotNil(reviewStep.signature)
        
        if let signature = reviewStep.signature {
            XCTAssertTrue(signature.requiresName)
            XCTAssertTrue(signature.requiresSignatureImage)
        }
        
        XCTAssertNotNil(reviewStep.formItems)
        
        let expected: [String: String] = [ "name"        : "ORKTextAnswerFormat",
                                           "signature"   : "BridgeAppSDK.SBASignatureImageAnswerFormat"]
        for (identifier, expectedClassName) in expected {
            let formItem = reviewStep.formItemForIdentifier(identifier)
            XCTAssertNotNil(formItem)
            if let classForCoder = formItem?.answerFormat?.classForCoder {
                let className = NSStringFromClass(classForCoder)
                XCTAssertEqual(className, expectedClassName)
            }
        }
    }
    
    func testConsentReview_ExternalID() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"   : "consentReview",
            "type"         : "consentReview",
            "items"        : ["externalID"]
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let reviewStep = step as? SBAConsentReviewStep else {
            XCTAssert(false, "\(step) not of expected type")
            return
        }
        
        XCTAssertNotNil(reviewStep.reasonForConsent)
        XCTAssertNotNil(reviewStep.signature)
        
        if let signature = reviewStep.signature {
            XCTAssertFalse(signature.requiresName)
            XCTAssertFalse(signature.requiresSignatureImage)
        }
        
        XCTAssertNotNil(reviewStep.formItems)
        
        let expected: [String: String] = [ "externalID" : "ORKTextAnswerFormat"]
        for (identifier, expectedClassName) in expected {
            let formItem = reviewStep.formItemForIdentifier(identifier)
            XCTAssertNotNil(formItem)
            if let classForCoder = formItem?.answerFormat?.classForCoder {
                let className = NSStringFromClass(classForCoder)
                XCTAssertEqual(className, expectedClassName)
            }
        }
    }
    
    func createConsentFactory() -> SBAConsentDocumentFactory? {
        guard let input = jsonForResource("Consent") else { return nil }
        return SBAConsentDocumentFactory(dictionary: input)
    }

}
