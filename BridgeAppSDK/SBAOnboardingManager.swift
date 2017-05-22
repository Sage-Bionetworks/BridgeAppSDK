//
//  SBAOnboardingManager.swift
//  BridgeAppSDK
//
//  Copyright © 2016-2017 Sage Bionetworks. All rights reserved.
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

import Foundation
import ResearchKit

/**
 Extend the onboarding task type to include a method for defining all the onboarding flows.
 */
extension SBAOnboardingTaskType {
    
    /**
     List of all the types.
     */
    public static var all: [SBAOnboardingTaskType] {
        return [.signup, .login, .reconsent]
    }
    
    public var identifier: String {
        switch self {
        case .signup:
            return "signup"
        case .login:
            return "login"
        case .reconsent:
            return "reconsent"
        }
    }
}

/**
 The onboarding manager can be used with a json file that defines the different onboarding sections.
 This manager will vend the sections that are required for each different `SBAOnboardingTaskType`.
 */
open class SBAOnboardingManager: NSObject, SBASharedInfoController, ORKTaskResultSource, SBATaskViewControllerStrongReference {
    
    static let completedIdentifier = "SBAOnboardingCompleted"
    
    open var sections: [SBAOnboardingSection]?
    open var tableRows: [SBAOnboardingTableRow]?
    open var tableHeader: SBAOnboardingTableHeader?

    public override init() {
        super.init()
    }
    
    public convenience init?(jsonNamed: String) {
        guard let json = SBAResourceFinder.shared.json(forResource: jsonNamed) else { return nil }
        self.init(dictionary: json as NSDictionary)
    }
    
    public convenience init(dictionary: NSDictionary) {
        self.init()
        self.sections = (dictionary["sections"] as? [NSDictionary])?.sorted(by: { sortOrder($0, $1) })
        self.tableRows = dictionary["tableRows"] as? [NSDictionary]
        self.tableHeader = dictionary["tableHeader"] as? NSDictionary
    }
    
    /**
     Returns an initialized task view controller for the given task type with this manager as its delegate.
     @param  onboardingTaskType     The task type for this view controller
     @return                        A new task view controller
    */
    open func initializeTaskViewController(for onboardingTaskType: SBAOnboardingTaskType, tableRow: Int = 0) -> SBATaskViewController? {
        guard let task = self.createTask(for: onboardingTaskType, tableRow: tableRow) else { return nil }
        
        // Create the task view controller
        let taskViewController = SBATaskViewController(task: task, taskRun: nil)
        
        // by default, attach self to the task view controller as a strong reference
        // This is to ensure that the onboarding manager, which is by default the result data source,
        // is not released prematurely.
        taskViewController.strongReference = self
        attachTaskViewController(taskViewController)
        
        return taskViewController
    }
    
    
    // MARK: Protected methods that are exposed publicly to allow for override and testing
    
    /**
     Convenience method for getting the section for a given section type.
     
     @param     sectionType     The section type
     @return                    The onboarding section for this section type
    */
    open func section(for sectionType: SBAOnboardingSectionType) -> SBAOnboardingSection? {
        return self.sections?.find({ $0.onboardingSectionType == sectionType })
    }
    
    /**
     Create the task for the given onboarding type. By default, this method will flatten the steps
     (for reverse-compatibility to older applications) if and only if there are no table rows. If
     there are table rows, then it is assumed that the onboarding is implemented using a 
     `SBASignUpViewController` which requires a different implementation.
     
     @param onboardingTaskType  The onboarding type (signup, login, or reconsent)
     @param tableRow            The current state of onboarding signup
     @return                    The navigable task (or nil if failed to create)
     */
    open func createTask(for onboardingTaskType: SBAOnboardingTaskType, tableRow: Int = 0) -> SBANavigableOrderedTask? {
        guard let sections = self.sections else { return nil }
        
        let steps: [ORKStep] = {
            if self.tableRows != nil, onboardingTaskType == .signup {
                // Get the steps as subtask steps for each section
                return self.steps(for: onboardingTaskType, tableRow: tableRow)
            }
            else {
                // Get the steps from the sections
                return sections.mapAndFilter({
                    self.steps(for: $0, with: onboardingTaskType)
                }).flatMap({$0})
            }
        }()
        
        // Create the task view controller
        let task = SBANavigableOrderedTask(identifier: onboardingTaskType.identifier, steps: steps)
        return task
    }
    
