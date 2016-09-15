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

public protocol SBAConsentSection: class {
    var consentSectionType: ORKConsentSectionType { get }
    var sectionTitle: String? { get }
    var sectionFormalTitle: String? { get }
    var sectionSummary: String? { get }
    var sectionContent: String? { get }
    var sectionHtmlContent: String? { get }
    var sectionLearnMoreButtonTitle: String? { get }
    var sectionCustomImage: UIImage? { get }
    var sectionCustomAnimationURL: URL? { get }
}

extension SBAConsentSection {
    
    func createConsentSection() -> ORKConsentSection {
        let section = ORKConsentSection(type: self.consentSectionType)
        section.title = self.sectionTitle
        section.formalTitle = self.sectionFormalTitle
        section.summary = self.sectionSummary
        section.content = self.sectionContent
        section.htmlContent = self.sectionHtmlContent
        section.customImage = self.sectionCustomImage
        section.customAnimationURL = self.sectionCustomAnimationURL
        section.customLearnMoreButtonTitle = self.sectionLearnMoreButtonTitle
        return section
    }
    
}

extension NSDictionary: SBAConsentSection {
    
    public var consentSectionType: ORKConsentSectionType {
        guard let sectionType = self["sectionType"] as? String else { return .custom }
        switch (sectionType) {
        case "overview"          : return .overview
        case "privacy"           : return .privacy
        case "dataGathering"     : return .dataGathering
        case "dataUse"           : return .dataUse
        case "timeCommitment"    : return .timeCommitment
        case "studySurvey"       : return .studySurvey
        case "studyTasks"        : return .studyTasks
        case "withdrawing"       : return .withdrawing
        case "onlyInDocument"    : return .onlyInDocument
        default                  : return .custom
        }
    }
    
    public var sectionTitle: String? {
        return self["sectionTitle"] as? String
    }
    
    public var sectionFormalTitle: String? {
        return self["sectionFormalTitle"] as? String
    }
    
    public var sectionSummary: String? {
        return self["sectionSummary"] as? String
    }
    
    public var sectionContent: String? {
        return self["sectionContent"] as? String
    }
    
    public var sectionLearnMoreButtonTitle: String? {
        return self["sectionLearnMoreButtonTitle"] as? String
    }
    
    public var sectionHtmlContent: String? {
        guard let htmlContent = self["sectionHtmlContent"] as? String else { return nil }
        return SBAResourceFinder.shared.html(forResource: htmlContent)
    }

    public var sectionCustomImage: UIImage? {
        guard let imageNamed = self["sectionImage"] as? String else { return nil }
        return SBAResourceFinder.shared.image(forResource: imageNamed)
    }
    
    public var sectionCustomAnimationURL: URL? {
        guard let resource = self["sectionAnimationUrl"] as? String else { return nil }
        let scaleFactor = UIScreen.main.scale >= 3 ? "@3x" : "@2x"
        return SBAResourceFinder.shared.url(forResource: "\(resource)\(scaleFactor)", withExtension: "m4v")
    }
}
