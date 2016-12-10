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
        let manager = MockOnboardingManager(jsonNamed: "Onboarding")
        XCTAssertNotNil(manager)
        XCTAssertNotNil(manager?.sections)
        guard let sections = manager?.sections else { return }
        
        XCTAssertEqual(sections.count, 9)
    }
    
    func testShouldInclude() {
        
        let manager = MockOnboardingManager(jsonNamed: "Onboarding")!
        
        let expectedNonNil: [SBAOnboardingSectionBaseType : [SBAOnboardingTaskType]] = [
            .login: [.login],
            .eligibility: [.registration],
            .consent: [.login, .registration, .reconsent],
            .registration: [.registration],
            .passcode: [.login, .registration, .reconsent],
            .emailVerification: [.registration],
            .permissions: [.login, .registration],
            .profile: [.registration],
            .completion: [.login, .registration]]

        for sectionType in SBAOnboardingSectionBaseType.all {
            let include = expectedNonNil[sectionType]
            XCTAssertNotNil(include, "\(sectionType)")
            if include != nil {
                for taskType in SBAOnboardingTaskType.all {
                    let expectedShouldInclude = include!.contains(taskType)
                    let section: NSDictionary = ["onboardingType": sectionType.rawValue]
                    let shouldInclude = manager.shouldInclude(section: section, onboardingTaskType: taskType)
                    XCTAssertEqual(shouldInclude, expectedShouldInclude, "\(sectionType) \(taskType)")
                }
            }
        }
        
    }
    
    func testShouldInclude_HasPasscode() {
        
        let manager = MockOnboardingManager(jsonNamed: "Onboarding")!
        manager._hasPasscode = true
        
        // Check that if the passcode has been set that it is not included
        for taskType in SBAOnboardingTaskType.all {
            let section: NSDictionary = ["onboardingType": SBAOnboardingSectionBaseType.passcode.rawValue]
            let shouldInclude = manager.shouldInclude(section: section, onboardingTaskType: taskType)
            XCTAssertFalse(shouldInclude, "\(taskType)")
        }
    }
    
    func testShouldInclude_HasRegistered() {
        
        let manager = MockOnboardingManager(jsonNamed: "Onboarding")!
        
        // If the user has registered and this is a completion of the registration
        // then only include email verification and those sections AFTER verification
        // However, if the user is being reconsented then include the reconsent section
        
        manager.mockAppDelegate.mockCurrentUser.isRegistered = true
        manager._hasPasscode = true
    
        let taskTypes: [SBAOnboardingTaskType] = [.registration, .reconsent]
        let expectedNonNil: [SBAOnboardingSectionBaseType : [SBAOnboardingTaskType]] = [
            .login: [.login],
            // eligibility should *not* be included in registration if the user is at the email verification step
            .eligibility: [],
            // consent should *not* be included in registration if the user is at the email verification step
            .consent: [.login, .reconsent],
            // registration should *not* be included in registration if the user is at the email verification step
            .registration: [],
            // passcode should *not* be included in registration if the user is at the email verification step
            // and has already set the passcode
            .passcode: [],
            .emailVerification: [.registration],
            .permissions: [.login, .registration],
            .profile: [.registration],
            .completion: [.login, .registration]]
        
        for sectionType in SBAOnboardingSectionBaseType.all {
            let include = expectedNonNil[sectionType]
            XCTAssertNotNil(include, "\(sectionType)")
            if include != nil {
                for taskType in taskTypes {
                    let expectedShouldInclude = include!.contains(taskType)
                    let section: NSDictionary = ["onboardingType": sectionType.rawValue]
                    let shouldInclude = manager.shouldInclude(section: section, onboardingTaskType: taskType)
                    XCTAssertEqual(shouldInclude, expectedShouldInclude, "\(sectionType) \(taskType)")
                }
            }
        }
    }
    
    func testSortOrder() {
        
        let inputSections = [
            ["onboardingType" : "customWelcome"],
            ["onboardingType" : "consent"],
            ["onboardingType" : "passcode"],
            ["onboardingType" : "emailVerification"],
            ["onboardingType" : "registration"],
            ["onboardingType" : "login"],
            ["onboardingType" : "eligibility"],
            ["onboardingType" : "profile"],
            ["onboardingType" : "permissions"],
            ["onboardingType" : "completion"],
            ["onboardingType" : "customEnd"],]
        let input: NSDictionary = ["sections" : inputSections];
        
        guard let sections = SBAOnboardingManager(dictionary: input).sections else {
            XCTAssert(false, "failed to create onboarding manager sections")
            return
        }
        
        let expectedOrder = ["customWelcome",
                             "login",
                             "eligibility",
                             "consent",
                             "registration",
                             "passcode",
                             "emailVerification",
                             "permissions",
                             "profile",
                             "completion",
                             "customEnd",]
        let actualOrder = sections.mapAndFilter({ $0.onboardingSectionType?.identifier })
        
        XCTAssertEqual(actualOrder, expectedOrder)
        
    }
    
    func testEligibilitySection() {

        guard let steps = checkOnboardingSteps( .base(.eligibility), .registration) else { return }
        
        let expectedSteps: [ORKStep] = [SBAToggleFormStep(identifier: "inclusionCriteria"),
                                        SBAInstructionStep(identifier: "ineligibleInstruction"),
                                        SBAInstructionStep(identifier: "eligibleInstruction")]
        XCTAssertEqual(steps.count, expectedSteps.count)
        for (idx, expectedStep) in expectedSteps.enumerated() {
            if idx < steps.count {
                XCTAssertEqual(steps[idx].identifier, expectedStep.identifier)
                let stepClass = NSStringFromClass(steps[idx].classForCoder)
                let expectedStepClass = NSStringFromClass(expectedStep.classForCoder)
                XCTAssertEqual(stepClass, expectedStepClass)
            }
        }
    }
    
    func testPasscodeSection() {

        guard let steps = checkOnboardingSteps( .base(.passcode), .registration) else { return }
        
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? ORKPasscodeStep else {
            XCTAssert(false, "\(steps.first) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "passcode")
        XCTAssertEqual(step.passcodeType, ORKPasscodeType.type6Digit)
        XCTAssertEqual(step.title, "Identification")
        XCTAssertEqual(step.text, "Select a 6-digit passcode. Setting up a passcode will help provide quick and secure access to this application.")
    }
    
    func testLoginSection() {
        guard let steps = checkOnboardingSteps( .base(.login), .login) else { return }
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? SBALoginStep else {
            XCTAssert(false, "\(steps.first) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "login")
    }
    
    func testRegistrationSection() {
        guard let steps = checkOnboardingSteps( .base(.registration), .registration) else { return }
        XCTAssertEqual(steps.count, 2)
        
        guard let step1 = steps.first as? SBAPermissionsStep else {
            XCTAssert(false, "\(steps.first) not of expected type")
            return
        }
        
        XCTAssertEqual(step1.identifier, "healthKitPermissions")
        
        guard let step2 = steps.last as? SBARegistrationStep else {
            XCTAssert(false, "\(steps.last) not of expected type")
            return
        }
        
        XCTAssertEqual(step2.identifier, "registration")
    }
    
    func testEmailVerificationSection() {
        guard let steps = checkOnboardingSteps( .base(.emailVerification), .registration) else { return }
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? SBAEmailVerificationStep else {
            XCTAssert(false, "\(steps.first) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "emailVerification")
    }
    
    func testProfileSection() {
        guard let steps = checkOnboardingSteps( .base(.profile), .registration) else { return }
        XCTAssertEqual(steps.count, 3)
        
        for step in steps {
            XCTAssertTrue(step is SBAProfileFormStep)
        }
    }
    
    func testPermissionsSection() {
        guard let steps = checkOnboardingSteps( .base(.permissions), .registration) else { return }
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? SBAPermissionsStep else {
            XCTAssert(false, "\(steps.first) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "permissions")
    }
    
    func testCompletionSection() {
        guard let steps = checkOnboardingSteps( .base(.completion), .registration) else { return }
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? SBAOnboardingCompleteStep else {
            XCTAssert(false, "\(steps.first) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "onboardingCompletion")
        XCTAssertEqual(step.title, "Thank You!")
        XCTAssertEqual(step.detailText, "You are all set.")
    }
    
    func checkOnboardingSteps(_ sectionType: SBAOnboardingSectionType, _ taskType: SBAOnboardingTaskType) -> [ORKStep]? {
        
        let manager = MockOnboardingManager(jsonNamed: "Onboarding")
        let section = manager?.section(for: sectionType)
        XCTAssertNotNil(section, "sectionType:\(sectionType) taskType:\(taskType)")
        guard section != nil else { return  nil}
        
        let steps = manager?.steps(for: section!, with: taskType)
        XCTAssertNotNil(steps, "sectionType:\(sectionType) taskType:\(taskType)")
        
        return steps
    }

}

class MockOnboardingManager: SBAOnboardingManager {
    
    var mockAppDelegate:MockAppInfoDelegate = MockAppInfoDelegate()
    
    override var sharedAppDelegate: SBAAppInfoDelegate {
        get { return mockAppDelegate }
        set {}
    }
    
    var _hasPasscode = false
    
    override var hasPasscode: Bool {
        return _hasPasscode
    }
    
}
