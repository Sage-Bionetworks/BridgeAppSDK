//
//  SBASignUpViewController.swift
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

import UIKit

public enum SBASignUpState {
    case current, completed, locked
}

/**
 The `SBASignUpViewController` can be used to display a table view or collection view with an
 overview of the user's onboarding progress.
 */
open class SBASignUpViewController : UIViewController, SBASharedInfoController, ORKTaskViewControllerDelegate {
    
    @IBOutlet open var greetingLabel: UILabel?
    @IBOutlet open var instructionLabel: UILabel?
    
    @IBOutlet weak var cancelButtonView: UIView?
    @IBOutlet weak var startButtonView: UIView?
    
    public var taskViewController: ORKTaskViewController? {
        return _taskViewController
    }
    fileprivate var _taskViewController: ORKTaskViewController?
    
    /**
     The onboarding manager to use with this signup view controller. By default, this will retain 
     an onboarding manager instantiated by the `SBAOnboardingAppDelegate`.
     */
    open var onboardingManager: SBAOnboardingManager {
        if (_onboardingManager == nil) {
            _onboardingManager = self.onboardingAppDelegate.onboardingManager(for: .signup)
        }
        return _onboardingManager
    }
    fileprivate var _onboardingManager: SBAOnboardingManager!
    
    /**
     List of the profile keys that are updated during onboarding
     */
    lazy open var profileKeys: [String] = {
        guard let profileKeys = SBAProfileManager.shared?.profileKeys() else { return [] }
        // By default, do not include keys that are handled during registration and consent
        let excludeKeys: [SBAProfileInfoOption] = [.fullName, .familyName, .givenName, .email, .password]
        let filteredKeys = Set(profileKeys).subtracting(excludeKeys.map{ $0.rawValue })
        return Array(filteredKeys)
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.appBackgroundDark
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateState()
    }
    
    /**
     Update the state of the view controller.
     */
    open func updateState() {
        
        // Set up the greeting label
        greetingLabel?.text = {
            guard let name = self.sharedNameDataSource?.givenName else {
                return Localization.localizedString("GREETING_WITHOUT_NAME")
            }
            return String.localizedStringWithFormat(Localization.localizedString("GREETING_WITH_NAME_%@"), name)
        }()
        
        let signupCompleted = (self.sharedUser.onboardingStepIdentifier == SBAOnboardingManager.completedIdentifier)
        self.cancelButtonView?.isHidden = signupCompleted
        self.startButtonView?.isHidden = !signupCompleted
        self.instructionLabel?.text = signupCompleted ? onboardingManager.tableHeader?.completedText : onboardingManager.tableHeader?.initialText
    }
    
    /**
     Number of rows in the data source.
     */
    public var numberOfRows: Int {
        return self.onboardingManager.tableRows?.count ?? 0
    }
    
    /**
     Returns the table row item at the given row.
     
     @param row     The row of the item
     @return        Item at the given row
     */
    public func item(at row:Int) -> SBAOnboardingTableRow? {
        return self.onboardingManager.tableRows?[row]
    }
    
    /**
     Set up the cell for the given row. This is used to assign values to either a subclass of a 
     `UITableViewCell` or `UICollectionViewCell`.
     
     @param cell    The cell to set up
     @param row     The row of the cell
     */
    open func setupCell(_ cell: SBASignUpCell, at row:Int) {
        guard let item = self.item(at: row) else { return }
        
        cell.titleLabel.text = item.title
        cell.detailLabel.text = item.text
        
        let signupState = self.onboardingManager.signupState(for: row)
        
        // Set up the number of steps
        let numSteps = self.onboardingManager.numberOfSteps(for: row)
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        if (signupState != .completed), numSteps > 0, let numStepsString = formatter.string(for: numSteps) {
            let format = Localization.localizedString("SBA_SHORT_NUMBER_OF_STEPS_%@")
            cell.numberOfStepsLabel?.text = String.localizedStringWithFormat(format, numStepsString)
            cell.numberOfStepsLabel?.isHidden = false
        } else {
            cell.numberOfStepsLabel?.isHidden = true
        }
        
        // toggle whether or not the row is completed
        cell.checkmarkImageView?.image = {
            switch signupState {
            case .completed:
                return SBAResourceFinder.shared.image(forResource: "signup_completion_checkmark")
            case .locked:
                return SBAResourceFinder.shared.image(forResource: "signup_locked")
            default:
                return nil
            }
        }()
    }
    
    /**
     Can the given row be selected?
     
     @param row  The row for the cell
     @return     Whether or not the row can be selected
     */
    open func canSelectRow(_ row : Int) -> Bool {
        return self.onboardingManager.signupState(for: row) == .current
    }
    
