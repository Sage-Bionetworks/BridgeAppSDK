//
//  SBAActivityArchive.swift
//  BridgeAppSDK
//
//  Created by Erin Mounts on 5/18/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

private let kSurveyCreatedOnKey               = "surveyCreatedOn"
private let kSurveyGuidKey                    = "surveyGuid"
private let kSchemaRevisionKey                = "schemaRevision"
private let kTaskIdentifierKey                = "taskIdentifier"
private let kScheduledActivityGuidKey         = "scheduledActivityGuid"
private let kTaskRunUUIDKey                   = "taskRunUUID"

public class SBAActivityArchive: SBADataArchive {
    
    public init?(result: SBAActivityResult) {
        super.init(reference: result.schemaIdentifier)
        
        // always set the schema revision, scheduled activity guid, and task run UUID
        self.setArchiveInfoObject(result.schemaRevision, forKey: kSchemaRevisionKey)
        self.setArchiveInfoObject(result.schedule.guid, forKey: kScheduledActivityGuidKey)
        self.setArchiveInfoObject(result.taskRunUUID.UUIDString, forKey: kTaskRunUUIDKey)
        
        // if it's a survey, also set the survey's guid and createdOn
        if let surveyReference = result.schedule.activity.survey {
            // Survey schema is better matched by created date and survey guid
            self.setArchiveInfoObject(surveyReference.guid, forKey: kSurveyGuidKey)
            self.setArchiveInfoObject(surveyReference.createdOn.ISO8601String(), forKey: kSurveyCreatedOnKey)
        }
        
        // if it's a task, also set the taskIdentifier
        if let taskReference = result.schedule.activity.task {
            self.setArchiveInfoObject(taskReference.identifier, forKey: kTaskIdentifierKey)
        }
        
        if !self.buildArchiveForResult(result) {
            self.removeArchive()
            return nil
        }
    }

    func buildArchiveForResult(activityResult: SBAActivityResult) -> Bool {
        
        // exit early with false if nothing to archive
        guard let activityResultResults = activityResult.results as? [ORKStepResult]
            where activityResultResults.count > 0
        else {
            return false
        }
        
        for stepResult in activityResultResults {
            if let stepResultResults = stepResult.results {
                for result in stepResultResults {
                    if !insertResult(result, stepResult: stepResult, activityResult: activityResult) {
                        return false
                    }
                }
            }
        }

        return true
    }
    
    /**
    * Method for inserting a result into an archive. Allows for override by subclasses
    */
    public func insertResult(result: ORKResult, stepResult: ORKStepResult, activityResult: SBAActivityResult) -> Bool {
        
        guard let archiveableResult = result.bridgeData(stepResult.identifier) else {
            assertionFailure("Something went wrong getting result to archive from result \(result.identifier) of step \(stepResult.identifier) of activity result \(activityResult.identifier)")
            return false
        }
        
        if let urlResult = archiveableResult.result as? NSURL {
            self.insertURLIntoArchive(urlResult, fileName: archiveableResult.filename)
        } else if let dictResult = archiveableResult.result as? [NSObject : AnyObject] {
            self.insertDictionaryIntoArchive(dictResult, filename: archiveableResult.filename)
        } else if let dataResult = archiveableResult.result as? NSData {
            self.insertDataIntoArchive(dataResult, filename: archiveableResult.filename)
        } else {
            let className = NSStringFromClass(archiveableResult.result.classForCoder)
            assertionFailure("Unsupported archiveable result type: \(className)")
            return false
        }
        
        return true
    }
    
}
