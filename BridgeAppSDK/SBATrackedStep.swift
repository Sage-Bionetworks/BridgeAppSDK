//
//  SBATrackedStep.swift
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

@objc
public protocol SBATrackedDataSelectedItemsProtocol {
    
    @objc(stepResultWithSelectedItems:)
    func stepResult(selectedItems:[SBATrackedDataObject]?) -> ORKStepResult?
}

public protocol SBATrackedStep {
    var trackingType: SBATrackingStepType? { get }
}

public protocol SBATrackedStepSurveyItem: SBASurveyItem, SBATrackedStep {
}

public protocol SBATrackedNavigationStep: SBATrackedStep {
    var shouldSkipStep: Bool { get }
    func update(selectedItems:[SBATrackedDataObject])
}

public protocol SBATrackedSelectionFilter: SBATrackedStep {
    func filter(selectedItems items: [SBATrackedDataObject], stepResult: ORKStepResult) -> [SBATrackedDataObject]?
}

public enum SBATrackingStepType: String {
    case introduction   = "introduction"
    case changed        = "changed"
    case completion     = "completion"
    case activity       = "activity"
    case selection      = "selection"
    case frequency      = "frequency"
}

public struct SBATrackingStepIncludes {
    
    let nextStepIfNoChange: SBATrackingStepType
    let includes:[SBATrackingStepType]
    
    fileprivate init(includes:[SBATrackingStepType]) {
        if (includes.contains(.changed) && !includes.contains(.activity)) {
            self.includes = [.changed, .selection, .frequency, .activity]
            self.nextStepIfNoChange = .completion
        }
        else {
            self.includes = includes
            self.nextStepIfNoChange = .activity
        }
    }
    
    public static let StandAloneSurvey = SBATrackingStepIncludes(includes: [.introduction, .selection, .frequency, .completion])
    public static let ActivityOnly = SBATrackingStepIncludes(includes: [.activity])
    public static let SurveyAndActivity = SBATrackingStepIncludes(includes: [.introduction, .selection, .frequency, .activity])
    public static let ChangedAndActivity = SBATrackingStepIncludes(includes: [.changed, .selection, .frequency, .activity])
    public static let ChangedOnly = SBATrackingStepIncludes(includes: [.changed])
    public static let None = SBATrackingStepIncludes(includes: [])
    
    func includeSurvey() -> Bool {
        return includes.contains(.introduction) || includes.contains(.changed)
    }
    
    func shouldInclude(_ trackingType: SBATrackingStepType) -> Bool {
        return includes.contains(trackingType)
    }
}




