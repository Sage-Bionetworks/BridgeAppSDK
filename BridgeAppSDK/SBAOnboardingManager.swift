//
//  SBAOnboardingManager.swift
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
import ResearchKit

public class SBAOnboardingManager: NSObject, SBASharedInfoController {
    
    public var sections: [SBAOnboardingSection]?
    
    public var sharedAppDelegate: SBASharedAppDelegate {
        return UIApplication.sharedApplication().delegate as! SBASharedAppDelegate
    }
    
    public override init() {
        super.init()
    }
    
    public convenience init?(jsonNamed: String) {
        guard let json = SBAResourceFinder().jsonNamed(jsonNamed) else { return nil }
        self.init(dictionary: json)
    }
    
    public convenience init(dictionary: NSDictionary) {
        self.init()
        self.sections = (dictionary["sections"] as? [AnyObject])?.map({ (obj) -> SBAOnboardingSection in
            return obj as! SBAOnboardingSection
        })
    }
    
    public func sectionForOnboardingSectionType(sectionType: SBAOnboardingSectionType) -> SBAOnboardingSection? {
        return self.sections?.findObject({ $0.onboardingSectionType == sectionType })
    }
    
    public func factoryForSection(section: SBAOnboardingSection) -> SBASurveyFactory {
        return section.defaultOnboardingSurveyFactory()
    }

}
