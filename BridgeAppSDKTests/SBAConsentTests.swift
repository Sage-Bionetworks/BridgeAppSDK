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
@testable import BridgeAppSDK

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
        
        let expectedSteps: [ORKStep] = [SBAInstructionStep(identifier: "reconsentIntroduction"),
                                   ORKVisualConsentStep(identifier: "consentVisual"),
                                   SBANavigationSubtaskStep(identifier: "consentQuiz"),
                                   SBAInstructionStep(identifier: "consentFailedQuiz"),
                                   SBAInstructionStep(identifier: "consentPassedQuiz"),
                                   SBAConsentSharingStep(identifier: "consentSharingOptions"),
                                   SBAConsentReviewStep(identifier: "consentReview"),
                                   SBAInstructionStep(identifier: "consentCompletion")]
        XCTAssertEqual(steps.count, expectedSteps.count)
        for (idx, expectedStep) in expectedSteps.enumerated() {
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
        
        let steps = (consentFactory.reconsentStep().subtask as! SBANavigableOrderedTask).steps
        
        let expectedSteps: [ORKStep] = [SBAInstructionStep(identifier: "reconsentIntroduction"),
                                        ORKVisualConsentStep(identifier: "consentVisual"),
                                        SBANavigationSubtaskStep(identifier: "consentQuiz"),
                                        SBAInstructionStep(identifier: "consentFailedQuiz"),
                                        SBAInstructionStep(identifier: "consentPassedQuiz"),
                                        SBAConsentSharingStep(identifier: "consentSharingOptions"),
                                        SBAConsentReviewStep(identifier: "consentReview"),
                                        SBAInstructionStep(identifier: "consentCompletion")]
        XCTAssertEqual(steps.count, expectedSteps.count)
        for (idx, expectedStep) in expectedSteps.enumerated() {
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
        
        let steps = (consentFactory.registrationConsentStep().subtask as! SBANavigableOrderedTask).steps
        
        let expectedSteps: [ORKStep] = [ORKVisualConsentStep(identifier: "consentVisual"),
                                        SBANavigationSubtaskStep(identifier: "consentQuiz"),
                                        SBAInstructionStep(identifier: "consentFailedQuiz"),
                                        SBAInstructionStep(identifier: "consentPassedQuiz"),
                                        SBAConsentSharingStep(identifier: "consentSharingOptions"),
                                        SBAConsentReviewStep(identifier: "consentReview"),
                                        SBAInstructionStep(identifier: "consentCompletion")]
        XCTAssertEqual(steps.count, expectedSteps.count)
        for (idx, expectedStep) in expectedSteps.enumerated() {
            if idx < steps.count {
                XCTAssertEqual(steps[idx].identifier, expectedStep.identifier)
                let stepClass = NSStringFromClass(steps[idx].classForCoder)
                let expectedStepClass = NSStringFromClass(expectedStep.classForCoder)
                XCTAssertEqual(stepClass, expectedStepClass)
            }
        }
        
        if (steps.count < expectedSteps.count) { return }
    }
    
    func testConsentReview_Default() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"   : "consentReview",
            "type"         : "consentReview"
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (_, reviewStep, nameStep, signatureStep) = consentReviewSteps(step)
        
        XCTAssertNotNil(nameStep)
        XCTAssertNotNil(signatureStep)
        
        guard reviewStep != nil && nameStep != nil && signatureStep != nil  else { return }
        
        XCTAssertNotNil(reviewStep!.reasonForConsent)
        XCTAssertNotNil(nameStep!.formItems)
        
        let expected: [String: String] = [ "name"        : "ORKTextAnswerFormat"]
        for (identifier, expectedClassName) in expected {
            let formItem = nameStep!.formItem(for: identifier)
            XCTAssertNotNil(formItem)
            if let classForCoder = formItem?.answerFormat?.classForCoder {
                let className = NSStringFromClass(classForCoder)
                XCTAssertEqual(className, expectedClassName)
            }
        }
    }
    
    func testConsentReview_NameAndBirthdate() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"   : "consentReview",
            "type"         : "consentReview",
            "items"        : ["name", "birthdate"]
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (_, reviewStep, nameStep, signatureStep) = consentReviewSteps(step)
        
        XCTAssertNotNil(nameStep)
        XCTAssertNotNil(signatureStep)
        
        guard reviewStep != nil && nameStep != nil && signatureStep != nil  else { return }
        
        XCTAssertNotNil(reviewStep!.reasonForConsent)
        XCTAssertNotNil(nameStep!.formItems)
        
        let nameItem = nameStep!.formItem(for: "name")
        XCTAssertNotNil(nameItem)
        if let _ = nameItem?.answerFormat as? ORKTextAnswerFormat {
        } else {
            XCTAssert(false, "\(nameItem?.answerFormat) not of expected type")
        }
        
        let birthdateItem = nameStep!.formItem(for: "birthdate")
        XCTAssertNotNil(birthdateItem)
        if let birthdateFormat = birthdateItem?.answerFormat as? ORKHealthKitCharacteristicTypeAnswerFormat {
            XCTAssertEqual(birthdateFormat.characteristicType.identifier, HKCharacteristicTypeIdentifier.dateOfBirth.rawValue)
        } else {
            XCTAssert(false, "\(birthdateItem?.answerFormat) not of expected type")
        }
    }
    
    func testConsentReview_RequiresSignature_YES() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"                : "consentReview",
            "type"                      : "consentReview",
            "requiresSignature"         : true
        ]
        
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (_, reviewStep, nameStep, signatureStep) = consentReviewSteps(step)
        
        XCTAssertNotNil(nameStep)
        XCTAssertNotNil(signatureStep)
        
        guard reviewStep != nil && nameStep != nil && signatureStep != nil  else { return }
        
        XCTAssertNotNil(reviewStep!.reasonForConsent)
        XCTAssertNotNil(nameStep!.formItems)
        
        let expected: [String: String] = [ "name"        : "ORKTextAnswerFormat"]
        for (identifier, expectedClassName) in expected {
            let formItem = nameStep!.formItem(for: identifier)
            XCTAssertNotNil(formItem)
            if let classForCoder = formItem?.answerFormat?.classForCoder {
                let className = NSStringFromClass(classForCoder)
                XCTAssertEqual(className, expectedClassName)
            }
        }
    }
    
    func testConsentReview_RequiresSignature_NO() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"                : "consentReview",
            "type"                      : "consentReview",
            "requiresSignature"         : false
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (_, reviewStep, nameStep, signatureStep) = consentReviewSteps(step)
        
        XCTAssertNotNil(reviewStep?.reasonForConsent)
        XCTAssertNil(nameStep)
        XCTAssertNil(signatureStep)
    }
    
    func testConsentResult_RequiresSignatureAndConsented() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"                : "consentReview",
            "type"                      : "consentReview",
            "items"                     : ["name", "birthdate"]
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (_, reviewStep, _, _) = consentReviewSteps(step)
        guard reviewStep != nil else { return }
        
        let reviewResult = ORKConsentSignatureResult(identifier: "review.consent")
        reviewResult.consented = true
        reviewResult.signature = reviewStep!.signature
        
        let nameResult = ORKTextQuestionResult(identifier: "name.name")
        nameResult.textAnswer = "John Jones"
        
        let birthResult = ORKDateQuestionResult(identifier: "name.birthdate")
        birthResult.dateAnswer = Date(timeIntervalSince1970: 0)
        
        let signatureResult = ORKSignatureResult(identifier: "signature.signature")
        signatureResult.signatureImage = UIImage()
        
        let inputResult = ORKStepResult(stepIdentifier: step!.identifier, results: [reviewResult, nameResult, birthResult, signatureResult])
        let viewController = step?.instantiateStepViewController(with: inputResult)
        let outputResult = viewController?.result
        
        XCTAssertNotNil(outputResult)
        guard let consentResult = outputResult?.result(forIdentifier: step!.identifier) as? SBAConsentReviewResult else {
            XCTAssert(false, "\(outputResult) missing consent review result")
            return
        }
        
        XCTAssertTrue(consentResult.isConsented)
        XCTAssertNotNil(consentResult.consentSignature)
        XCTAssertNotNil(consentResult.consentSignature?.signatureImage)
        XCTAssertNotNil(consentResult.consentSignature?.signatureName)
        XCTAssertNotNil(consentResult.consentSignature?.signatureDate)
        XCTAssertNotNil(consentResult.consentSignature?.signatureBirthdate)
    }
    
    func testConsentResult_RequiresNoSignature() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"                : "consentReview",
            "type"                      : "consentReview",
            "requiresSignature"         : false
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (_, reviewStep, _, _) = consentReviewSteps(step)
        guard reviewStep != nil else { return }
        
        let reviewResult = ORKConsentSignatureResult(identifier: "review.consent")
        reviewResult.consented = true
        reviewResult.signature = reviewStep!.signature
        
        let inputResult = ORKStepResult(stepIdentifier: step!.identifier, results: [reviewResult])
        let viewController = step?.instantiateStepViewController(with: inputResult)
        let outputResult = viewController?.result
        
        XCTAssertNotNil(outputResult)
        guard let consentResult = outputResult?.result(forIdentifier: step!.identifier) as? SBAConsentReviewResult else {
            XCTAssert(false, "\(outputResult) missing consent review result")
            return
        }
        
        XCTAssertTrue(consentResult.isConsented)
    }
    
    func testConsentResult_RequiresNotConsented() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"                : "consentReview",
            "type"                      : "consentReview",
            "requiresSignature"         : true
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (_, reviewStep, _, _) = consentReviewSteps(step)
        guard reviewStep != nil else { return }
        
        let reviewResult = ORKConsentSignatureResult(identifier: "review.consent")
        reviewResult.consented = false
        reviewResult.signature = reviewStep!.signature
        
        let inputResult = ORKStepResult(stepIdentifier: step!.identifier, results: [reviewResult])
        let viewController = step?.instantiateStepViewController(with: inputResult)
        let outputResult = viewController?.result
        
        XCTAssertNotNil(outputResult)
        guard let consentResult = outputResult?.result(forIdentifier: step!.identifier) as? SBAConsentReviewResult else {
            XCTAssert(false, "\(outputResult) missing consent review result")
            return
        }
        
        XCTAssertFalse(consentResult.isConsented)
    }
    
    func testConsentReviewStepAfterStep_NotConsented() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"                : "consentReview",
            "type"                      : "consentReview",
            "requiresSignature"         : true
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (pageStep, reviewStep, _, _) = consentReviewSteps(step)
        guard reviewStep != nil else { return }
        let taskResult = consentReviewTaskResult(step!.identifier, consented: false)
        
        let nextStep = pageStep?.stepAfterStep(withIdentifier: reviewStep?.identifier, with: taskResult)
        XCTAssertNil(nextStep)
    }
    
    func testConsentReviewStepAfterStep_Consented() {
        guard let consentFactory = createConsentFactory() else { return }
        
        let inputStep: NSDictionary = [
            "identifier"                : "consentReview",
            "type"                      : "consentReview",
            "requiresSignature"         : true
        ]
        
        let step = consentFactory.createSurveyStepWithDictionary(inputStep)
        let (pageStep, reviewStep, _, _) = consentReviewSteps(step)
        guard reviewStep != nil else { return }
        let taskResult = consentReviewTaskResult(step!.identifier, consented: true)
        
        let nextStep = pageStep?.stepAfterStep(withIdentifier: reviewStep?.identifier, with: taskResult)
        XCTAssertNotNil(nextStep)
    }
    
    
    // MARK: helper methods
    
    func consentReviewTaskResult(_ identifier: String, consented: Bool) -> ORKTaskResult {
        let reviewResult = ORKConsentSignatureResult(identifier: "consent")
        reviewResult.consented = consented
        let stepResult = ORKStepResult(stepIdentifier: "review", results: [reviewResult])
        let taskResult = ORKTaskResult(identifier: identifier)
        taskResult.results = [stepResult]
        return taskResult
    }
    
    func consentReviewSteps(_ step: ORKStep?) -> (pageStep:SBAConsentReviewStep?, reviewStep: ORKConsentReviewStep?, nameStep: ORKFormStep?, signatureStep: ORKSignatureStep?) {
        
        guard let pageStep = step as? SBAConsentReviewStep else {
            XCTAssert(false, "\(step) not of expected type")
            return (nil, nil, nil, nil)
        }

        guard let reviewStep = pageStep.step(withIdentifier: "review") as? ORKConsentReviewStep else {
            XCTAssert(false, "\(pageStep.steps) does not include a review step (required)")
            return (nil, nil, nil, nil)
        }
        
        if let signature = reviewStep.signature {
            // Review step should have either a nil signature or not require name/image
            XCTAssertFalse(signature.requiresName)
            XCTAssertFalse(signature.requiresSignatureImage)
        }
        
        let formStep = pageStep.step(withIdentifier: "name") as? ORKFormStep
        let signatureStep = pageStep.step(withIdentifier: "signature") as? ORKSignatureStep
        
        return (pageStep, reviewStep, formStep, signatureStep)
    }
    
    func createConsentFactory() -> SBAConsentDocumentFactory? {
        guard let input = jsonForResource("Consent") else { return nil }
        return SBAConsentDocumentFactory(dictionary: input)
    }

}
