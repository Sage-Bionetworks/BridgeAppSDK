//
//  SBAPermissionsStep.swift
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

import ResearchKit

open class SBAPermissionsStep: ORKTableStep, SBANavigationSkipRule {

    /**
     Manager for handling requesting permissions
    */
    open var permissionsManager: SBAPermissionsManager {
        return SBAPermissionsManager.shared
    }
    
    /**
     Permission types to request for this step of the task.
    */
    open var permissionTypes: [SBAPermissionObjectType] {
        get {
            return self.items as? [SBAPermissionObjectType] ?? []
        }
        set {
            self.items = newValue
        }
    }
    
    @available(*, deprecated, message: "use `permissionTypes` instead")
    open var permissions: SBAPermissionsType {
        get {
            return permissionsManager.permissionsType(for: self.permissionTypes)
        }
        set {
            self.items = permissionsManager.typeObjectsFor(for: newValue)
        }
    }
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
        commonInit()
    }
    
    public init(identifier: String, permissions: [SBAPermissionTypeIdentifier]) {
        super.init(identifier: identifier)
        self.items = self.permissionsManager.permissionsTypeFactory.permissionTypes(for: permissions)
        commonInit()
    }
    
    convenience init?(inputItem: SBASurveyItem) {
        guard let survey = inputItem as? SBAFormStepSurveyItem else { return nil }
        self.init(identifier: inputItem.identifier)
        survey.mapStepValues(with: self)
        self.items = self.permissionsManager.permissionsTypeFactory.permissionTypes(for: survey.items)
        commonInit()
    }
    
    fileprivate func commonInit() {
        if self.title == nil {
            self.title = Localization.localizedString("SBA_PERMISSIONS_TITLE")
        }
        if self.items == nil {
            self.items = self.permissionsManager.defaultPermissionTypes
        }
        else if let healthKitPermission = self.permissionTypes.find({ $0.permissionType == .healthKit }) as? SBAHealthKitPermissionObjectType,
            (healthKitPermission.healthKitTypes == nil) || healthKitPermission.healthKitTypes!.count == 0,
            let replacement = permissionsManager.defaultPermissionTypes.find({ $0.permissionType == .healthKit }) as? SBAHealthKitPermissionObjectType {
            // If this is a healthkit step and the permission types are not defined, 
            // then look in the default permission types for the default types to include.
            healthKitPermission.healthKitTypes = replacement.healthKitTypes
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func stepViewControllerClass() -> AnyClass {
        return SBAPermissionsStepViewController.classForCoder()
    }
    
    open func allPermissionsAuthorized() -> Bool {
        for permissionType in permissionTypes {
            if !self.permissionsManager.isPermissionGranted(for: permissionType) {
                return false
            }
        }
        return true
    }
    
    // MARK: SBANavigationSkipRule
    
    open func shouldSkipStep(with result: ORKTaskResult, and additionalTaskResults: [ORKTaskResult]?) -> Bool {
        return allPermissionsAuthorized()
    }
    
    // MARK: Cell overrides
    
    let cellIdentifier = "PermissionsCell"
    
    override open func reuseIdentifierForRow(at indexPath: IndexPath) -> String {
        return cellIdentifier
    }
    
    override open func registerCells(for tableView: UITableView) {
        tableView.register(SBAMultipleLineTableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentifier)
    }
    
    override open func configureCell(_ cell: UITableViewCell, indexPath: IndexPath, tableView: UITableView) {
        guard let item = self.objectForRow(at: indexPath) as? SBAPermissionObjectType,
            let multipleLineCell = cell as? SBAMultipleLineTableViewCell
        else {
            return
        }
        multipleLineCell.titleLabel?.text = item.title
        multipleLineCell.subtitleLabel?.text = item.detail
    }
}

open class SBAPermissionsStepViewController: ORKTableStepViewController {
    
    var permissionsGranted: Bool = false
    
    override open var result: ORKStepResult? {
        guard let result = super.result else { return nil }
        
        // Add a result for whether or not the permissions were granted
        let grantedResult = ORKBooleanQuestionResult(identifier: result.identifier)
        grantedResult.booleanAnswer = NSNumber(value: permissionsGranted)
        result.results = [grantedResult]
        
        return result
    }
    
    override open func goForward() {
        guard let permissionsStep = self.step as? SBAPermissionsStep else {
            assertionFailure("Step is not of expected type")
            super.goForward()
            return
        }
        
        // Show a loading view to indicate that something is happening
        self.showLoadingView()
        let permissionsManager = permissionsStep.permissionsManager
        let permissions = permissionsStep.permissionTypes
        permissionsManager.requestPermissions(for: permissions, alertPresenter: self) { [weak self] (granted) in
            if granted || permissionsStep.isOptional {
                self?.permissionsGranted = granted
                self?.goNext()
            }
            else if let strongSelf = self, let strongDelegate = strongSelf.delegate {
                let error = NSError(domain: "SBAPermissionsStepDomain", code: 1, userInfo: nil)
                strongDelegate.stepViewControllerDidFail(strongSelf, withError: error)
            }
        }
    }
    
    fileprivate func goNext() {
        super.goForward()
    }
    
    open override var cancelButtonItem: UIBarButtonItem? {
        // Override the cancel button to *not* display. User must tap the "Continue" button.
        get { return nil }
        set {}
    }
}
