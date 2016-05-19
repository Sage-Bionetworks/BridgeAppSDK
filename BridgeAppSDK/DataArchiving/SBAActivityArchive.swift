//
//  SBAActivityArchive.swift
//  BridgeAppSDK
//
//  Created by Erin Mounts on 5/18/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

private let kSurveyCreatedOnKey               = "surveyCreatedOn";
private let kSurveyGuidKey                    = "surveyGuid";
private let kSchemaRevisionKey                = "schemaRevision";

class SBAActivityArchive: SBADataArchive {
    
    init(reference: String, result: SBAActivityResult) {
        super.init(reference: reference)
        
        if (result.schemaRevision != nil) {
            self.setArchiveInfoObject(result.schemaRevision, forKey: kSchemaRevisionKey)
        }
        if let surveyReference = result.schedule.activity.survey {
            // Survey schema is better matched by created date and survey guid
            self.setArchiveInfoObject(surveyReference.guid, forKey: kSurveyGuidKey)
            self.setArchiveInfoObject(surveyReference.createdOn.ISO8601String(), forKey: kSurveyCreatedOnKey)
        }
    }
    
    class func buildResultArchives(results: [SBAActivityResult]) -> [SBADataArchive]? {
        
        var archives = [SBADataArchive]()
        for activityResult in results {
            if let activityResultResults = activityResult.results as? [ORKStepResult] {
                let archive = SBAActivityArchive(reference: activityResult.schemaIdentifier, result: activityResult)
                for stepResult in activityResultResults {
                    if let stepResultResults = stepResult.results {
                        for result in stepResultResults {
                            guard let archiveableResult = result.bridgeData(stepResult.identifier) else {
                                assertionFailure("Something went wrong getting result to archive from result \(result.identifier) of step \(stepResult.identifier) of activity result \(activityResult.identifier)")
                                archive.removeArchive()
                                return nil
                            }
                            
                            if let urlResult = archiveableResult.result as? NSURL {
                                archive.insertURLIntoArchive(urlResult, fileName: archiveableResult.filename)
                            } else if let dictResult = archiveableResult.result as? [NSObject : AnyObject] {
                                archive.insertDictionaryIntoArchive(dictResult, filename: archiveableResult.filename)
                            } else if let dataResult = archiveableResult.result as? NSData {
                                archive.insertDataIntoArchive(dataResult, filename: archiveableResult.filename)
                            } else {
                                let className = NSStringFromClass(archiveableResult.result.classForCoder)
                                fatalError("Unsupported archiveable result type: \(className)")
                            }
                        }
                    }
                }
                
                if let error = archive.completeArchive() {
                    print("Completing the archive of \(activityResult.schemaIdentifier) failed:\n\(error)")
                } else {
                    archives += [archive]
                }
            }
        }
        
        return archives
    }
    
}
