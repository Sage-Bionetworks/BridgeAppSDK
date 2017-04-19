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
        
        XCTAssertEqual(sections.count, 8)
    }
    
    func testShouldInclude() {
        
        let manager = MockOnboardingManager(jsonNamed: "Onboarding")!
        
        let expectedNonNil: [SBAOnboardingSectionBaseType : [SBAOnboardingTaskType]] = [
            .login: [.login],
            .eligibility: [.signup],
            .consent: [.login, .signup, .reconsent],
            .registration: [.signup],
            .passcode: [.login, .signup, .reconsent],
            .emailVerification: [.signup],
            .permissions: [.login, .signup],
            .profile: [.signup],
            .completion: [.login, .signup]]

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
    
        let taskTypes: [SBAOnboardingTaskType] = [.signup, .reconsent]
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
            .emailVerification: [.signup],
            .permissions: [.login, .signup],
            .profile: [.signup],
            .completion: [.login, .signup]]
        
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

        guard let steps = checkOnboardingSteps( .base(.eligibility), .signup) else { return }
        
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

        guard let steps = checkOnboardingSteps( .base(.passcode), .signup) else { return }
        
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? ORKPasscodeStep else {
            XCTAssert(false, "\(String(describing: steps.first)) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "passcode")
        XCTAssertEqual(step.passcodeType, ORKPasscodeType.type4Digit)
        XCTAssertEqual(step.title, "Identification")
        XCTAssertEqual(step.text, "Select a 4-digit passcode. Setting up a passcode will help provide quick and secure access to this application.")
    }
    
    func testLoginSection() {
        guard let steps = checkOnboardingSteps( .base(.login), .login) else { return }
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? SBALoginStep else {
            XCTAssert(false, "\(String(describing: steps.first)) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "login")
    }
    
    func testRegistrationSection() {
        guard let steps = checkOnboardingSteps( .base(.registration), .signup) else { return }
        XCTAssertEqual(steps.count, 2)
        
        guard let step1 = steps.first as? SBAPermissionsStep else {
            XCTAssert(false, "\(String(describing: steps.first)) not of expected type")
            return
        }
        
        XCTAssertEqual(step1.identifier, "healthKitPermissions")
        
        guard let step2 = steps.last as? SBARegistrationStep else {
            XCTAssert(false, "\(String(describing: steps.last)) not of expected type")
            return
        }
        
        XCTAssertEqual(step2.identifier, "registration")
    }
    
    func testEmailVerificationSection() {
        guard let steps = checkOnboardingSteps( .base(.emailVerification), .signup) else { return }
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? SBAEmailVerificationStep else {
            XCTAssert(false, "\(String(describing: steps.first)) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "emailVerification")
    }
    
    func testProfileSection() {
        guard let steps = checkOnboardingSteps( .base(.profile), .signup) else { return }
        XCTAssertEqual(steps.count, 3)
        
        for step in steps {
            XCTAssertTrue(step is SBAProfileFormStep)
        }
    }
    
    func testPermissionsSection() {
        guard let steps = checkOnboardingSteps( .base(.permissions), .signup) else { return }
        XCTAssertEqual(steps.count, 1)
        
        guard let step = steps.first as? SBAPermissionsStep else {
            XCTAssert(false, "\(String(describing: steps.first)) not of expected type")
            return
        }
        
        XCTAssertEqual(step.identifier, "permissions")
    }
    
    func testCreateTask_SignUp_Row0() {
        guard let manager = MockOnboardingManager(jsonNamed: "Onboarding") else { return }
        
        guard let task = manager.createTask(for: .signup, tableRow: 0) else {
            XCTAssert(false, "Created task is nil")
            return
        }
        print(task)
        
        let expectedCount = 7
        XCTAssertEqual(task.steps.count, expectedCount)
        guard task.steps.count == expectedCount else {
            XCTAssert(false, "Exit early b/c step count doesn't match expected")
            return
        }
        
        var ii = 0
        XCTAssertTrue(task.steps[ii] is SBASubtaskStep)
        XCTAssertEqual(task.steps[ii].identifier, "eligibility")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is SBASubtaskStep)
        XCTAssertEqual(task.steps[ii].identifier, "consent")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is SBASubtaskStep)
        XCTAssertEqual(task.steps[ii].identifier, "registration")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is ORKPasscodeStep)
        XCTAssertEqual(task.steps[ii].identifier, "passcode")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is SBAEmailVerificationStep)
        XCTAssertEqual(task.steps[ii].identifier, "emailVerification")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is SBAPermissionsStep)
        XCTAssertEqual(task.steps[ii].identifier, "permissions")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is SBASubtaskStep)
        XCTAssertEqual(task.steps[ii].identifier, "profile")
    }
    
    func testCreateTask_SignUp_Row2() {
        guard let manager = MockOnboardingManager(jsonNamed: "Onboarding") else { return }
        
        guard let task = manager.createTask(for: .signup, tableRow: 2) else {
            XCTAssert(false, "Created task is nil")
            return
        }
        print(task)
        
        let expectedCount = 5
        XCTAssertEqual(task.steps.count, expectedCount)
        guard task.steps.count == expectedCount else {
            XCTAssert(false, "Exit early b/c step count doesn't match expected")
            return
        }
        
        var ii = 0
        XCTAssertTrue(task.steps[ii] is SBASubtaskStep)
        XCTAssertEqual(task.steps[ii].identifier, "registration")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is ORKPasscodeStep)
        XCTAssertEqual(task.steps[ii].identifier, "passcode")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is SBAEmailVerificationStep)
        XCTAssertEqual(task.steps[ii].identifier, "emailVerification")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is SBAPermissionsStep)
        XCTAssertEqual(task.steps[ii].identifier, "permissions")
        
        ii = ii + 1
        XCTAssertTrue(task.steps[ii] is SBASubtaskStep)
        XCTAssertEqual(task.steps[ii].identifier, "profile")
    }
    
    func testSignupState() {
        guard let manager = MockOnboardingManager(jsonNamed: "Onboarding") else { return }
        
        let eligibilityState1 = manager.signupState(for: 0)
        XCTAssertEqual(eligibilityState1, .current)
        
        let consentState1 = manager.signupState(for: 1)
        XCTAssertEqual(consentState1, .locked)
        
        let registrationState1 = manager.signupState(for: 2)
        XCTAssertEqual(registrationState1, .locked)
        
        let profileState1 = manager.signupState(for: 3)
        XCTAssertEqual(profileState1, .locked)
        
        // For any step in the consent flow except the last, then the consent is the current section
        manager.sharedUser.onboardingStepIdentifier = "eligibility.eligibleInstruction"
        
        let eligibilityState2 = manager.signupState(for: 0)
        XCTAssertEqual(eligibilityState2, .completed)
        
        let consentState2 = manager.signupState(for: 1)
        XCTAssertEqual(consentState2, .current)
        
        let registrationState2 = manager.signupState(for: 2)
        XCTAssertEqual(registrationState2, .locked)
        
        let profileState2 = manager.signupState(for: 3)
        XCTAssertEqual(profileState2, .locked)

        // Once we enter the consent flow then that becomes the current section
        manager.sharedUser.onboardingStepIdentifier = "consent.consentVisual"
        
        let eligibilityState3 = manager.signupState(for: 0)
        XCTAssertEqual(eligibilityState3, .completed)
        
        let consentState3 = manager.signupState(for: 1)
        XCTAssertEqual(consentState3, .current)
        
        let registrationState3 = manager.signupState(for: 2)
        XCTAssertEqual(registrationState3, .locked)
        
        let profileState3 = manager.signupState(for: 3)
        XCTAssertEqual(profileState3, .locked)
        
        // For any step in the consent flow except the last, then the consent is the current section
        manager.sharedUser.onboardingStepIdentifier = "consent.consentCompletion"
        
        let eligibilityState4 = manager.signupState(for: 0)
        XCTAssertEqual(eligibilityState4, .completed)
        
        let consentState4 = manager.signupState(for: 1)
        XCTAssertEqual(consentState4, .completed)
        
        let registrationState4 = manager.signupState(for: 2)
        XCTAssertEqual(registrationState4, .current)
        
        let profileState4 = manager.signupState(for: 3)
        XCTAssertEqual(profileState4, .locked)
 
        // Set the steps to the registration section
        manager.sharedUser.onboardingStepIdentifier = "registration.registration"
        
        let eligibilityState5 = manager.signupState(for: 0)
        XCTAssertEqual(eligibilityState5, .completed)
        
        let consentState5 = manager.signupState(for: 1)
        XCTAssertEqual(consentState5, .completed)
        
        let registrationState5 = manager.signupState(for: 2)
        XCTAssertEqual(registrationState5, .current)
        
        let profileState5 = manager.signupState(for: 3)
        XCTAssertEqual(profileState5, .locked)
        
        // For registration, there isn't a completion step and the final step is email verification
        // so the current section remains the email verification *until* login is verified
        manager.sharedUser.isRegistered = true
        manager.sharedUser.isLoginVerified = false
        manager.sharedUser.isConsentVerified = false
        manager.sharedUser.onboardingStepIdentifier = "emailVerification"
        
        let eligibilityState6 = manager.signupState(for: 0)
        XCTAssertEqual(eligibilityState6, .completed)
        
        let consentState6 = manager.signupState(for: 1)
        XCTAssertEqual(consentState6, .completed)
        
        let registrationState6 = manager.signupState(for: 2)
        XCTAssertEqual(registrationState6, .current)
        
        let profileState6 = manager.signupState(for: 3)
        XCTAssertEqual(profileState6, .locked)
        
        // Once login and consent are verified, then ready for the profile section
        manager.sharedUser.isLoginVerified = true
        manager.sharedUser.isConsentVerified = true
        
        let eligibilityState7 = manager.signupState(for: 0)
        XCTAssertEqual(eligibilityState7, .completed)
        
        let consentState7 = manager.signupState(for: 1)
        XCTAssertEqual(consentState7, .completed)
        
        let registrationState7 = manager.signupState(for: 2)
        XCTAssertEqual(registrationState7, .completed)
        
        let profileState7 = manager.signupState(for: 3)
        XCTAssertEqual(profileState7, .current)

        manager.sharedUser.onboardingStepIdentifier = "SBAOnboardingCompleted"
        
        let eligibilityState8 = manager.signupState(for: 0)
        XCTAssertEqual(eligibilityState8, .completed)
        
        let consentState8 = manager.signupState(for: 1)
        XCTAssertEqual(consentState8, .completed)
        
        let registrationState8 = manager.signupState(for: 2)
        XCTAssertEqual(registrationState8, .completed)
        
        let profileState8 = manager.signupState(for: 3)
        XCTAssertEqual(profileState8, .completed)
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
