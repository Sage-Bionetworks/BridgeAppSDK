//
//  SBAProfileManagerTests.swift
//  BridgeAppSDK
//
//  Created by Erin Mounts on 5/8/17.
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//

import XCTest
@testable import BridgeAppSDK

class SBAProfileManagerTests: ResourceTestCase {
    
    var ProfileManager: SBAProfileManagerProtocol?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        guard let input = jsonForResource("ProfileDescription") as? [String: Any] else { return }
        ProfileManager = SBAClassTypeMap.shared.object(with:input, classType:SBAProfileManagerClassType) as? SBAProfileManagerProtocol
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testProfileKeys() {
        guard let keys = ProfileManager?.profileKeys() else {
            XCTFail("No ProfileManager instance")
            return
        }
        XCTAssert(keys.count == 6, "expected 6 keys, got \(keys.count)")
    }
    
    func testProfileItems() {
        guard let items = ProfileManager?.profileItems() else {
            XCTFail("No ProfileManager instance")
            return
        }
        XCTAssert(items.count == 6, "expected 6 items, got \(items.count)")
        let fullNameItem = items["fullName"]
        let externalIdItem = items["externalId"]
        let genderItem = items["gender"]
        let birthDateItem = items["birthDate"]
        let favoriteColorItem = items["favoriteColor"]
        let numberOfSiblingsItem = items["numberOfSiblings"]
        XCTAssert(fullNameItem != nil, "no item for profileKey fullName")
        XCTAssert(externalIdItem != nil, "no item for profileKey externalId")
        XCTAssert(genderItem != nil, "no item for profileKey gender")
        XCTAssert(birthDateItem != nil, "no item for profileKey birthDate")
        XCTAssert(favoriteColorItem != nil, "no item for profileKey favoriteColor")
        XCTAssert(numberOfSiblingsItem != nil, "no item for profileKey numberOfSiblings")
        if fullNameItem != nil {
            XCTAssert(fullNameItem!.sourceKey == "fullName", "expected fullNameItem.sourceKey to be fullName, but it's \(fullNameItem!.sourceKey)")
            XCTAssert(fullNameItem!.demographicKey == fullNameItem!.profileKey, "expected fullNameItem.demographicKey to be \(fullNameItem!.profileKey), but it's \(fullNameItem!.demographicKey)")
            XCTAssert(fullNameItem!.itemType == .string, "expected fullNameItem.itemType to be String, but it's \(fullNameItem!.itemType.rawValue)")
            let typedItem = fullNameItem as? BridgeAppSDK.SBAUserProfileItem
            XCTAssertNotNil(typedItem, "fullNameItem is not an SBAUserProfileItem: \(String(describing: fullNameItem))")
        }
        if externalIdItem != nil {
            XCTAssert(externalIdItem!.sourceKey == "externalId", "expected externalIdItem.sourceKey to be externalId, but it's \(externalIdItem!.sourceKey)")
            XCTAssert(externalIdItem!.demographicKey == externalIdItem!.profileKey, "expected externalIdItem.demographicKey to be \(externalIdItem!.profileKey), but it's \(externalIdItem!.demographicKey)")
            XCTAssert(externalIdItem!.itemType == .string, "expected externalIdItem.itemType to be String, but it's \(externalIdItem!.itemType.rawValue)")
            let typedItem = externalIdItem as? BridgeAppSDK.SBAUserProfileItem
            XCTAssertNotNil(typedItem, "externalIdItem is not an SBAUserProfileItem: \(String(describing: externalIdItem))")
        }
        if genderItem != nil {
            XCTAssert(genderItem!.sourceKey == "gender", "expected genderItem.sourceKey to be gender, but it's \(genderItem!.sourceKey)")
            XCTAssert(genderItem!.demographicKey == genderItem!.profileKey, "expected genderItem.demographicKey to be \(genderItem!.profileKey), but it's \(genderItem!.demographicKey)")
            XCTAssert(genderItem!.itemType == .hkBiologicalSex, "expected genderItem.itemType to be HKBiologicalSex, but it's \(genderItem!.itemType.rawValue)")
            let typedItem = genderItem as? BridgeAppSDK.SBAKeychainProfileItem
            XCTAssertNotNil(typedItem, "genderItem is not an SBAKeychainProfileItem: \(String(describing: genderItem))")
        }
        if birthDateItem != nil {
            XCTAssert(birthDateItem!.sourceKey == "birthDate", "expected birthDateItem.sourceKey to be name, but it's \(birthDateItem!.sourceKey)")
            XCTAssert(birthDateItem!.demographicKey == birthDateItem!.profileKey, "expected birthDateItem.demographicKey to be \(birthDateItem!.profileKey), but it's \(birthDateItem!.demographicKey)")
            XCTAssert(birthDateItem!.itemType == .date, "expected birthDateItem.itemType to be Date, but it's \(birthDateItem!.itemType.rawValue)")
            let typedItem = birthDateItem as? BridgeAppSDK.SBAKeychainProfileItem
            XCTAssertNotNil(typedItem, "birthDateItem is not an SBAKeychainProfileItem: \(String(describing: birthDateItem))")
        }
        if favoriteColorItem != nil {
            XCTAssert(favoriteColorItem!.sourceKey == "favouriteColour", "expected favoriteColorItem.sourceKey to be favouriteColour, but it's \(favoriteColorItem!.sourceKey)")
            XCTAssert(favoriteColorItem!.demographicKey == favoriteColorItem!.profileKey, "expected favoriteColorItem.demographicKey to be \(favoriteColorItem!.profileKey), but it's \(favoriteColorItem!.demographicKey)")
            XCTAssert(favoriteColorItem!.itemType == .string, "expected favoriteColorItem.itemType to be String, but it's \(favoriteColorItem!.itemType.rawValue)")
            let typedItem = favoriteColorItem as? BridgeAppSDK.SBAUserDefaultsProfileItem
            XCTAssertNotNil(typedItem, "favoriteColorItem is not an SBAUserDefaultsProfileItem: \(String(describing: favoriteColorItem))")
        }
        if numberOfSiblingsItem != nil {
            XCTAssert(numberOfSiblingsItem!.sourceKey == "numberOfSiblings", "expected numberOfSiblingsItem.sourceKey to be numberOfSiblings, but it's \(numberOfSiblingsItem!.sourceKey)")
            XCTAssert(numberOfSiblingsItem!.demographicKey == "number_of_siblings", "expected favoriteColorItem.demographicKey to be number_of_siblings, but it's \(favoriteColorItem!.demographicKey)")
            XCTAssert(numberOfSiblingsItem!.itemType == .number, "expected numberOfSiblingsItem.itemType to be Number, but it's \(numberOfSiblingsItem!.itemType.rawValue)")
            let typedItem = numberOfSiblingsItem as? BridgeAppSDK.SBAUserDefaultsProfileItem
            XCTAssertNotNil(typedItem, "numberOfSiblingsItem is not an SBAUserDefaultsProfileItem: \(String(describing: numberOfSiblingsItem))")
        }
    }
    
