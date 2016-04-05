//
//  SBADataObjectTests.swift
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

import XCTest
import ResearchKit
import BridgeAppSDK

class SBADataObjectTests: ResourceTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testClassTypeMap_AutomaticallyMappedBridgeAppObject() {
        
        let result: AnyClass? = SBAClassTypeMap.sharedMap().classForClassType("SBAMedication")
        XCTAssertNotNil(result)
        guard let classType = result as? SBATrackedDataObject.Type else {
            XCTAssert(false, "\(result) not of expected class type")
            return
        }
        
        let obj = classType.init(identifier: "abc123")
        XCTAssertNotNil(obj)
        XCTAssertEqual(obj.identifier, "abc123")
        
        guard let _ = obj as? SBAMedication else {
            XCTAssert(false, "\(obj) not of expected class type")
            return
        }
    }
    
    func testClassTypeMap_AutomaticallyMappedBundleObject() {
        let result: AnyClass? = SBAClassTypeMap.sharedMap().classForClassType("MockORKTaskWithoutOptionals")
        XCTAssertNotNil(result)
    }
    
    func testClassTypeMap_PlistMappedBridgeAppObjects() {

        let result: AnyClass? = SBAClassTypeMap.sharedMap().classForClassType("Medication")
        XCTAssertNotNil(result)
        guard let _ = result as? SBAMedication.Type else {
            XCTAssert(false, "\(result) not of expected class type")
            return
        }
        
    }
    
    func testMedicationArchiveAndUnarchive() {
        
        // Create a medication
        let duopa = SBAMedication(dictionaryRepresentation: [
            "identifier"            : "Duopa",
            "name"                  : "Carbidopa/Levodopa",
            "detail"                : "Continuous Infusion",
            "brand"                 : "Duopa",
            "tracking"              : true,
            "injection"             : true,
            ])
        
        
        // Modify the frequency
        duopa.frequency = 4;
        
        // Archive
        let data = NSKeyedArchiver.archivedDataWithRootObject([duopa]);
        
        // Unarchive it and check the result
        guard let arr = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [SBAMedication],
            let med = arr.first else {
                XCTAssert(false, "Value did not unarchive as array")
                return
        }
        
        XCTAssertEqual(duopa.identifier, med.identifier)
        XCTAssertEqual(duopa.name, med.name)
        XCTAssertEqual(duopa.brand, med.brand)
        XCTAssertEqual(duopa.detail, med.detail)
        XCTAssertEqual(duopa.frequency, med.frequency)
        XCTAssertTrue(duopa.tracking)
        XCTAssertTrue(duopa.injection)
    }
    
    func testMedicationTrackerFromResourceFile() {
    
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        
        XCTAssertEqual(dataCollection.taskIdentifier, "1-APHMedicationTracker-20EF8ED2-E461-4C20-9024-F43FCAAAF4C3")
        XCTAssertEqual(dataCollection.schemaIdentifier, "Medication Tracker")
        XCTAssertEqual(dataCollection.schemaRevision, 8)
    }
    
    func testMedicationTrackerFromResourceFile_Items() {
    
        guard let dataCollection = self.dataCollectionForMedicationTracking() else { return }
        XCTAssertEqual(dataCollection.itemsClassType, "Medication")
        
        let expectedCount = 15
        XCTAssertEqual(dataCollection.trackedItems.count, expectedCount);
        if (dataCollection.trackedItems.count != expectedCount) {
            return
        }
        
        let meds = dataCollection.trackedItems;
        guard let levodopa = meds[0] as? SBAMedication,
            let carbidopa = meds[1] as? SBAMedication,
            let rytary = meds[2] as? SBAMedication,
            let duopa = meds.last as? SBAMedication
        else {
            XCTAssert(false, "trackedItems not of expected type \(meds)")
            return
        }
        
        XCTAssertEqual(levodopa.identifier, "Levodopa");
        XCTAssertEqual(levodopa.name, "Levodopa");
        XCTAssertEqual(levodopa.text, "Levodopa");
        XCTAssertEqual(levodopa.shortText, "Levodopa");
        XCTAssertTrue(levodopa.tracking);
        XCTAssertFalse(levodopa.injection);
        
        XCTAssertEqual(carbidopa.identifier, "Carbidopa");
        XCTAssertEqual(carbidopa.name, "Carbidopa");
        XCTAssertEqual(carbidopa.text, "Carbidopa");
        XCTAssertEqual(carbidopa.shortText, "Carbidopa");
        XCTAssertFalse(carbidopa.tracking);
        XCTAssertFalse(carbidopa.injection);
        
        XCTAssertEqual(rytary.identifier, "Rytary");
        XCTAssertEqual(rytary.name, "Carbidopa/Levodopa");
        XCTAssertEqual(rytary.brand, "Rytary");
        XCTAssertEqual(rytary.text, "Carbidopa/Levodopa (Rytary)");
        XCTAssertEqual(rytary.shortText, "Rytary");
        XCTAssertTrue(rytary.tracking);
        XCTAssertFalse(rytary.injection);
        
        XCTAssertEqual(duopa.identifier, "Duopa");
        XCTAssertEqual(duopa.name, "Carbidopa/Levodopa");
        XCTAssertEqual(duopa.brand, "Duopa");
        XCTAssertEqual(duopa.detail, "Continuous Infusion");
        XCTAssertEqual(duopa.text, "Carbidopa/Levodopa Continuous Infusion (Duopa)");
        XCTAssertEqual(duopa.shortText, "Duopa");
        XCTAssertFalse(duopa.tracking);
        XCTAssertTrue(duopa.injection);
    
    }
    
    // Mark: convenience methods
    
    func dataCollectionForMedicationTracking() -> SBATrackedDataObjectCollection? {
        guard let json = self.jsonForResource("MedicationTracking") as? [NSObject: AnyObject] else {
            return nil
        }
        return SBATrackedDataObjectCollection(dictionaryRepresentation: json)
    }
}
