//
//  SBAActivityArchive.swift
//  BridgeAppSDK
//
// Copyright © 2016 Sage Bionetworks. All rights reserved.
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
import BridgeSDK

private let kSurveyCreatedOnKey               = "surveyCreatedOn"
private let kSurveyGuidKey                    = "surveyGuid"
private let kSchemaRevisionKey                = "schemaRevision"
private let kTaskIdentifierKey                = "taskIdentifier"
private let kScheduledActivityGuidKey         = "scheduledActivityGuid"
private let kScheduleIdentifierKey            = "scheduleIdentifier"
private let kScheduledOnKey                   = "scheduledOn"
private let kScheduledActivityLabelKey        = "activityLabel"
private let kTaskRunUUIDKey                   = "taskRunUUID"
private let kStartDate                        = "startDate"
private let kEndDate                          = "endDate"
private let kDataGroups                       = "dataGroups"
private let kMetadataFilename                 = "metadata.json"

public protocol SBAScheduledActivityResult {
    
    var identifier: String { get }
    var schemaIdentifier: String { get }
    var schemaRevision: NSNumber { get }
    var taskRunUUID: UUID { get }
    var startDate: Date { get }
    var endDate: Date { get }
    
    func archivableResults() -> [(String, SBAArchivableResult)]?
}

public protocol SBAArchivableResult {
    // returns result object, result type, and filename
    func bridgeData(_ stepIdentifier: String) -> ArchiveableResult?
    
    var identifier: String { get }
    var startDate: Date { get }
    var endDate: Date { get }
}

extension ORKResult : SBAArchivableResult {
}

extension SBAActivityResult: SBAScheduledActivityResult {
    
    public func archivableResults() -> [(String, SBAArchivableResult)]? {
        // exit early with false if nothing to archive
        guard let activityResultResults = self.results as? [ORKStepResult],
            activityResultResults.count > 0
            else {
                return nil
        }
        
        var results: [(String, SBAArchivableResult)] = []
        
        for stepResult in activityResultResults {
            if let stepResultResults = stepResult.results {
                for result in stepResultResults {
                    results.append((stepResult.identifier, result))
                }
            }
        }
        
        return results
    }
}

open class SBAActivityArchive: SBBDataArchive {

    fileprivate var metadata = [String: AnyObject]()
    
    public convenience init?(result: SBAActivityResult, jsonValidationMapping: [String: NSPredicate]? = nil) {
        self.init(result: result as SBAScheduledActivityResult, schedule: result.schedule, jsonValidationMapping: jsonValidationMapping)
    }
    
    public init?(result: SBAScheduledActivityResult, schedule: SBBScheduledActivity, jsonValidationMapping: [String: NSPredicate]? = nil) {
        
        super.init(reference: result.schemaIdentifier, jsonValidationMapping: jsonValidationMapping)
        
        // set up the activity metadata
        // -- always set scheduledActivityGuid, scheduleIdentifier, scheduledOn, activityLabel, and taskRunUUID
        self.metadata[kScheduledActivityGuidKey] = schedule.guid as AnyObject?
        self.metadata[kScheduleIdentifierKey] = schedule.scheduleIdentifier as AnyObject?
        self.metadata[kScheduledOnKey] = (schedule.scheduledOn as NSDate).iso8601String() as AnyObject?
        self.metadata[kScheduledActivityLabelKey] = schedule.activity.label as AnyObject?
        self.metadata[kTaskRunUUIDKey] = result.taskRunUUID.uuidString as AnyObject?
        
        // -- if it's a task, also set the taskIdentifier
        if let taskReference = schedule.activity.task {
            self.metadata[kTaskIdentifierKey] = taskReference.identifier as AnyObject?
        }
        
        // -- add the start/end date
        self.metadata[kStartDate] = (result.startDate as NSDate).iso8601String() as AnyObject?
        self.metadata[kEndDate] = (result.endDate as NSDate).iso8601String() as AnyObject?
        
        // -- add data groups
        if let dataGroups = SBAUser.shared.dataGroups {
            self.metadata[kDataGroups] = dataGroups.joined(separator: ",") as AnyObject?
        }
        
        // set up the info.json
        // -- always set the schemaRevision
        self.setArchiveInfoObject(result.schemaRevision, forKey: kSchemaRevisionKey)

        // -- if it's a survey, also set the survey's guid and createdOn
        if let surveyReference = schedule.activity.survey {
            // Survey schema is better matched by created date and survey guid
            self.setArchiveInfoObject(surveyReference.guid as SBAJSONObject, forKey: kSurveyGuidKey)
            let createdOn = surveyReference.createdOn ?? Date()
            self.setArchiveInfoObject((createdOn as NSDate).iso8601String() as SBAJSONObject, forKey: kSurveyCreatedOnKey)
        }
        
        if !self.buildArchiveForResult(result) {
            self.remove()
            return nil
        }
    }

    func buildArchiveForResult(_ activityResult: SBAScheduledActivityResult) -> Bool {
        guard let archivableResults = activityResult.archivableResults() else { return false }

        // (although there _still_ might be nothing to archive, if none of the stepResults have any results.)
        for (stepIdentifier, result) in archivableResults {
            if !insert(result: result, stepIdentifier: stepIdentifier, activityIdentifier: activityResult.identifier) {
                return false
            }
        }
        
        // don't insert the metadata if the archive is otherwise empty
        let builtArchive = !isEmpty()
        if builtArchive {
            insertDictionary(intoArchive: self.metadata, filename: kMetadataFilename, createdOn: activityResult.startDate)
        }

        return builtArchive
    }
    
    /**
    * Method for inserting a result into an archive. Allows for override by subclasses
    */
    open func insert(result: SBAArchivableResult, stepIdentifier: String, activityIdentifier: String) -> Bool {
        
        guard let archiveableResult = result.bridgeData(stepIdentifier) else {
            assertionFailure("Something went wrong getting result to archive from result \(result.identifier) of step \(stepIdentifier) of activity result \(activityIdentifier)")
            return false
        }
        
        if let urlResult = archiveableResult.result as? URL {
            self.insertURL(intoArchive: urlResult, fileName: archiveableResult.filename)
        } else if let dictResult = archiveableResult.result as? [AnyHashable: Any] {
            self.insertDictionary(intoArchive: dictResult, filename: archiveableResult.filename, createdOn: result.startDate)
        } else if let dataResult = archiveableResult.result as? NSData {
            self.insertData(intoArchive: dataResult as Data, filename: archiveableResult.filename, createdOn: result.startDate)
        } else {
            let className = NSStringFromClass(archiveableResult.result.classForCoder)
            assertionFailure("Unsupported archiveable result type: \(className)")
            return false
        }
        
        return true
    }
    
}
