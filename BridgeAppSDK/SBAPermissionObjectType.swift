//
//  SBAPermissionObjectType.swift
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

import Foundation
import HealthKit

/**
 Factory for creating `SBAPermissionObjectType` instances.
 
 `String` keys are defined with a mapping for:
    "healthKit"
    "location"
    "notifications"
    "coremotion"
    "microphone"
    "camera"
    "photoLibrary"
 
 A dictionary of type `[String : Any]` can map to object types where:
 
    SBAPermissionObjectType
    "identifier" = `String` value from the list defined above
 
    SBANotificationPermissionObjectType
    "notificationTypes" = ["alert", "badge", "sound"], Default = ["alert", "badge", "sound"]
 
    SBALocationPermissionObjectType
    "always" = true/false, Default = false
 
    SBAHealthKitPermissionObjectType
    "healthKitTypes" = [SBAHealthKitProfileObject<String or [String : Any]>]
 
        SBAHealthKitProfileObject
        "identifier" = valid HKObjectTypeIdentifier
        "profileKey" = mapping to a key in the user profile (optional), Default = nil
        "readonly" = true/false, Default = false
 
 */
open class SBAPermissionObjectTypeFactory: NSObject {
    
    @objc
    open func permissionTypes(for items:[Any]?) -> [SBAPermissionObjectType] {
        guard let inputItems = items else { return [] }
        return inputItems.map({ self.permissionType(for: $0) })
    }
    
    @objc
    open func permissionType(for item:Any) -> SBAPermissionObjectType {
        if let identifier = item as? String {
            // If the item is a string then create a permission object for the given identifier
            return self.permissionType(with: SBAPermissionTypeIdentifier(rawValue: identifier))
        }
        else if let permissionTypeIdentifier = item as? SBAPermissionTypeIdentifier {
            // If this is a permission type identifier enum then return type for that
            return self.permissionType(with: permissionTypeIdentifier)
        }
        else if let dictionary = item as? [String : Any] {
            // If this is a dictionary, first look to see if the class type map includes a non-nil
            // object for this dictionary
            if let permissionType = SBAClassTypeMap.shared.object(with: dictionary) as? SBAPermissionObjectType {
                return permissionType
            }
            // Otherwise, look for an identifier and use that to get the permission type
            // Then set the values from the dictionary using KVO
            else if let identifier = dictionary["identifier"] as? String {
                let permissionType = self.permissionType(with: SBAPermissionTypeIdentifier(rawValue: identifier))
                permissionType.setValuesForKeys(dictionary)
                return permissionType
            }
        }
        
        // Define a default but assert on unrecognized type
        assertionFailure("Unrecognized item type: \(item)")
        return SBAPermissionObjectType(identifier: "unknown")
    }
    
    fileprivate func permissionType(with permissionTypeIdentifier:SBAPermissionTypeIdentifier) -> SBAPermissionObjectType {
        switch (permissionTypeIdentifier) {
        case SBAPermissionTypeIdentifier.notifications:
            return SBANotificationPermissionObjectType(permissionType: permissionTypeIdentifier)
        case SBAPermissionTypeIdentifier.location:
            return SBALocationPermissionObjectType(permissionType: permissionTypeIdentifier)
        case SBAPermissionTypeIdentifier.healthKit:
            return SBAHealthKitPermissionObjectType(permissionType: permissionTypeIdentifier)
        default:
            return SBAPermissionObjectType(permissionType: permissionTypeIdentifier)
        }
    }
}

/**
 Base class for creating a permission type object. This object stores information about how
 to display the permission (of a given type).
 */
open class SBAPermissionObjectType: SBADataObject {
    
    open var permissionType: SBAPermissionTypeIdentifier {
        return SBAPermissionTypeIdentifier(rawValue: self.identifier)
    }
    
    open dynamic var title: String?
    open dynamic var detail: String?
    
