//
//  SBASurveyTask.swift
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


import BridgeSDK
import ResearchKit

public class SBASurveyTask: NSObject, ORKTask, NSCopying, NSSecureCoding {
    
    let factory: SBASurveyFactory
    let surveyReference: SBBSurveyReference
    
    public var title: String?
    public var schemaRevision: NSNumber?
    
    private var survey: ORKOrderedTask?
    
    required public init(surveyReference: SBBSurveyReference, factory: SBASurveyFactory) {
        self.surveyReference = surveyReference
        self.factory = factory
        super.init()
    }
    
    public func load(survey survey: SBBSurvey?, error: NSError?) {
        // If there was an error or the survey is nil
        if survey == nil {
            let errorStep = ORKInstructionStep(identifier: "error")
            errorStep.title = Localization.localizedString("SBA_NETWORK_FAILURE_TITLE")
            errorStep.text = Localization.localizedString("SBA_NETWORK_FAILURE_MESSAGE")
            errorStep.detailText = error?.localizedFailureReason
            self.survey = ORKOrderedTask(identifier: self.identifier, steps: [errorStep])
        }
        else {
            self.survey = self.factory.createTaskWithSurvey(survey!)
            self.schemaRevision = survey?.schemaRevision
            if surveyReference.createdOn == nil {
                surveyReference.createdOn = survey?.createdOn
            }
        }
    }
    
    // MARK: ORKTask
    
    static let loadingStepIdentifier = "SBALoadingStepIdentifier"
    func createLoadingStep() -> ORKStep? {
        let loadingStep = SBASurveyLoadingStep(identifier: SBASurveyTask.loadingStepIdentifier)
        loadingStep.title = self.title
        loadingStep.text = Localization.localizedString("SBA_SURVEY_LOADING_TEXT")
        loadingStep.task = self
        return loadingStep
    }
    
    public var identifier: String {
        return surveyReference.identifier
    }
    
    public func stepAfterStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        if let task = survey {
            // If there is a task then go off of that for the identifiers
            if step?.identifier == SBASurveyTask.loadingStepIdentifier {
                return task.stepAfterStep(nil, withResult: result)
            }
            else {
                return task.stepAfterStep(step, withResult: result)
            }
        }
        else if step == nil {
            // Otherwise, if the step is nil then show the loading step
            return createLoadingStep()
        }
        else {
            return nil
        }
    }
    
    public func stepBeforeStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        return self.survey?.stepBeforeStep(step, withResult: result)
    }
    
    public func stepWithIdentifier(identifier: String) -> ORKStep? {
        return self.survey?.stepWithIdentifier(identifier)
    }
    
    public func progressOfCurrentStep(step: ORKStep, withResult result: ORKTaskResult) -> ORKTaskProgress {
        return self.survey?.progressOfCurrentStep(step, withResult: result) ?? ORKTaskProgress()
    }
    
    // MARK: NSCopying
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = self.dynamicType.init(surveyReference: surveyReference, factory: factory)
        copy.survey = self.survey
        copy.title = self.title
        copy.schemaRevision = self.schemaRevision
        return copy
    }
    
    // MARK: NSSecureCoding
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.surveyReference.dictionaryRepresentation(), forKey: "surveyReference")
        if let encodableFactory = factory as? NSSecureCoding {
            aCoder.encodeObject(encodableFactory, forKey: "factory")
        }
        aCoder.encodeObject(self.survey, forKey: "survey")
        aCoder.encodeObject(self.title, forKey: "title")
        aCoder.encodeObject(self.schemaRevision, forKey: "schemaRevision")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let surveyReferenceDictionary = aDecoder.decodeObjectForKey("surveyReference") as? [NSObject : AnyObject],
            let surveyReference = SBBSurveyReference(dictionaryRepresentation: surveyReferenceDictionary) else {
                return nil
        }
        self.surveyReference = surveyReference
        self.factory = aDecoder.decodeObjectForKey("factory") as? SBASurveyFactory ?? SBASurveyFactory()
        self.survey = aDecoder.decodeObjectForKey("survey") as? ORKOrderedTask
        self.title = aDecoder.decodeObjectForKey("title") as? String
        self.schemaRevision = aDecoder.decodeObjectForKey("schemaRevision") as? NSNumber
        super.init()
    }

    // MARK: Equality
    
    override public var hash: Int {
        return self.surveyReference.hash
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        guard let castObject = object as? SBASurveyTask else { return false }
        return self.surveyReference == castObject.surveyReference
    }
}

class SBASurveyLoadingStep: ORKWaitStep {
    override func stepViewControllerClass() -> AnyClass {
        return SBASurveyLoadingStepViewController.classForCoder()
    }
}

class SBASurveyLoadingStepViewController: ORKWaitStepViewController {
    
    var urlSessionTask: NSURLSessionTask?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let surveyTask = self.step?.task as? SBASurveyTask {
            self.urlSessionTask = SBABridgeManager.loadSurvey(surveyTask.surveyReference) { [weak self] (object, error) in
                self?.handleSurveyLoaded(survey: object as? SBBSurvey, error: error)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.urlSessionTask?.cancel()
    }
    
    func handleSurveyLoaded(survey survey: SBBSurvey?, error: NSError?) {
        guard let surveyTask = self.step?.task as? SBASurveyTask else {
            assertionFailure("The task is not of expected type")
            return
        }
        
        // Nil out the pointer to the url session
        self.urlSessionTask = nil
        
        // load the survey into the task and then go forward
        dispatch_async(dispatch_get_main_queue()) { 
            surveyTask.load(survey: survey, error: error)
            self.goForward()
        }
    }
}