    func testSetAndGetValueForProfileKey() {
        guard let items = ProfileManager?.profileItems() else {
            XCTFail("No ProfileManager instance")
            return
        }
        let fullNameItem = items["fullName"] as? BridgeAppSDK.SBAUserProfileItem
        let externalIdItem = items["externalId"] as? BridgeAppSDK.SBAUserProfileItem
        let genderItem = items["gender"] as? BridgeAppSDK.SBAKeychainProfileItem
        let birthDateItem = items["birthDate"] as? BridgeAppSDK.SBAKeychainProfileItem
        let favoriteColorItem = items["favoriteColor"] as? BridgeAppSDK.SBAUserDefaultsProfileItem
        let numberOfSiblingsItem = items["numberOfSiblings"] as? BridgeAppSDK.SBAUserDefaultsProfileItem
        XCTAssert(fullNameItem != nil, "no SBAUserProfileItem for profileKey fullName")
        XCTAssert(externalIdItem != nil, "no SBAUserProfileItem for profileKey externalId")
        XCTAssert(genderItem != nil, "no SBAKeychainProfileItem for profileKey gender")
        XCTAssert(birthDateItem != nil, "no SBAKeychainProfileItem for profileKey birthDate")
        XCTAssert(favoriteColorItem != nil, "no SBAUserDefaultsProfileItem for profileKey favoriteColor")
        XCTAssert(numberOfSiblingsItem != nil, "no SBAUserDefaultsProfileItem for profileKey numberOfSiblings")
        if fullNameItem != nil {
            let testName = "Full Name"
            
            // fullName is not a writeable property on SBAUser--it's a computed read-only property
            // defined in a protocol extension
            SBAUser.shared.name = "Full"
            SBAUser.shared.familyName = "Name"
            
            let value = ProfileManager!.value(forProfileKey: fullNameItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for fullNameItem")
            } else {
                XCTAssertEqual(testName, value!, "Expected value to be \(testName), but instead it's \(value!)")
            }
        }
        if externalIdItem != nil {
            let testId = "Test External ID"
            do {
                try ProfileManager!.setValue(testId, forProfileKey: externalIdItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for externalIdItem: unknown profile key \(externalIdItem!.profileKey)")
            }
            
            let value = ProfileManager!.value(forProfileKey: externalIdItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for externalIdItem")
            } else {
                XCTAssertEqual(testId, value!, "Expected value to be \(testId), but instead it's \(value!)")
            }
        }
        if genderItem != nil {
            let testGender = HKBiologicalSex.female
            do {
                try ProfileManager!.setValue(testGender, forProfileKey: genderItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for genderItem: unknown profile key \(genderItem!.profileKey)")
            }
            
            let value = ProfileManager!.value(forProfileKey: genderItem!.profileKey) as? HKBiologicalSex
            if value == nil {
                XCTFail("Failed retrieving HKBiologicalSex value for genderItem")
            } else {
                XCTAssertEqual(testGender, value!, "Expected value to be \(testGender), but instead it's \(value!)")
            }
        }
        if birthDateItem != nil {
            let testBirthDate = Date()
            do {
                try ProfileManager!.setValue(testBirthDate, forProfileKey: birthDateItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for birthDateItem: unknown profile key \(birthDateItem!.profileKey)")
            }
            
            let value = ProfileManager!.value(forProfileKey: birthDateItem!.profileKey) as? Date
            if value == nil {
                XCTFail("Failed retrieving Date value for birthDateItem")
            } else {
                XCTAssertEqual(testBirthDate, value!, "Expected value to be \(testBirthDate), but instead it's \(value!)")
            }
        }
        if favoriteColorItem != nil {
            let testColor = "Octarine"
            do {
                try ProfileManager!.setValue(testColor, forProfileKey: favoriteColorItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for favoriteColorItem: unknown profile key \(favoriteColorItem!.profileKey)")
            }
            
            let value = ProfileManager!.value(forProfileKey: favoriteColorItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for favoriteColorItem")
            } else {
                XCTAssertEqual(testColor, value!, "Expected value to be \(testColor), but instead it's \(value!)")
            }
        }
        if numberOfSiblingsItem != nil {
            let testNumber = 7
            do {
                try ProfileManager!.setValue(testNumber, forProfileKey: numberOfSiblingsItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for numberOfSiblingsItem: unknown profile key \(numberOfSiblingsItem!.profileKey)")
            }
            
            let value = ProfileManager!.value(forProfileKey: numberOfSiblingsItem!.profileKey) as? Int
            if value == nil {
                XCTFail("Failed retrieving Number value for numberOfSiblingsItem")
            } else {
                XCTAssertEqual(testNumber, value!, "Expected value to be \(testNumber), but instead it's \(value!)")
            }
        }
    }
    
}
