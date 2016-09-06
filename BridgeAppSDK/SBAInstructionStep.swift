//
//  SBAInstructionStep.swift
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

public class SBAInstructionStep: ORKInstructionStep, SBADirectNavigationRule, SBACustomTypeStep {
    
    /**
    * For cases where this type of step is created as a placeholder for a custom step.
    */
    public var customTypeIdentifier: String?
    
    /**
     * Pointer to the next step to show after this one. If nil, then the next step
     * is determined by the navigation rules setup by SBANavigableOrderedTask.
     */
    public var nextStepIdentifier: String?
    
    /**
     * HTML Content for the "learn more" for this step
     */
    @available(*, deprecated, message="use learnMoreAction: instead")
    public var learnMoreHTMLContent: String? {
        guard let learnMore = self.learnMoreAction?.identifier else {
            return nil
        }
        return SBAResourceFinder.sharedResourceFinder.htmlNamed(learnMore)
    }
    
    /**
    * Indicates whether or not this step should use the completion step animation.
    */
    public var isCompletionStep: Bool = false
    
    /**
     * The learn more action for this step
     */
    public var learnMoreAction: SBALearnMoreAction?
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    public init(identifier: String, nextStepIdentifier: String?) {
        super.init(identifier: identifier)
        self.nextStepIdentifier = nextStepIdentifier
    }
    
    public init(identifier: String, customTypeIdentifier: String?) {
        super.init(identifier: identifier)
        self.customTypeIdentifier = customTypeIdentifier
    }
    
    public override func stepViewControllerClass() -> AnyClass {
        // If this is a completion step, then use ORKCompletionStepViewController 
        // unless this is class has an image, in which case ORKCompletionStepViewController
        // will not display that image so use the super class implementation.
        if self.isCompletionStep && self.image == nil {
            return ORKCompletionStepViewController.classForCoder()
        }
        else {
            return super.stepViewControllerClass()
        }
    }
    
    // MARK: NSCopy
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone)
        guard let step = copy as? SBAInstructionStep else { return copy }
        step.nextStepIdentifier = self.nextStepIdentifier
        step.learnMoreAction = self.learnMoreAction
        step.customTypeIdentifier = self.customTypeIdentifier
        step.isCompletionStep = self.isCompletionStep
        return step
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.nextStepIdentifier = aDecoder.decodeObjectForKey("nextStepIdentifier") as? String
        self.learnMoreAction = aDecoder.decodeObjectForKey("learnMoreAction") as? SBALearnMoreAction
        self.customTypeIdentifier = aDecoder.decodeObjectForKey("customTypeIdentifier") as? String
        self.isCompletionStep = aDecoder.decodeBoolForKey("isCompletionStep")
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.nextStepIdentifier, forKey: "nextStepIdentifier")
        aCoder.encodeObject(self.learnMoreAction, forKey: "learnMoreAction")
        aCoder.encodeObject(self.customTypeIdentifier, forKey: "customTypeIdentifier")
        aCoder.encodeBool(self.isCompletionStep, forKey: "isCompletionStep")
    }
    
    // MARK: Equality
    
    override public func isEqual(object: AnyObject?) -> Bool {
        guard let object = object as? SBAInstructionStep else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(self.nextStepIdentifier, object.nextStepIdentifier) &&
            SBAObjectEquality(self.learnMoreAction, object.learnMoreAction) &&
            SBAObjectEquality(self.customTypeIdentifier, object.customTypeIdentifier) &&
            (self.isCompletionStep == object.isCompletionStep)
    }
    
    override public var hash: Int {
        return super.hash ^
            SBAObjectHash(self.nextStepIdentifier) ^
            SBAObjectHash(learnMoreAction) ^
            SBAObjectHash(self.customTypeIdentifier) ^
            self.isCompletionStep.hashValue
    }
}