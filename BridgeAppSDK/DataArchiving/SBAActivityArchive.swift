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
private let kMetadataFilename                 = "metadata.json"

public class SBAActivityArchive: SBADataArchive {
    private var metadata = [String: AnyObject]()
    
    public init?(result: SBAActivityResult) {
        super.init(reference: result.schemaIdentifier)
        
        // set up the activity metadata
        // -- always set scheduledActivityGuid and taskRunUUID
        self.metadata[kScheduledActivityGuidKey] = result.schedule.guid
        self.metadata[kTaskRunUUIDKey] = result.taskRunUUID.UUIDString
        
        // -- if it's a task, also set the taskIdentifier
        if let taskReference = result.schedule.activity.task {
            self.metadata[kTaskIdentifierKey] = taskReference.identifier
        }
        
        // set up the info.json
        // -- always set the schemaRevision
        self.setArchiveInfoObject(result.schemaRevision, forKey: kSchemaRevisionKey)

        // -- if it's a survey, also set the survey's guid and createdOn
        if let surveyReference = result.schedule.activity.survey {
            // Survey schema is better matched by created date and survey guid
            self.setArchiveInfoObject(surveyReference.guid, forKey: kSurveyGuidKey)
            self.setArchiveInfoObject(surveyReference.createdOn.ISO8601String(), forKey: kSurveyCreatedOnKey)
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
        
        // (although there _still_ might be nothing to archive, if none of the stepResults have any results.)
        for stepResult in activityResultResults {
            if let stepResultResults = stepResult.results {
                for result in stepResultResults {
                    if !insertResult(result, stepResult: stepResult, activityResult: activityResult) {
                        return false
                    }
                }
            }
        }
        
        // don't insert the metadata if the archive is otherwise empty
        let builtArchive = !isEmpty()
        if builtArchive {
            insertDictionaryIntoArchive(self.metadata, filename: kMetadataFilename)
        }

        return builtArchive
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
