//
//  SBAProfileManagerTests.swift
//  BridgeAppSDK
//
//  Created by Erin Mounts on 5/8/17.
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//

import XCTest
@testable import BridgeAppSDK
@testable import BridgeAppSDKSample

class SBAProfileManagerTests: ResourceTestCase {
    
    var profileManager: SBAProfileManagerProtocol!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        guard let input = jsonForResource("ProfileDescription") as? [String: Any] else {
            XCTFail("Cannot open ProfileManager file")
            return
        }
        profileManager = SBAClassTypeMap.shared.object(with:input, classType:SBAProfileManagerClassType) as? SBAProfileManagerProtocol
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testProfileKeys() {
        guard let keys = profileManager?.profileKeys() else {
            XCTFail("No ProfileManager instance")
            return
        }
        XCTAssertEqual(keys.count, 9)
    }
    
    func testProfileItems() {
        guard let items = profileManager?.profileItems() else {
            XCTFail("No ProfileManager instance")
            return
        }
        XCTAssertEqual(items.count, 9)
        
        let fullNameItem = items["fullName"]
        let externalIdItem = items["externalId"]
        let genderItem = items["gender"]
        let birthDateItem = items["birthDate"]
        let favoriteColorItem = items["favoriteColor"]
        let numberOfSiblingsItem = items["numberOfSiblings"]
        
        XCTAssertNotNil(fullNameItem, "no item for profileKey fullName")
        XCTAssertNotNil(externalIdItem, "no item for profileKey externalId")
        XCTAssertNotNil(genderItem, "no item for profileKey gender")
        XCTAssertNotNil(birthDateItem, "no item for profileKey birthDate")
        XCTAssertNotNil(favoriteColorItem, "no item for profileKey favoriteColor")
        XCTAssertNotNil(numberOfSiblingsItem, "no item for profileKey numberOfSiblings")
        if fullNameItem != nil {
            XCTAssert(fullNameItem!.sourceKey == "fullName", "expected fullNameItem.sourceKey to be fullName, but it's \(fullNameItem!.sourceKey)")
            XCTAssert(fullNameItem!.demographicKey == fullNameItem!.profileKey, "expected fullNameItem.demographicKey to be \(fullNameItem!.profileKey), but it's \(fullNameItem!.demographicKey)")
            XCTAssert(fullNameItem!.itemType == .string, "expected fullNameItem.itemType to be String, but it's \(fullNameItem!.itemType.rawValue)")
            let typedItem = fullNameItem as? BridgeAppSDK.SBAFullNameProfileItem
            XCTAssertNotNil(typedItem, "fullNameItem is not an SBAFullNameProfileItem: \(String(describing: fullNameItem))")
        }
        if externalIdItem != nil {
            XCTAssert(externalIdItem!.sourceKey == "externalId", "expected externalIdItem.sourceKey to be externalId, but it's \(externalIdItem!.sourceKey)")
            XCTAssert(externalIdItem!.demographicKey == externalIdItem!.profileKey, "expected externalIdItem.demographicKey to be \(externalIdItem!.profileKey), but it's \(externalIdItem!.demographicKey)")
            XCTAssert(externalIdItem!.itemType == .string, "expected externalIdItem.itemType to be String, but it's \(externalIdItem!.itemType.rawValue)")
            let typedItem = externalIdItem as? BridgeAppSDK.SBAKeychainProfileItem
            XCTAssertNotNil(typedItem, "externalIdItem is not an SBAKeychainProfileItem: \(String(describing: externalIdItem))")
        }
        if genderItem != nil {
            XCTAssert(genderItem!.sourceKey == "gender", "expected genderItem.sourceKey to be gender, but it's \(genderItem!.sourceKey)")
            XCTAssert(genderItem!.demographicKey == genderItem!.profileKey, "expected genderItem.demographicKey to be \(genderItem!.profileKey), but it's \(genderItem!.demographicKey)")
            XCTAssert(genderItem!.itemType == .hkBiologicalSex, "expected genderItem.itemType to be HKBiologicalSex, but it's \(genderItem!.itemType.rawValue)")
            let typedItem = genderItem as? BridgeAppSDK.SBAClientDataProfileItem
            XCTAssertNotNil(typedItem, "genderItem is not an SBAClientDataProfileItem: \(String(describing: genderItem))")
        }
        if birthDateItem != nil {
            XCTAssert(birthDateItem!.sourceKey == "birthDate", "expected birthDateItem.sourceKey to be name, but it's \(birthDateItem!.sourceKey)")
            XCTAssert(birthDateItem!.demographicKey == birthDateItem!.profileKey, "expected birthDateItem.demographicKey to be \(birthDateItem!.profileKey), but it's \(birthDateItem!.demographicKey)")
            XCTAssert(birthDateItem!.itemType == .date, "expected birthDateItem.itemType to be Date, but it's \(birthDateItem!.itemType.rawValue)")
            let typedItem = birthDateItem as? BridgeAppSDK.SBABirthDateProfileItem
            XCTAssertNotNil(typedItem, "birthDateItem is not an SBABirthDateProfileItem: \(String(describing: birthDateItem))")
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
            let typedItem = numberOfSiblingsItem as? BridgeAppSDK.SBAClientDataProfileItem
            XCTAssertNotNil(typedItem, "numberOfSiblingsItem is not an SBAClientDataProfileItem: \(String(describing: numberOfSiblingsItem))")
        }
    }
    
