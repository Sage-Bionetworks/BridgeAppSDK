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
        XCTAssert(keys.count == 5, "expected 5 keys, got \(keys.count)")
    }
    
    func testProfileItems() {
        guard let items = ProfileManager?.profileItems() else {
            XCTFail("No ProfileManager instance")
            return
        }
        XCTAssert(items.count == 5, "expected 5 items, got \(items.count)")
        let fullNameItem = items["fullName"]
        let genderItem = items["gender"]
        let birthDateItem = items["birthDate"]
        let favoriteColorItem = items["favoriteColor"]
        let numberOfSiblingsItem = items["numberOfSiblings"]
        XCTAssert(fullNameItem != nil, "no item for key fullName")
        XCTAssert(genderItem != nil, "no item for key gender")
        XCTAssert(birthDateItem != nil, "no item for key birthDate")
        XCTAssert(favoriteColorItem != nil, "no item for key favoriteColor")
        XCTAssert(numberOfSiblingsItem != nil, "no item for key numberOfSiblings")
        if fullNameItem != nil {
            XCTAssert(fullNameItem!.sourceKey == "name", "expected fullNameItem.sourceKey to be name, but it's \(fullNameItem!.sourceKey)")
            XCTAssert(fullNameItem!.demographicKey == fullNameItem!.key, "expected fullNameItem.demographicKey to be \(fullNameItem!.key), but it's \(fullNameItem!.demographicKey)")
            XCTAssert(fullNameItem!.itemType == "String", "expected fullNameItem.itemType to be String, but it's \(fullNameItem!.itemType)")
            let typedItem = fullNameItem as? BridgeAppSDK.SBAKeychainProfileItem
            XCTAssertNotNil(typedItem, "fullNameItem is not an SBAKeychainProfileItem: \(String(describing: fullNameItem))")
        }
        if genderItem != nil {
            XCTAssert(genderItem!.sourceKey == "gender", "expected genderItem.sourceKey to be gender, but it's \(genderItem!.sourceKey)")
            XCTAssert(genderItem!.demographicKey == genderItem!.key, "expected genderItem.demographicKey to be \(genderItem!.key), but it's \(genderItem!.demographicKey)")
            XCTAssert(genderItem!.itemType == "HKBiologicalSex", "expected genderItem.itemType to be HKBiologicalSex, but it's \(genderItem!.itemType)")
            let typedItem = genderItem as? BridgeAppSDK.SBAKeychainProfileItem
            XCTAssertNotNil(typedItem, "genderItem is not an SBAKeychainProfileItem: \(String(describing: genderItem))")
        }
        if birthDateItem != nil {
            XCTAssert(birthDateItem!.sourceKey == "birthDate", "expected birthDateItem.sourceKey to be name, but it's \(birthDateItem!.sourceKey)")
            XCTAssert(birthDateItem!.demographicKey == birthDateItem!.key, "expected birthDateItem.demographicKey to be \(birthDateItem!.key), but it's \(birthDateItem!.demographicKey)")
            XCTAssert(birthDateItem!.itemType == "Date", "expected birthDateItem.itemType to be Date, but it's \(birthDateItem!.itemType)")
            let typedItem = birthDateItem as? BridgeAppSDK.SBAKeychainProfileItem
            XCTAssertNotNil(typedItem, "birthDateItem is not an SBAKeychainProfileItem: \(String(describing: birthDateItem))")
        }
        if favoriteColorItem != nil {
            XCTAssert(favoriteColorItem!.sourceKey == "favoriteColor", "expected favoriteColorItem.sourceKey to be favoriteColor, but it's \(favoriteColorItem!.sourceKey)")
            XCTAssert(favoriteColorItem!.demographicKey == favoriteColorItem!.key, "expected favoriteColorItem.demographicKey to be \(favoriteColorItem!.key), but it's \(favoriteColorItem!.demographicKey)")
            XCTAssert(favoriteColorItem!.itemType == "String", "expected favoriteColorItem.itemType to be String, but it's \(favoriteColorItem!.itemType)")
            let typedItem = favoriteColorItem as? BridgeAppSDK.SBAUserDefaultsProfileItem
            XCTAssertNotNil(typedItem, "favoriteColorItem is not an SBAUserDefaultsProfileItem: \(String(describing: favoriteColorItem))")
        }
        if numberOfSiblingsItem != nil {
            XCTAssert(numberOfSiblingsItem!.sourceKey == "numberOfSiblings", "expected numberOfSiblingsItem.sourceKey to be numberOfSiblings, but it's \(numberOfSiblingsItem!.sourceKey)")
            XCTAssert(numberOfSiblingsItem!.demographicKey == "number_of_siblings", "expected favoriteColorItem.demographicKey to be number_of_siblings, but it's \(favoriteColorItem!.demographicKey)")
            XCTAssert(numberOfSiblingsItem!.itemType == "Number", "expected numberOfSiblingsItem.itemType to be Number, but it's \(numberOfSiblingsItem!.itemType)")
            let typedItem = numberOfSiblingsItem as? BridgeAppSDK.SBAUserDefaultsProfileItem
            XCTAssertNotNil(typedItem, "numberOfSiblingsItem is not an SBAUserDefaultsProfileItem: \(String(describing: numberOfSiblingsItem))")
        }
    }
    
    func testSetAndGetValueForProfileKey() {
        guard let items = ProfileManager?.profileItems() else {
            XCTFail("No ProfileManager instance")
            return
        }
        let fullNameItem = items["fullName"] as? BridgeAppSDK.SBAKeychainProfileItem
        let genderItem = items["gender"] as? BridgeAppSDK.SBAKeychainProfileItem
        let birthDateItem = items["birthDate"] as? BridgeAppSDK.SBAKeychainProfileItem
        let favoriteColorItem = items["favoriteColor"] as? BridgeAppSDK.SBAUserDefaultsProfileItem
        let numberOfSiblingsItem = items["numberOfSiblings"] as? BridgeAppSDK.SBAUserDefaultsProfileItem
        XCTAssert(fullNameItem != nil, "no SBAKeychainProfileItem for key fullName")
        XCTAssert(genderItem != nil, "no SBAKeychainProfileItem for key gender")
        XCTAssert(birthDateItem != nil, "no SBAKeychainProfileItem for key birthDate")
        XCTAssert(favoriteColorItem != nil, "no SBAUserDefaultsProfileItem for key favoriteColor")
        XCTAssert(numberOfSiblingsItem != nil, "no SBAUserDefaultsProfileItem for key numberOfSiblings")
        if fullNameItem != nil {
            let testName = "Full Name"
            do {
                try ProfileManager!.setValue(testName, forProfileKey: fullNameItem!.key);
            }
            catch {
                XCTFail("Failed setting value for fullNameItem: unknown profile key \(fullNameItem!.key)")
            }
            
            let value = ProfileManager!.value(forProfileKey: fullNameItem!.key) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for fullNameItem")
            } else {
                XCTAssertEqual(testName, value!, "Expected value to be \(testName), but instead it's \(value!)")
            }
        }
        if genderItem != nil {
            let testGender = HKBiologicalSex.female
            do {
                try ProfileManager!.setValue(testGender, forProfileKey: genderItem!.key);
            }
            catch {
                XCTFail("Failed setting value for genderItem: unknown profile key \(genderItem!.key)")
            }
            
            let value = ProfileManager!.value(forProfileKey: genderItem!.key) as? HKBiologicalSex
            if value == nil {
                XCTFail("Failed retrieving HKBiologicalSex value for genderItem")
            } else {
                XCTAssertEqual(testGender, value!, "Expected value to be \(testGender), but instead it's \(value!)")
            }
        }
        if birthDateItem != nil {
            let testBirthDate = Date()
            do {
                try ProfileManager!.setValue(testBirthDate, forProfileKey: birthDateItem!.key);
            }
            catch {
                XCTFail("Failed setting value for birthDateItem: unknown profile key \(birthDateItem!.key)")
            }
            
            let value = ProfileManager!.value(forProfileKey: birthDateItem!.key) as? Date
            if value == nil {
                XCTFail("Failed retrieving Date value for birthDateItem")
            } else {
                XCTAssertEqual(testBirthDate, value!, "Expected value to be \(testBirthDate), but instead it's \(value!)")
            }
        }
        if favoriteColorItem != nil {
            let testColor = "Octarine"
            do {
                try ProfileManager!.setValue(testColor, forProfileKey: favoriteColorItem!.key);
            }
            catch {
                XCTFail("Failed setting value for favoriteColorItem: unknown profile key \(favoriteColorItem!.key)")
            }
            
            let value = ProfileManager!.value(forProfileKey: favoriteColorItem!.key) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for favoriteColorItem")
            } else {
                XCTAssertEqual(testColor, value!, "Expected value to be \(testColor), but instead it's \(value!)")
            }
        }
        if numberOfSiblingsItem != nil {
            let testNumber = 7
            do {
                try ProfileManager!.setValue(testNumber, forProfileKey: numberOfSiblingsItem!.key);
            }
            catch {
                XCTFail("Failed setting value for numberOfSiblingsItem: unknown profile key \(numberOfSiblingsItem!.key)")
            }
            
            let value = ProfileManager!.value(forProfileKey: numberOfSiblingsItem!.key) as? Int
            if value == nil {
                XCTFail("Failed retrieving Number value for numberOfSiblingsItem")
            } else {
                XCTAssertEqual(testNumber, value!, "Expected value to be \(testNumber), but instead it's \(value!)")
            }
        }
    }
    
}