    fileprivate func steps(for onboardingTaskType: SBAOnboardingTaskType, tableRow: Int) -> [ORKStep] {
        guard let tableRows = self.tableRows else { return [] }
        let mapping = sectionStepMapping(for: onboardingTaskType)
        return tableRows.enumerated().mapAndFilter({ (offset: Int, row: SBAOnboardingTableRow) -> [ORKStep]? in
            guard offset >= tableRow else { return nil }
            return row.onboardingSectionTypes.mapAndFilter({ mapping[$0] })
        }).flatMap({$0})
    }
    
    fileprivate func sectionStepMapping(for onboardingTaskType: SBAOnboardingTaskType) -> [SBAOnboardingSectionType : ORKStep] {
        guard let sections = self.sections else { return [:] }
        var mapping: [SBAOnboardingSectionType : ORKStep] = [:]
        for section in sections {
            if let sectionType = section.onboardingSectionType,
                let substeps = self.steps(for: section, with: onboardingTaskType), substeps.count > 0 {
                mapping[sectionType] = {
                    if substeps.count > 1 {
                        let subtask = SBANavigableOrderedTask(identifier: sectionType.identifier, steps: substeps)
                        return SBASubtaskStep(subtask: subtask)
                    }
                    else {
                        return substeps.first!
                    }
                }()
            }
        }
        return mapping
    }
    
    /**
     Allows subclasses of the onboarding manager to vend a different survey factory. By default, this will return the default
     factory as defined by the onboarding section.
     
     @param     section                 The onboarding section
     @param     onboardingTaskType      The task type
     @return                            Survey Factory
     */
    open func factory(for section: SBAOnboardingSection, with onboardingTaskType: SBAOnboardingTaskType) -> SBASurveyFactory {
        return section.defaultOnboardingSurveyFactory()
    }
    
    /**
     Get the steps that should be included for a given `SBAOnboardingSection` and `SBAOnboardingTaskType`.
     By default, this will return the steps created using the default onboarding survey factory for that section
     or nil if the steps for that section should not be included for the given task.
     
     @param     section               The onboarding section
     @param     onboardingTaskType    The task type
     @return    Optional array of `ORKStep`
    */
    open func steps(for section: SBAOnboardingSection, with onboardingTaskType: SBAOnboardingTaskType) -> [ORKStep]? {
        
        // Check to see that the steps for this section should be included
        guard shouldInclude(section: section, onboardingTaskType: onboardingTaskType) else { return nil }
        
        // Get the default factory
        let factory = self.factory(for: section, with: onboardingTaskType)
        
        // For consent, need to filter out steps that should not be included and group the steps into a substep. 
        // This is to facilitate skipping reconsent for a user who is logging in where it is unknown whether
        // or not the user needs to reconsent. Returned this way because the steps in a subclass of ORKOrderedTask 
        // are immutable but can be skipped using navigation rules.
        if let baseType = section.onboardingSectionType?.baseType(), baseType == .consent {
            switch (onboardingTaskType) {
            case .signup:
                return [factory.registrationConsentStep()]
            case .login:
                return [factory.loginConsentStep()]
            default:
                return [factory.reconsentStep()]
            }
        }
        
        // For all other cases, return the steps.
        return factory.steps
    }
    
