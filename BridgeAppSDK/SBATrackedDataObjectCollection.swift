//
//  SBADataObjectCollection.swift
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

public class SBATrackedDataObjectCollection: SBADataObject, SBABridgeTask, SBAStepTransformer {
    
    // MARK: SBAStepTransformer
    
    public func transformToStep(factory: SBASurveyFactory, isLastStep: Bool) -> ORKStep {
        // TODO: implement
        return ORKStep(identifier: self.identifier)
    }

    // MARK: SBABridgeTask
    
    let taskIdentifierKey = "taskIdentifier"
    public dynamic var taskIdentifier: String!
    
    let schemaIdentifierKey = "schemaIdentifier"
    public dynamic var schemaIdentifier: String!
    
    let schemaRevisionKey = "schemaRevision"
    public dynamic var schemaRevision: NSNumber!
    
    public var taskSteps: [SBAStepTransformer] {
        return [self]
    }
    
    public var insertSteps: [SBAStepTransformer]? {
        return nil
    }
    
    // MARK: SBADataObject overrides
    
    let trackedItemsKey = "items"
    public dynamic var trackedItems: [SBATrackedDataObject] = {
        return []   // init with empty if needed
    }()
    
    let itemsClassTypeKey = "itemsClassType"
    public dynamic var itemsClassType: String?
    
    let stepsKey = "steps"
    public dynamic var steps: [AnyObject] = {
        return []   // init with empty if needed
    }()
    
    let identifierKey = "identifier"
    override public func defaultIdentifierIfNil() -> String {
        return self.schemaIdentifier
    }
    
    override public func dictionaryRepresentationKeys() -> [String] {
        return [taskIdentifierKey, schemaIdentifierKey, schemaRevisionKey, itemsClassTypeKey, trackedItemsKey, stepsKey] +
            super.dictionaryRepresentationKeys().filter({ $0 != identifierKey })
    }
    
    public override func valueForKey(key: String) -> AnyObject? {
        switch key {
        case trackedItemsKey:
            return self.trackedItems
        default:
            return super.valueForKey(key)
        }
    }

    override public func setValue(value: AnyObject?, forKey key: String) {
        
        switch key {
            
        case trackedItemsKey:
            if let array = value as? [AnyObject] {
                self.trackedItems = array.map({ (obj) -> SBATrackedDataObject in
                    if let dataObject = obj as? SBATrackedDataObject {
                        return dataObject
                    }
                    else if let mappedObject = self.mapValue(obj, forKey: key, withClassType: self.itemsClassType) as? SBATrackedDataObject {
                        return mappedObject;
                    }
                    else {
                        return SBATrackedDataObject(identifier: NSUUID().UUIDString)
                    }
                })
            }
            else {
                self.trackedItems = []
            }
            
        default:
            super.setValue(value, forKey: key)
        }
    }
}
