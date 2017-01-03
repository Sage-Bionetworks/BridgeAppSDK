//
//  SBAConsentSection.swift
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

/**
 Mapping used to define each section in the consent document. This is used for both 
 visual consent and consent review.
 */
public protocol SBAConsentSection: class {
    var consentSectionType: SBAConsentSectionType { get }
    var sectionTitle: String? { get }
    var sectionFormalTitle: String? { get }
    var sectionSummary: String? { get }
    var sectionContent: String? { get }
    var sectionHtmlContent: String? { get }
    var sectionLearnMoreButtonTitle: String? { get }
    var sectionCustomImage: UIImage? { get }
    var sectionCustomAnimationURLString: String? { get }
}

public enum SBAConsentSectionType: String {

    // Maps to ORKConsentSectionType
    // These cases use images and animations baked into ResearchKit
    case overview
    case privacy
    case dataGathering
    case dataUse
    case timeCommitment
    case studySurvey
    case studyTasks
    case onlyInDocument
    
    // Maps to BridgeAppSDK resources
    // These cases use images and animations baked into BridgeAppSDK
    case understanding
    case activities
    case sensorData
    case medicalCare
    case followUp
    case potentialRisks
    case exitArrow
    case thinkItOver
    case futureResearch
    case dataSharing
    case qualifiedResearchers
    
    // The section defines its own image and animation
    case custom
    
    /**
     Some sections of the consent flow map to sections where the image and animation
     are defined in ResearchKit. For these cases, use the ResearchKit section types.
     */
    var orkSectionType: ORKConsentSectionType {
        switch(self) {
        case .overview:
            // syoung 10/05/2016 The layout of the ORKConsentSectionType.overview does not
            // match the layout of the other views so the animation is janky.
            return .custom
        case .privacy:
            return .privacy
        case .dataGathering:
            return .dataGathering
        case .dataUse:
            return .dataUse
        case .timeCommitment:
            return .timeCommitment
        case .studySurvey:
            return .studySurvey
        case .studyTasks:
            return .studyTasks
        case .onlyInDocument:
            return .onlyInDocument
        case .potentialRisks:
            // Internally, we use the "withdrawing" image and animation for potential risks
            return .withdrawing
        default:
            return .custom
        }
    }
    
    var customImage: UIImage? {
        let imageName = "consent_\(self.rawValue)"
        return SBAResourceFinder.shared.image(forResource: imageName)
    }
}

extension SBAConsentSection {
    
    func createConsentSection(previous: SBAConsentSectionType?) -> ORKConsentSection {
        let section = ORKConsentSection(type: self.consentSectionType.orkSectionType)
        section.title = self.sectionTitle
        section.formalTitle = self.sectionFormalTitle
        section.summary = self.sectionSummary
        section.content = self.sectionContent
        section.htmlContent = self.sectionHtmlContent
        section.customImage = self.sectionCustomImage ?? self.consentSectionType.customImage
        section.customAnimationURL = animationURL(previous: previous)
        section.customLearnMoreButtonTitle = self.sectionLearnMoreButtonTitle ?? Localization.buttonLearnMore()
        return section
    }
    
    func animationURL(previous: SBAConsentSectionType?) -> URL? {
        let fromSection = previous?.rawValue ?? "blank"
        let toSection = self.consentSectionType.rawValue
        let urlString = self.sectionCustomAnimationURLString ?? "consent_\(fromSection)_to_\(toSection)"
        let scaleFactor = UIScreen.main.scale >= 3 ? "@3x" : "@2x"
        return SBAResourceFinder.shared.url(forResource: "\(urlString)\(scaleFactor)", withExtension: "m4v")
    }
}


