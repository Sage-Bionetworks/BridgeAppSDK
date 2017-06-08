//
//  SBASinglePermissionStep.swift
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

open class SBASinglePermissionStep: ORKInstructionStep, SBANavigationSkipRule {
    
    /**
     Permission type to request for this step of the task.
     */
    open dynamic var permissionType: SBAPermissionObjectType!
    
    /**
     Text to show for the continue button.
     */
    open dynamic var buttonTitle: String?
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    public init(permissionsStep: SBAPermissionsStep, index: Int) {
        let permission = permissionsStep.permissionTypes[index]
        super.init(identifier: "\(permissionsStep.identifier).\(permission.identifier)")
        
        self.permissionType = permission
        
        self.title = permissionsStep.title
        self.text = permission.title
        self.detailText = permission.detail
        
        commonInit()
    }
    
    public init?(inputItem: SBASurveyItem) {
        guard let survey = inputItem as? SBAFormStepSurveyItem, let items = survey.items, items.count == 1,
            let permission = SBAPermissionsManager.shared.permissionsTypeFactory.permissionTypes(for: items).first
            else {
                return nil
        }
        super.init(identifier: inputItem.identifier)
        
        self.permissionType = permission
        
        self.title = inputItem.stepTitle?.trim()
        self.text = inputItem.stepText?.trim()
        self.footnote = inputItem.stepFootnote?.trim()
        self.isOptional = survey.optional
        
        if let surveyItem = inputItem as? SBAInstructionStepSurveyItem {
            self.detailText = surveyItem.stepDetail?.trim() ?? permission.detail
            self.image = surveyItem.stepImage
            self.iconImage = surveyItem.iconImage
        }
        if let dictionary = inputItem as? NSDictionary {
            let key = #keyPath(buttonTitle)
            self.buttonTitle = dictionary[key] as? String
        }
        
        commonInit()
    }
    
    open func commonInit() {
        
        // Set the button title to default if not defined
        if self.buttonTitle == nil {
            switch (self.permissionType.permissionType) {
                
            case SBAPermissionTypeIdentifier.coremotion:
                self.buttonTitle = Localization.localizedString("PERMISSION_BUTTON_MOTION")
                
            case SBAPermissionTypeIdentifier.healthKit:
                self.buttonTitle = Localization.localizedString("PERMISSION_BUTTON_HEALTHKIT")
                
            case SBAPermissionTypeIdentifier.location:
                self.buttonTitle = Localization.localizedString("PERMISSION_BUTTON_LOCATION")
                
            case SBAPermissionTypeIdentifier.microphone:
                self.buttonTitle = Localization.localizedString("PERMISSION_BUTTON_LOCATION")
                
            case SBAPermissionTypeIdentifier.camera:
                self.buttonTitle = Localization.localizedString("PERMISSION_BUTTON_CAMERA")
             
            default:
                if let title = self.permissionType.title {
                 self.buttonTitle = Localization.localizedStringWithFormatKey("PERMISSION_BUTTON_FORMAT_%@", title as NSString)
                }
            }
        }
        
        // If no image is defined, then look to see if the image can be mapped from an asset
        // with a special-case naming. These assets are not defined in the framework b/c 
        // they are not all needed (only for certain modules) and the colors and image context
        // will need to be customized to the app. However, b/c the permissions are automatically
        // added to ResearchKit tasks that require them, include here as a backup.
        if self.image == nil {
            self.image = SBAResourceFinder.shared.image(forResource: "\(self.permissionType.identifier)Permission")
        }
        
        // If the detail text isn't set then use the permission detail
        if self.detailText == nil {
            self.detailText = self.permissionType.detail
        }
    }
    
    open override func isInstructionStep() -> Bool {
        return true
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return SBASinglePermissionStepViewController.classForCoder()
    }
    
    // MARK: SBANavigationSkipRule
    
    open func shouldSkipStep(with result: ORKTaskResult, and additionalTaskResults: [ORKTaskResult]?) -> Bool {
        return SBAPermissionsManager.shared.isPermissionGranted(for: self.permissionType)
    }
    
    // MARK: NSCopy
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let step = copy as? SBASinglePermissionStep else { return copy }
        step.permissionType = self.permissionType
        step.buttonTitle = self.buttonTitle
        return step
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.permissionType = aDecoder.decodeObject(forKey: #keyPath(permissionType)) as! SBAPermissionObjectType
        self.buttonTitle = aDecoder.decodeObject(forKey: #keyPath(buttonTitle)) as? String
    }
    
    override open func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.permissionType, forKey: #keyPath(permissionType))
        aCoder.encode(self.buttonTitle, forKey: #keyPath(buttonTitle))
    }
    
    // MARK: Equality
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBASinglePermissionStep else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(self.permissionType, object.permissionType) &&
            SBAObjectEquality(self.buttonTitle, object.buttonTitle)
    }
    
    override open var hash: Int {
        return super.hash ^
            SBAObjectHash(self.permissionType) ^
            SBAObjectHash(buttonTitle)
    }

}
