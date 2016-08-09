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

public class SBAPermissionsStep: ORKTableStep, SBANavigationSkipRule {
    
    lazy public var permissionsManager: SBAPermissionsManager = {
        return SBAPermissionsManager.sharedManager()
    }()
    
    public var permissions: SBAPermissionsType {
        get {
            return SBAPermissionsType(items: self.items as? [UInt])
        }
        set(newValue) {
            self.items = newValue.items
        }
    }
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
        commonInit()
    }
    
    convenience init(inputItem: SBAFormStepSurveyItem) {
        self.init(identifier: inputItem.identifier)
        inputItem.mapStepValues(self)
        commonInit()
        // Set the permissions if they can be mapped
        self.permissions = inputItem.items?.reduce(SBAPermissionsType.None, combine: { (input, item) -> SBAPermissionsType in
            return input.union(SBAPermissionsType(key: item as? String))
        }) ?? .None
    }
    
    private func commonInit() {
        if self.title == nil {
            self.title = Localization.localizedString("SBA_PERMISSIONS_TITLE")
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func stepViewControllerClass() -> AnyClass {
        return SBAPermissionStepViewController.classForCoder()
    }
    
    public func allPermissionsAuthorized() -> Bool {
        guard let items = self.items as? [UInt] else { return true }
        for item in items {
            let permission = SBAPermissionsType(rawValue: item)
            // If permission has not yet been granted for a given type then show the step
            if !self.permissionsManager.isPermissionsGrantedForType(permission) {
                return false
            }
        }
        // If all the checked permissions have been granted then return
        return true
    }
    
    // MARK: SBANavigationSkipRule
    
    public func shouldSkip(result: ORKTaskResult, additionalTaskResults: [ORKTaskResult]?) -> Bool {
        return allPermissionsAuthorized()
    }
    
    // MARK: Cell overrides
    
    let cellIdentifier = "PermissionsCell"
    
    override public func reuseIdentifierForRowAtIndexPath(indexPath: NSIndexPath) -> String {
        return cellIdentifier
    }
    
    override public func registerCellsForTableView(tableView: UITableView) {
        tableView.registerClass(SBAMultipleLineTableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentifier)
    }
    
    override public func configureCell(cell: UITableViewCell, indexPath: NSIndexPath, tableView: UITableView) {
        guard let item = self.objectForRowAtIndexPath(indexPath) as? UInt,
            let multipleLineCell = cell as? SBAMultipleLineTableViewCell
        else {
            return
        }
        let permission = SBAPermissionsType(rawValue: item)
        multipleLineCell.titleLabel?.text = permissionsManager.permissionTitleForType(permission)
        multipleLineCell.subtitleLabel?.text = permissionsManager.permissionDescriptionForType(permission)
    }
}

extension SBAPermissionsType {
    
    init(items: [UInt]?) {
        let rawValue = items?.reduce(0, combine: |) ?? 0
        self.init(rawValue: rawValue)
    }
    
    init(key: String?) {
        guard let key = key else {
            self.init(rawValue: 0)
            return
        }
        switch key {
        case "camera":
            self.init(rawValue:SBAPermissionsType.Camera.rawValue)
        case "coremotion":
            self.init(rawValue:SBAPermissionsType.Coremotion.rawValue)
        case "healthKit":
            self.init(rawValue:SBAPermissionsType.HealthKit.rawValue)
        case "location":
            self.init(rawValue:SBAPermissionsType.Location.rawValue)
        case "localNotifications":
            self.init(rawValue:SBAPermissionsType.LocalNotifications.rawValue)
        case "microphone":
            self.init(rawValue:SBAPermissionsType.Microphone.rawValue)
        case "photoLibrary":
            self.init(rawValue:SBAPermissionsType.PhotoLibrary.rawValue)
        default:
            let intValue = UInt(key) ?? 0
            self.init(rawValue: intValue)
        }
    }
    
    var items: [UInt] {
        var items: [UInt] = []
        for ii in UInt(0)...UInt(16) {
            let rawValue = 1 << ii
            let member = SBAPermissionsType(rawValue: rawValue)
            if self.contains(member) {
                items.append(rawValue)
            }
        }
        return items
    }
}

public class SBAPermissionStepViewController: ORKTableStepViewController, SBALoadingViewPresenter {
    
    public var permissionsStep: SBAPermissionsStep? {
        return self.step as? SBAPermissionsStep
    }
    
    override public func goForward() {
        guard let items = self.permissionsStep?.items as? [UInt] else {
            assert(false, "Could not convert permission step items to permissions")
            super.goForward()
            return
        }
        
        // Show a loading view to indicate that something is happening
        self.showLoadingView()
        
        // Use a dispatch group to iterate through all the permissions and accept them as
        // a batch, showing an alert for each if not authorized.
        let dispatchGroup = dispatch_group_create()
        let permissionsManager = self.permissionsStep!.permissionsManager
        
        for item in items {
            let permission = SBAPermissionsType(rawValue: item)
            if !permissionsManager.isPermissionsGrantedForType(permission) {
                dispatch_group_enter(dispatchGroup)
                permissionsManager.requestPermissionForType(permission, withCompletion: { [weak self] (success, error) in
                    if (!success) {
                        dispatch_async(dispatch_get_main_queue(), { 
                            let title = Localization.localizedString("SBA_PERMISSIONS_FAILED_TITLE")
                            let message = error?.localizedDescription ?? Localization.localizedString("SBA_PERMISSIONS_FAILED_MESSAGE")
                            self?.showAlertWithOk(title, message: message, actionHandler: { (_) in
                                dispatch_group_leave(dispatchGroup)
                            })
                        })
                    }
                    else {
                        dispatch_group_leave(dispatchGroup)
                    }
                })
            }
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { [weak self] in
            self?.goNext()
        }
    }
    
    private func goNext() {
        super.goForward()
    }
}