    /**
     When initializing an onboarding manager with either an embedded json file or a dictionary,
     the sections returned in that dictionary will be sorted according to this function. By default,
     this sort function will ensure that the sections conforming to `SBAOnboardingSectionBaseType`
     are ordered as needed to ensure the proper sequence of login, consent and registration according
     to their ordinal position. All custom sections are left in the order they were included in the 
     original dictionary.
     @return    `true` if left precedes right in order, `false` if same or right precedes left
    */
    open func sortOrder(_ lhs: SBAOnboardingSection, _ rhs: SBAOnboardingSection) -> Bool {
        guard let lhsType = lhs.onboardingSectionType, let rhsType = rhs.onboardingSectionType else { return false }
        switch (lhsType, rhsType) {
        case (.base(let lhsValue), .base(let rhsValue)):
            return lhsValue.ordinal() < rhsValue.ordinal();
        default:
            return false
        }
    }
    
    /**
     Define the rules for including a given section in a given task type.
     
     @param     section              The section to be included
     @param     onboardingTaskType   The onboarding task type
     @return    `true` if the `SBAOnboardingSection` should be included for this `SBAOnboardingTaskType`
    */
    open func shouldInclude(section: SBAOnboardingSection, onboardingTaskType: SBAOnboardingTaskType) -> Bool {
        
        guard let baseType = section.onboardingSectionType?.baseType() else {
            // By default, ONLY Registration and verification should include any custom section
            return onboardingTaskType == .signup
        }
        
        switch (baseType) {
            
        case .login:
            // Only Login includes login
            return (onboardingTaskType == .login)
            
        case .consent:
            // All types *except* email verification include consent
            return (onboardingTaskType != .signup) || !sharedUser.isRegistered
            
        case .eligibility, .registration:
            // Intro, eligibility and registration are only included in registration
            return (onboardingTaskType == .signup) && !sharedUser.isRegistered
        
        case .passcode:
            // Passcode is included if it has not already been set
            return !hasPasscode
        
        case .emailVerification:
            // Only registration where the login has not been verified includes verification
            return (onboardingTaskType == .signup) && !sharedUser.isLoginVerified
        
        case .profile:
            // Additional profile information is included if this is a registration type
            return (onboardingTaskType == .signup)
        
        case .permissions, .completion:
            // Permissions and completion are included for login and registration
            return onboardingTaskType == .signup || onboardingTaskType == .login

        }
    }
    
    // MARK: Display data source
    
    fileprivate var signupStepMapping: [[ORKStep]] = []
    
    open func numberOfSteps(for tableRow: Int) -> Int {
        // TODO: syoung 04/12/2017 Implement
        return 0
    }
    
    open func signupState(for tableRow: Int) -> SBASignUpState {
        guard let currentStepIdentifier = self.sharedUser.onboardingStepIdentifier, let tableRows = self.tableRows else {
            return (tableRow == 0) ? .current : .locked
        }
        
        // setup the step mapping if the number of elements doesn't match
        if signupStepMapping.count != tableRows.count {
            self.signupStepMapping = {
                let mapping = self.sectionStepMapping(for: .signup)
                return tableRows.map { $0.onboardingSectionTypes.mapAndFilter { mapping[$0] } }
            }()
        }
        
        // look for the current row
        let currentRow: Int = {
            for (row, _) in tableRows.enumerated() {
                for step in signupStepMapping[row] {
                    if currentStepIdentifier.hasPrefix(step.identifier) {
                        // Found the section that the current step is in
                        if step == signupStepMapping[row].last {
                            // If this is the last step then look to see if this is a step that requires special-casing.
                            let currentStep: ORKStep? = {
                                if let subtaskStep = step as? SBASubtaskStep {
                                    return subtaskStep.isLast(with: currentStepIdentifier)
                                }
                                else {
                                    return step
                                }
                            }()
                            if currentStep is SBAEmailVerificationStep {
                                return self.sharedUser.isLoginVerified ? row + 1 : row
                            }
                            else if currentStep is ORKInstructionStep {
                                return row + 1
                            }
                        }
                        return row
                    }
                }
            }
            return tableRows.count
        }()
        
        return (currentRow < tableRow) ? .locked : (currentRow == tableRow) ? .current : .completed
    }