    /**
     Call when the user did select the given row.
     
     @param row  The row for the cell
     */
    open func didSelectRow(_ row : Int) {
        guard let taskViewController = onboardingManager.initializeTaskViewController(for: .signup, tableRow: row)
        else {
            assertionFailure("Failed to create an onboarding manager.")
            return
        }
        
        // present the onboarding
        _taskViewController = taskViewController
        taskViewController.delegate = self
        self.present(taskViewController, animated: true, completion: nil)
    }
    
    /**
     Connect to the cancel action.
     */
    @IBAction open func cancelTapped() {
        self.sharedUser.resetStoredUserData()
        self.onboardingAppDelegate.showAppropriateViewController(animated: true)
    }
    
    /**
     Connect to the action to start the study.
     */
    @IBAction open func startStudyTapped() {
        self.sharedUser.onboardingStepIdentifier = nil
        self.onboardingAppDelegate.showAppropriateViewController(animated: true)
    }
    
    
    // MARK: ORKTaskViewControllerDelegate
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        self.sharedUser.onboardingStepIdentifier = stepViewController.step?.identifier
        stepViewController.cancelButtonItem = UIBarButtonItem(title: Localization.localizedString("BUTTON_CLOSE"),
                                                              style: .done,
                                                              target: self,
                                                              action: #selector(closeTaskAction))
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillDisappear stepViewController: ORKStepViewController, navigationDirection direction: ORKStepViewControllerNavigationDirection) {
        if direction == .forward, profileKeys.count > 0 {
            // If going forward, then update the profile with the matching keys
            stepViewController.update(participantInfo: self.sharedUser, with: profileKeys)
            
            // If this is a data groups step *and* the user is not registered, then update the data groups that 
            // are stored locally on the user. These data groups will be submitted with the registration.
            if !sharedUser.isLoginVerified,
                let dataGroupsStep = stepViewController.step as? SBADataGroupsStepProtocol,
                let stepResult = stepViewController.result {
                 sharedUser.dataGroups = Array(dataGroupsStep.union(previousGroups: sharedUser.dataGroups, stepResult: stepResult))
            }
        }
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        var shouldReset = false
        if reason == .completed {
            if sharedUser.isLoginVerified {
                // If the flow was completed then set the completion identifier for the onboarding step
                self.sharedUser.onboardingStepIdentifier = SBAOnboardingManager.completedIdentifier
                
                // Commit any tracked data changes (data store and data groups)
                taskViewController.task?.commitTrackedDataChanges(user: sharedUser, taskResult: taskViewController.result, completion:nil)
            }
            else {
                // If the flow exits with "complete" status but login isn't verified,
                // then the user is not eligibile.
                shouldReset = true
            }
        }
        else if reason == .failed, let err = error as? SBAProfileInfoOptionsError, err == .notConsented {
            // If the user declined consent then need to reset the stored user data and the onboarding steps
            shouldReset = true
        }
        
        if shouldReset {
            self.sharedUser.resetStoredUserData()
            self.sharedUser.onboardingStepIdentifier = nil
        }
        
        taskViewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: ORKTaskViewController customization
    
    func closeTaskAction() {
        guard let taskViewController = self.taskViewController else { return }
        self.taskViewController(taskViewController, didFinishWith: .discarded, error: nil)
    }
    
    // MARK: SBASharedInfoController
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    open var onboardingAppDelegate: SBAOnboardingAppDelegate {
        return self.sharedAppDelegate as! SBAOnboardingAppDelegate
    }
}

public protocol SBASignUpCell : class {
    var titleLabel: UILabel! { get set }
    var detailLabel: UILabel! { get set }
    var numberOfStepsLabel: UILabel? { get set }
    var checkmarkImageView: UIImageView? { get set }
}

open class SBASignUpTableCell : UITableViewCell, SBASignUpCell {
    @IBOutlet weak public var titleLabel: UILabel!
    @IBOutlet weak public var detailLabel: UILabel!
    @IBOutlet weak public var numberOfStepsLabel: UILabel?
    @IBOutlet weak public var checkmarkImageView: UIImageView?
}

open class SBASignUpTableViewController : SBASignUpViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet public weak var tableView: UITableView!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure that the data source and the delegate are set up to point to self
        if (self.tableView.dataSource == nil) {
            self.tableView.dataSource = self
        }
        if (self.tableView.delegate == nil) {
            self.tableView.delegate = self
        }
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }
    
    func sizeHeaderToFit() {
        let headerView = tableView.tableHeaderView!
        
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        var frame = headerView.frame
        frame.size.height = height
        headerView.frame = frame
        
        tableView.tableHeaderView = headerView
    }
    
    override open func updateState() {
        super.updateState()
        self.tableView.reloadData()
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SignUpTableCell", for: indexPath) as? SBASignUpTableCell
        else {
            assertionFailure("Missing expected cell reuse identifier: 'SignUpTableCell'")
            return UITableViewCell()
        }
        self.setupCell(cell, at: indexPath.row)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return self.canSelectRow(indexPath.row) ? indexPath : nil
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didSelectRow(indexPath.row)
    }
}




