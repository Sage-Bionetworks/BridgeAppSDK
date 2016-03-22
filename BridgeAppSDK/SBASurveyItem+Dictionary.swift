//
//  SBASurveyItem+Dictionary.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 3/16/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import ResearchKit

extension NSDictionary: SBASurveyItem {
    
    public var identifier: String! {
        return (self["identifier"] as? String) ?? "\(self.hash)"
    }
    
    public var surveyItemType: SBASurveyItemType {
        let type = self["type"] as? String
        return SBASurveyItemType(rawValue: type)
    }
    
    public var stepTitle: String? {
        return self["title"] as? String
    }
    
    public var stepText: String? {
        return (self["text"] as? String) ?? (self["prompt"] as? String)
    }
    
    public var stepDetail: String? {
        return self["detailText"] as? String
    }
    
    public func createCustomStep() -> ORKStep {
        return self.createInstructionStep()
    }
}

extension NSDictionary: SBAInstructionStepSurveyItem {
    
    public var stepImage: UIImage? {
        guard let imageNamed = self["image"] as? String else { return nil }
        return SBAResourceFinder().imageNamed(imageNamed)
    }
    
    public var learnMoreHTMLContent: String? {
        guard let html = self["learnMoreHTMLContentURL"] as? String,
            let htmlContent = SBAResourceFinder().htmlNamed(html) else {
                return nil;
        }
        return htmlContent
    }
}

extension NSDictionary: SBAFormStepSurveyItem {
    
    public var optional: Bool {
        let optional = self["optional"] as? Bool
        return optional ?? false
    }
    
    public var items: [AnyObject]? {
        return self["items"] as? [AnyObject]
    }
    
    public var range: AnyObject? {
        return nil 
    }
    
    public var skipIdentifier: String? {
        return self["skipIdentifier"] as? String
    }
    
    public var skipIfPassed: Bool {
        let skipIfPassed = self["skipIfPassed"] as? Bool
        return skipIfPassed ?? false
    }
    
    public var rulePredicate: NSPredicate? {
        if let subtype = self.surveyItemType.formSubtype() {
            if case .Boolean = subtype,
                let expectedAnswer = self.expectedAnswer as? Bool
            {
                return NSPredicate(format: "answer = %@", expectedAnswer)
            }
            else if case .SingleChoice = subtype,
                let expectedAnswer = self.expectedAnswer
            {
                let answerArray = [expectedAnswer]
                return NSPredicate(format: "answer = %@", answerArray)
            }
        }
        return nil;
    }
    
    public var expectedAnswer: AnyObject? {
        return self["expectedAnswer"]
    }
}