    override open func dictionaryRepresentationKeys() -> [String] {
        var keys = super.dictionaryRepresentationKeys()
        keys.append(#keyPath(title))
        keys.append(#keyPath(detail))
        return keys
    }
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        commonInit()
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public required init(dictionaryRepresentation dictionary: [AnyHashable : Any]) {
        super.init(dictionaryRepresentation: dictionary)
        commonInit()
    }
    
    public init(permissionType: SBAPermissionTypeIdentifier) {
        super.init(identifier: permissionType.rawValue)
        commonInit()
    }
    
    fileprivate func commonInit() {
        if self.title == nil {
            self.title = self.permissionType.defaultTitle()
        }
        if self.detail == nil {
            self.detail = self.permissionType.defaultDescription()
        }
    }
}

extension UIUserNotificationType {
    init(keys: [String]) {
        let rawValue = keys.map({ (name) -> UInt in
            switch (name) {
            case "alert":
                return UIUserNotificationType.alert.rawValue
            case "badge":
                return UIUserNotificationType.badge.rawValue
            case "sound":
                return UIUserNotificationType.sound.rawValue
            default:
                return 0
            }
        }).reduce(0, |)
        self.init(rawValue: rawValue)
    }
}

/**
 The `SBANotificationPermissionObjectType` is used to define information for permission
 handling that is specific to requesting permission to send the user notifications.
 */
public final class SBANotificationPermissionObjectType: SBAPermissionObjectType {
    
    class func localNotifications() -> SBANotificationPermissionObjectType {
        return SBANotificationPermissionObjectType(permissionType: .notifications)
    }
    
    override open func defaultIdentifierIfNil() -> String {
        return SBAPermissionTypeIdentifier.notifications.rawValue
    }
    
    public var categories: Set<UIUserNotificationCategory>?
    
    public dynamic var notificationTypes: UIUserNotificationType = [.alert, .badge, .sound]
    
    override public func dictionaryRepresentation() -> [AnyHashable : Any] {
        var dictionary = super.dictionaryRepresentation()
        let keyPath = #keyPath(notificationTypes)
        dictionary[keyPath] = notificationTypes.rawValue
        return dictionary
    }
    
    override public func setValue(_ value: Any?, forKey key: String) {
        switch (key) {
        case #keyPath(notificationTypes):
            customSetNotificationTypes(value)
        default:
            super.setValue(value, forKey: key)
        }
    }
    
    fileprivate func customSetNotificationTypes(_ value: Any?) {
        if let types = value as? UIUserNotificationType {
            self.notificationTypes = types
        }
        else if let types = value as? UInt {
            self.notificationTypes = UIUserNotificationType(rawValue: types)
        }
        else if let types = value as? [String] {
            self.notificationTypes = UIUserNotificationType(keys: types)
        }
        else {
            assertionFailure("Failed to convert \(value) to UIUserNotificationType")
        }
    }
}

/**
 The `SBALocationPermissionObjectType` is used to define information for permission
 handling that is specific to requesting permission to access the user's location.
 */
public final class SBALocationPermissionObjectType: SBAPermissionObjectType {
    
    public dynamic var always: Bool = true
    
    override open func defaultIdentifierIfNil() -> String {
        return SBAPermissionTypeIdentifier.location.rawValue
    }
    
    override public func dictionaryRepresentationKeys() -> [String] {
        var keys = super.dictionaryRepresentationKeys()
        keys.append(#keyPath(always))
        return keys
    }
}

/**
 The `SBAHealthKitPermissionObjectType` is used to define information for permission
 handling that is specific to requesting permission to access the user's health data.
 */
public final class SBAHealthKitPermissionObjectType: SBAPermissionObjectType {
    
    /**
     The collection of health kit data types that are being requested.
    */
    public dynamic var healthKitTypes: [SBAHealthKitProfileObject]?
    
    public var writeTypes: Set<HKSampleType>? {
        guard let profileObjects = healthKitTypes else { return nil }
        return Set(profileObjects.mapAndFilter({ (profileObject) -> HKSampleType? in
            guard !profileObject.readonly else { return nil }
            return profileObject._hkObjectType as? HKSampleType
        }))
    }
    
    public var readTypes: Set<HKObjectType>? {
        guard let profileObjects = healthKitTypes else { return nil }
        return Set(profileObjects.mapAndFilter({ (profileObject) -> HKObjectType? in
            return profileObject._hkObjectType
        }))
    }

    override open func defaultIdentifierIfNil() -> String {
        return SBAPermissionTypeIdentifier.healthKit.rawValue
    }
    
    override public func dictionaryRepresentationKeys() -> [String] {
        var keys = super.dictionaryRepresentationKeys()
        keys.append(#keyPath(healthKitTypes))
        return keys
    }
    
    override public func setValue(_ value: Any?, forKey key: String) {
        switch (key) {
            
        case #keyPath(healthKitTypes):
            let items = value as? [Any]
            healthKitTypes = items?.mapAndFilter({ (item) -> SBAHealthKitProfileObject? in
                if let profileObject = item as? SBAHealthKitProfileObject {
                    return profileObject
                }
                
                // Look for the item to be either a string or dictionary
                let profileObject: SBAHealthKitProfileObject? = {
                    if let typeIdentifier = item as? String {
                        return SBAHealthKitProfileObject(identifier: typeIdentifier)
                    }
                    else if let dictionary = item as? [String : Any] {
                        return SBAHealthKitProfileObject(dictionaryRepresentation: dictionary)
                    }
                    return nil
                }()
                
                // Nil out if the health type is not nl
                guard profileObject?._hkObjectType != nil else {
                    return nil
                }
                
                return profileObject
            })

        default:
            super.setValue(value, forKey: key)
        }
    }
}

/**
 Model object for storing iformation about each healthkit type for which the app needs 
 read/write accesss.
 */
public final class SBAHealthKitProfileObject: SBADataObject {
    
    public dynamic var profileKey: String?
    public dynamic var readonly: Bool = false
    
    override public func dictionaryRepresentationKeys() -> [String] {
        var keys = super.dictionaryRepresentationKeys()
        keys.append(#keyPath(profileKey))
        keys.append(#keyPath(readonly))
        return keys
    }
    
    public var hkObjectType: HKObjectType! {
        return _hkObjectType
    }
    lazy fileprivate var _hkObjectType: HKObjectType? = {
        
        // Check if this is a quantity type
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: self.identifier)
        if let type = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier) {
            return type
        }
        
        // Check if this is a category type
        let categoryTypeIdentifier = HKCategoryTypeIdentifier(rawValue: self.identifier)
        if let type = HKObjectType.categoryType(forIdentifier: categoryTypeIdentifier) {
            return type
        }
        
        // Check if this is a characteristic type
        let characteristicTypeIdentifier = HKCharacteristicTypeIdentifier(rawValue: self.identifier)
        if let type = HKObjectType.characteristicType(forIdentifier: characteristicTypeIdentifier) {
            return type
        }
        
        // Check if this is a correlation type
        let correlationTypeIdentifier = HKCorrelationTypeIdentifier(rawValue: self.identifier)
        if let type = HKObjectType.correlationType(forIdentifier: correlationTypeIdentifier) {
            return type
        }
        
        // open class func workoutType() -> HKWorkoutType
        let workoutTypeIdentifier = String(describing: HKWorkoutType.classForCoder())
        if self.identifier == workoutTypeIdentifier {
            return HKObjectType.workoutType()
        }
        
        guard #available(iOS 9.3, *) else { return nil }
        let activitySummaryTypeIdentifier = String(describing: HKActivitySummaryType.classForCoder())
        if self.identifier == activitySummaryTypeIdentifier {
            return HKObjectType.activitySummaryType()
        }
        
        guard #available(iOS 10, *) else { return nil }
        let documentTypeIdentifier = HKDocumentTypeIdentifier(rawValue: self.identifier)
        if let type = HKObjectType.documentType(forIdentifier: documentTypeIdentifier) {
            return type
        }
        
        return nil
    }()
}

extension SBAPermissionTypeIdentifier {
    
    /**
     Returns the default title to use for a given permission.
     @return   Default title
     */
    public func defaultTitle() -> String {
        switch (self) {
        case SBAPermissionTypeIdentifier.healthKit:
            return Localization.localizedString("SBA_HEALTHKIT_PERMISSIONS_TITLE")
        case SBAPermissionTypeIdentifier.location:
            return Localization.localizedString("SBA_LOCATION_PERMISSIONS_TITLE")
        case SBAPermissionTypeIdentifier.coremotion:
            return Localization.localizedString("SBA_COREMOTION_PERMISSIONS_TITLE")
        case SBAPermissionTypeIdentifier.notifications:
            return Localization.localizedString("SBA_REMINDER_PERMISSIONS_TITLE")
        case SBAPermissionTypeIdentifier.microphone:
            return Localization.localizedString("SBA_MICROPHONE_PERMISSIONS_TITLE")
        case SBAPermissionTypeIdentifier.camera:
            return Localization.localizedString("SBA_CAMERA_PERMISSIONS_TITLE")
        case SBAPermissionTypeIdentifier.photoLibrary:
            return Localization.localizedString("SBA_PHOTOLIBRARY_PERMISSIONS_TITLE")
        default:
            return ""
        }
    }
    
    /**
     Returns the default description for the given permission
     @return   Default description
     */
    public func defaultDescription() -> String {
        switch (self) {
        case SBAPermissionTypeIdentifier.healthKit:
            return Localization.localizedString("SBA_HEALTHKIT_PERMISSIONS_DESCRIPTION")
            
        case SBAPermissionTypeIdentifier.location:
            return Localization.localizedBundleString("NSLocationWhenInUseUsageDescription",
                                                      localizedKey: "SBA_LOCATION_PERMISSIONS_DESCRIPTION")
        case SBAPermissionTypeIdentifier.coremotion:
            return Localization.localizedBundleString("NSMotionUsageDescription",
                                                      localizedKey: "SBA_COREMOTION_PERMISSIONS_DESCRIPTION")
        case SBAPermissionTypeIdentifier.notifications:
            return Localization.localizedString("SBA_NOTIFICATIONS_PERMISSIONS_DESCRIPTION")
        case SBAPermissionTypeIdentifier.microphone:
            return Localization.localizedBundleString("NSMicrophoneUsageDescription",
                                                      localizedKey: "SBA_MICROPHONE_PERMISSIONS_DESCRIPTION")
        case SBAPermissionTypeIdentifier.camera:
            return Localization.localizedBundleString("NSCameraUsageDescription",
                                                      localizedKey: "SBA_CAMERA_PERMISSIONS_TITLE")
        case SBAPermissionTypeIdentifier.photoLibrary:
            return Localization.localizedBundleString("NSPhotoLibraryUsageDescription",
                                                      localizedKey: "SBA_PHOTOLIBRARY_PERMISSIONS_TITLE")
        default:
            return ""
        }
    }
}