    // MARK: SBASharedInfoController
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // MARK: Passcode handling
    
    open var hasPasscode: Bool {
        return ORKPasscodeViewController.isPasscodeStoredInKeychain()
    }
    
    // MARK: ORKTaskResultSource
    
    open func stepResult(forStepIdentifier stepIdentifier: String) -> ORKStepResult? {
        
        guard let step = _taskViewController?.task?.step?(withIdentifier: stepIdentifier) else { return nil }
        
        // If this is a registration step with a name field and a currently available 
        // name stored for that field then return that result as a default.
        if let registrationStep = step as? SBARegistrationStep,
            let fullName = sharedNameDataSource?.fullName,
            let formItem = registrationStep.formItemForProfileInfoOption(.fullName)  {
            let nameResult = ORKTextQuestionResult(identifier: formItem.identifier)
            nameResult.textAnswer = fullName
            return ORKStepResult(stepIdentifier: stepIdentifier, results: [nameResult])
        }
        else if let registrationStep = step as? SBARegistrationStep,
            let givenName = sharedNameDataSource?.givenName,
            let givenFormItem = registrationStep.formItemForProfileInfoOption(.givenName),
            let familyName = sharedUser.familyName,
            let familyFormItem = registrationStep.formItemForProfileInfoOption(.familyName) {
    
            let givenNameResult = ORKTextQuestionResult(identifier: givenFormItem.identifier)
            givenNameResult.textAnswer = givenName
            let familyNameResult = ORKTextQuestionResult(identifier: familyFormItem.identifier)
            familyNameResult.textAnswer = familyName
            return ORKStepResult(stepIdentifier: stepIdentifier, results: [givenNameResult, familyNameResult])
        }
        
        return nil
    }
    
    // MARK: SBATaskViewControllerStrongReference
    
    weak fileprivate var _taskViewController: SBATaskViewController?
    
    public func attachTaskViewController(_ taskViewController: SBATaskViewController) {
        _taskViewController = taskViewController
        taskViewController.defaultResultSource = self
    }
    
    // MARK: NSSecureCoding
    
    public static var supportsSecureCoding : Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        guard let encodedSections = aDecoder.decodeObject(forKey: "sections") as? [NSDictionary] else { return }
        self.sections = encodedSections.map({ $0 as SBAOnboardingSection })
    }
    
    open func encode(with aCoder: NSCoder) {
        guard let encodableSections = self.sections?.map({ $0.dictionaryRepresentation() as NSDictionary }) else { return }
        aCoder.encode(encodableSections, forKey: "sections")
    }
    
    // MARK: Deprecated methods
    
    @available(*, deprecated)
    open func initializeTaskViewController(onboardingTaskType: SBAOnboardingTaskType) -> SBATaskViewController? {
        return initializeTaskViewController(for: onboardingTaskType)
    }
    
    @available(*, deprecated)
    open func section(onboardingSectionType sectionType: SBAOnboardingSectionType) -> SBAOnboardingSection? {
        return section(for: sectionType)
    }
    
    @available(*, deprecated)
    open func steps(section: SBAOnboardingSection, onboardingTaskType: SBAOnboardingTaskType) -> [ORKStep]? {
        return steps(for: section, with: onboardingTaskType)
    }

}

extension SBASubtaskStep {
    func isLast(with stepIdentifier: String) -> ORKStep? {
        guard let step = self.step(withIdentifier: stepIdentifier) else {
            return nil
        }
        let next: ORKStep? = self.stepAfterStep(step, withResult: ORKTaskResult(identifier: self.identifier))
        return (next == nil) ? step : nil
    }
}