    // MARK: build schedules
    
    static let demographicIdentifier: String = "Demographic Survey"
    static let someOtherIdentifier: String = "Something Else"
    let activityIdentifiers: [String] = [demographicIdentifier, someOtherIdentifier]
    
    func buildSchedule(startTime: Date, endTime: Date) -> [SBBScheduledActivity] {
        
        var schedules:[SBBScheduledActivity] = []
        
        var scheduledOn = startTime.startOfDay()
        while scheduledOn < endTime {
            for identifier in activityIdentifiers {
                let schedule = createSchedule(identifier: identifier, scheduledOn: scheduledOn)
                schedules.append(schedule)
            }
            scheduledOn = scheduledOn.addingNumberOfDays(1)
        }
        
        return schedules
    }
    
    func createSchedule(identifier: String, scheduledOn: Date) -> SBBScheduledActivity {
        
        let activity = SBBActivity()
        let taskRef = SBBTaskReference()
        taskRef.identifier = identifier
        activity.task = taskRef

        let schedule = SBBScheduledActivity()
        schedule.activity = activity
        schedule.guid = UUID().uuidString
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = scheduledOn.addingNumberOfDays(1)
        
        return schedule
    }
    
    func testSetAndGetValueForProfileKey() {
        guard let items = profileManager?.profileItems() else {
            XCTFail("No ProfileManager instance")
            return
        }
        let fullNameItem = items["fullName"] as? BridgeAppSDK.SBAFullNameProfileItem
        let givenNameItem = items["given"] as? BridgeAppSDK.SBAStudyParticipantProfileItem
        let familyNameItem = items["family"] as? BridgeAppSDK.SBAStudyParticipantProfileItem
        let preferredNameItem = items["preferredName"] as? BridgeAppSDK.SBAStudyParticipantCustomAttributesProfileItem
        let externalIdItem = items["externalId"] as? BridgeAppSDK.SBAKeychainProfileItem
        let genderItem = items["gender"] as? BridgeAppSDK.SBAClientDataProfileItem
        let birthDateItem = items["birthDate"] as? BridgeAppSDK.SBABirthDateProfileItem
        let favoriteColorItem = items["favoriteColor"] as? BridgeAppSDK.SBAUserDefaultsProfileItem
        let numberOfSiblingsItem = items["numberOfSiblings"] as? BridgeAppSDK.SBAClientDataProfileItem
        XCTAssert(fullNameItem != nil, "no SBAUserProfileItem for profileKey fullName")
        XCTAssert(externalIdItem != nil, "no SBAUserProfileItem for profileKey externalId")
        XCTAssert(genderItem != nil, "no SBAClientDataProfileItem for profileKey gender")
        XCTAssert(birthDateItem != nil, "no SBAKeychainProfileItem for profileKey birthDate")
        XCTAssert(favoriteColorItem != nil, "no SBAUserDefaultsProfileItem for profileKey favoriteColor")
        XCTAssert(numberOfSiblingsItem != nil, "no SBAClientDataProfileItem for profileKey numberOfSiblings")
        
        // Use a mock for the keychain
        let mockKeychain = MockKeychainWrapper()
        externalIdItem?.keychain = mockKeychain
        
        // Use the same mock keychain for the client item cache
        SBAClientDataProfileItem.keychain = mockKeychain
        try? mockKeychain.setObject([String: [String: SBBJSONValue]]() as NSSecureCoding, forKey: SBAClientDataProfileItem.cachedItemsKey)
        
        // Use a mock activity manager
        let activityManager = MockActivityManager()
        let historyDays = 10
        let futureDays = 10
        let startTime = Date().addingNumberOfDays(-historyDays)
        let endTime = startTime.addingNumberOfDays(futureDays)
        let schedules = buildSchedule(startTime: startTime, endTime: endTime)
        activityManager.getScheduledActivitiesForRange_Result = schedules
        SBBComponentManager.registerComponent(activityManager, for: SBBActivityManager.classForCoder())
        
        // Use a mock user as the app delegate's currentUser
        let mockUser = MockUser()
        mockUser.createdOn = Date().addingNumberOfDays(-historyDays)
        (SBAAppDelegate.shared as? AppDelegate)?.mockUser = mockUser
        
        // Use a uuid instance for the user defaults
        let mockUserDefaults = UserDefaults(suiteName: UUID().uuidString)!
        favoriteColorItem?.defaults = mockUserDefaults
        
        // set up a dummy instance for the study participant
        SBAStudyParticipantProfileItem.studyParticipant = DummyStudyParticipant()
        
        if givenNameItem != nil {
            let testGiven = "Full"
            do {
                try profileManager!.setValue(testGiven, forProfileKey: givenNameItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for givenNameItem: unknown profile key \(givenNameItem!.profileKey)")
            }
            
            let value = profileManager!.value(forProfileKey: givenNameItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for givenNameItem")
            } else {
                XCTAssertEqual(testGiven, value!, "Expected value to be \(testGiven), but instead it's \(value!)")
            }
        }
        
        if familyNameItem != nil {
            let testFamily = "Name"
            do {
                try profileManager!.setValue(testFamily, forProfileKey: familyNameItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for familyNameItem: unknown profile key \(familyNameItem!.profileKey)")
            }
            
            let value = profileManager!.value(forProfileKey: familyNameItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for familyNameItem")
            } else {
                XCTAssertEqual(testFamily, value!, "Expected value to be \(testFamily), but instead it's \(value!)")
            }
        }
        
        if preferredNameItem != nil {
            let testName = "Full"
            
            let value = profileManager!.value(forProfileKey: preferredNameItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for preferredNameItem")
            } else {
                XCTAssertEqual(testName, value!, "Expected value to be \(testName), but instead it's \(value!)")
            }
        }
        
        if fullNameItem != nil {
            let testName = "Full Name"
            
            let value = profileManager!.value(forProfileKey: fullNameItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for fullNameItem")
            } else {
                XCTAssertEqual(testName, value!, "Expected value to be \(testName), but instead it's \(value!)")
            }
        }
        
        if externalIdItem != nil {
            let testId = "Test External ID"
            do {
                try profileManager!.setValue(testId, forProfileKey: externalIdItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for externalIdItem: unknown profile key \(externalIdItem!.profileKey)")
            }
            
            let value = profileManager!.value(forProfileKey: externalIdItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for externalIdItem")
            } else {
                XCTAssertEqual(testId, value!, "Expected value to be \(testId), but instead it's \(value!)")
            }
        }
        
        let testGender = HKBiologicalSex.female
        if genderItem != nil {
            do {
                try profileManager!.setValue(testGender, forProfileKey: genderItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for genderItem: unknown profile key \(genderItem!.profileKey)")
            }
            
            let value = profileManager!.value(forProfileKey: genderItem!.profileKey) as? HKBiologicalSex
            if value == nil {
                XCTFail("Failed retrieving HKBiologicalSex value for genderItem")
            } else {
                XCTAssertEqual(testGender, value!, "Expected value to be \(testGender), but instead it's \(value!)")
            }
        }
        
        if birthDateItem != nil {
            let testBirthDate = Date()
            do {
                try profileManager!.setValue(testBirthDate, forProfileKey: birthDateItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for birthDateItem: unknown profile key \(birthDateItem!.profileKey)")
            }
            
            let value = profileManager!.value(forProfileKey: birthDateItem!.profileKey) as? Date
            if value == nil {
                XCTFail("Failed retrieving Date value for birthDateItem")
            } else {
                XCTAssertEqualWithAccuracy(testBirthDate.timeIntervalSince1970, value!.timeIntervalSince1970, accuracy: 0.00099999, "Expected value to be \(testBirthDate), but instead it's \(value!)")
            }
        }
        
        if favoriteColorItem != nil {
            let testColor = "Octarine"
            do {
                try profileManager!.setValue(testColor, forProfileKey: favoriteColorItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for favoriteColorItem: unknown profile key \(favoriteColorItem!.profileKey)")
            }
            
            let value = profileManager!.value(forProfileKey: favoriteColorItem!.profileKey) as? String
            if value == nil {
                XCTFail("Failed retrieving String value for favoriteColorItem")
            } else {
                XCTAssertEqual(testColor, value!, "Expected value to be \(testColor), but instead it's \(value!)")
            }
        }
        
        let testNumberSibs = 7
        if numberOfSiblingsItem != nil {
            do {
                try profileManager!.setValue(testNumberSibs, forProfileKey: numberOfSiblingsItem!.profileKey);
            }
            catch {
                XCTFail("Failed setting value for numberOfSiblingsItem: unknown profile key \(numberOfSiblingsItem!.profileKey)")
            }
            
            let value = profileManager!.value(forProfileKey: numberOfSiblingsItem!.profileKey) as? Int
            if value == nil {
                XCTFail("Failed retrieving Number value for numberOfSiblingsItem")
            } else {
                XCTAssertEqual(testNumberSibs, value!, "Expected value to be \(testNumberSibs), but instead it's \(value!)")
            }
        }
        
        // now update the changes to Bridge, and check that they made it there
        SBAClientDataProfileItem.scheduledActivities = schedules
        
        let sibsBridgeValues = numberOfSiblingsItem?.jsonWhatsAndWhensFromBridge().map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) })
        XCTAssert(sibsBridgeValues?.count == 1, "Expected to find 1 value for numberOfSiblings in Bridge history, but instead there are \(String(describing: sibsBridgeValues?.count))")
        XCTAssertEqual(testNumberSibs, sibsBridgeValues?[0].value as? Int, "Expected numberOfSiblings to be \(testNumberSibs) but got \(String(describing: sibsBridgeValues?[0].value)) instead")
        
        let genderBridgeValues = genderItem?.jsonWhatsAndWhensFromBridge().map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) })
        XCTAssert(genderBridgeValues?.count == 1, "Expected to find 1 value for gender in Bridge history, but instead there are \(String(describing: genderBridgeValues?.count))")
        XCTAssertEqual(testGender.rawValue, genderBridgeValues?[0].value as? Int, "Expected value to be \(testGender), but instead it's \(String(describing: genderBridgeValues?[0].value))")
        
        // now explicitly update numberOfSiblings twice more, once 10 seconds in the future and once 1 day in the past
        let testNumberSibs2 = 3
        numberOfSiblingsItem?.setStoredValue(testNumberSibs2, asOf: Date().addingTimeInterval(10.0))
        let testNumberSibs3 = 99
        numberOfSiblingsItem?.setStoredValue(testNumberSibs3, asOf: Date().addingNumberOfDays(-11))
        
        // now update the changes to Bridge, and check that they made it there
        SBAClientDataProfileItem.scheduledActivities = schedules
        
        let sibsBridgeValues2 = numberOfSiblingsItem?.jsonWhatsAndWhensFromBridge().map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) })
        XCTAssert(sibsBridgeValues2?.count == 3, "Expected to find 3 values for numberOfSiblings in Bridge history, but instead there are \(String(describing: sibsBridgeValues2?.count))")
        XCTAssertEqual(testNumberSibs3, sibsBridgeValues2?[0].value as? Int, "Expected first numberOfSiblings to be \(testNumberSibs3) but got \(String(describing: sibsBridgeValues2?[0].value)) instead")
        XCTAssertEqual(testNumberSibs, sibsBridgeValues2?[1].value as? Int, "Expected second numberOfSiblings to be \(testNumberSibs) but got \(String(describing: sibsBridgeValues2?[1].value)) instead")
        XCTAssertEqual(testNumberSibs2, sibsBridgeValues2?[2].value as? Int, "Expected second numberOfSiblings to be \(testNumberSibs2) but got \(String(describing: sibsBridgeValues2?[2].value)) instead")
    }
    
}

class DummyCustomAttributes: SBBStudyParticipantCustomAttributes {
    dynamic var birthDate: NSString?
    dynamic var preferredName: NSString?
}

class DummyStudyParticipant: SBBStudyParticipant {
    override init() {
        super.init()
        self.attributes = DummyCustomAttributes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
