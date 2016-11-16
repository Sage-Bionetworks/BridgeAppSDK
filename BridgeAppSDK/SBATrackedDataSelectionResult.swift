//
//  SBATrackedDataResult.swift
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

import UIKit

open class SBATrackedDataSelectionResult: ORKQuestionResult {
    
    open var selectedItems: [SBATrackedDataObject]?
    
    override init() {
        super.init()
    }
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        self.questionType = .multipleChoice
    }
    
    open override var answer: Any? {
        get { return selectedItems }
        set {
            guard let items = newValue as? [SBATrackedDataObject] else {
                selectedItems = nil
                return
            }
            selectedItems = items
        }
    }
    
    // MARK: NSCoding
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.selectedItems = aDecoder.decodeObject(forKey: #keyPath(selectedItems)) as? [SBATrackedDataObject]
    }
    
    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.selectedItems, forKey: #keyPath(selectedItems))
    }
    
    // MARK: NSCopying
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let result = copy as? SBATrackedDataSelectionResult else { return copy }
        result.selectedItems = self.selectedItems
        return result
    }
    
    // MARK: Equality
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard super.isEqual(object), let obj = object as? SBATrackedDataSelectionResult else { return false }
        return SBAObjectEquality(self.selectedItems, obj.selectedItems)
    }
    
    override open var hash: Int {
        return super.hash ^ SBAObjectHash(self.selectedItems)
    }

}

extension SBATrackedDataSelectionResult {
    
    public override func jsonSerializedAnswer() -> SBAAnswerKeyAndValue? {
        // Always return a non-nil result for items
        let selectedItems: NSArray? = self.selectedItems as NSArray?
        let value = selectedItems?.jsonObject() ?? NSArray()
        return SBAAnswerKeyAndValue(key: "items", value: value, questionType: .multipleChoice)
    }
    
}
