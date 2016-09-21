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

    lazy open var permissionsManager: SBAPermissionsManager = {
        return SBAPermissionsManager.shared
    }()
    
    open class func defaultPermissions() -> SBAPermissionsType {
        guard let appDelegate = UIApplication.shared.delegate as? SBAAppInfoDelegate else { return SBAPermissionsType() }
        return appDelegate.requiredPermissions
    }
    
    open var permissions: SBAPermissionsType {
        get {
            return SBAPermissionsType(items: self.items as? [UInt])
        }
        set(newValue) {
            self.items = newValue.items as [NSCopying & NSSecureCoding & NSObjectProtocol]?
        }
    }
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
        commonInit()
    }
    
    convenience init?(inputItem: SBASurveyItem) {
        guard let survey = inputItem as? SBAFormStepSurveyItem else { return nil }
        self.init(identifier: inputItem.identifier)
        survey.mapStepValues(with: self)
        commonInit()
        // Set the permissions if they can be mapped
        self.permissions = survey.items?.reduce(SBAPermissionsType(), { (input, item) -> SBAPermissionsType in
            return input.union(SBAPermissionsType(key: item as? String))
        }) ?? SBAPermissionsStep.defaultPermissions()
    }
    
    fileprivate func commonInit() {
        if self.title == nil {
            self.title = Localization.localizedString("SBA_PERMISSIONS_TITLE")
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func stepViewControllerClass() -> AnyClass {
        return SBAPermissionsStepViewController.classForCoder()
    }
    
    open func allPermissionsAuthorized() -> Bool {
        guard let items = self.items as? [UInt] else { return true }
        for item in items {
            let permission = SBAPermissionsType(rawValue: item)
            // If permission has not yet been granted for a given type then show the step
            if !self.permissionsManager.isPermissionsGranted(for: permission) {
                return false
            }
        }
        // If all the checked permissions have been granted then return
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
        guard let item = self.objectForRow(at: indexPath) as? UInt,
            let multipleLineCell = cell as? SBAMultipleLineTableViewCell
        else {
            return
        }
        let permission = SBAPermissionsType(rawValue: item)
        multipleLineCell.titleLabel?.text = permissionsManager.permissionTitle(for: permission)
        multipleLineCell.subtitleLabel?.text = permissionsManager.permissionDescription(for: permission)
    }
}

open class SBAPermissionsStepViewController: ORKTableStepViewController, SBALoadingViewPresenter {
    
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
        let permissions = permissionsStep.permissions
        permissionsManager.requestPermissions(permissions, alertPresenter: self) { [weak self] (granted) in
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
        // Overrride the cancel button to *not* display. User must tap the "Done" button.
        get { return nil }
        set {}
    }
}
