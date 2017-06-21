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

open class SBASurveyTask: NSObject, ORKTask, NSCopying, NSSecureCoding {
    
    let factory: SBASurveyFactory
    let surveyReference: SBBSurveyReference
    
    open var title: String?
    open var schemaRevision: NSNumber?
    
    fileprivate var survey: ORKOrderedTask?
    
    public var error: Error? {
        return _error
    }
    fileprivate var _error: Error?
    
    required public init(surveyReference: SBBSurveyReference, factory: SBASurveyFactory) {
        self.surveyReference = surveyReference
        self.factory = factory
        super.init()
    }
    
    open func load(survey: SBBSurvey?, error: Error?) {
        // If there was an error or the survey is nil
        if survey == nil {
            let errorStep = ORKInstructionStep(identifier: "error")
            errorStep.title = Localization.localizedString("SBA_NETWORK_FAILURE_TITLE")
            errorStep.text = Localization.localizedString("SBA_NETWORK_FAILURE_MESSAGE")
            errorStep.detailText = error?.localizedDescription
            self.survey = ORKOrderedTask(identifier: self.identifier, steps: [errorStep])
            _error = error ?? NSError(domain: "SBASurveyTaskDomain",
                                      code: -1,
                                      userInfo: nil) as Error
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
    
    open var identifier: String {
        return surveyReference.identifier
    }
    
    open func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        if let task = survey {
            // If there is a task then go off of that for the identifiers
            if step?.identifier == SBASurveyTask.loadingStepIdentifier {
                return task.step(after: nil, with: result)
            }
            else {
                return task.step(after: step, with: result)
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
    
    open func step(before step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        return self.survey?.step(before: step, with: result)
    }
    
    open func step(withIdentifier identifier: String) -> ORKStep? {
        return self.survey?.step(withIdentifier: identifier)
    }
    
    open func progress(ofCurrentStep step: ORKStep, with result: ORKTaskResult) -> ORKTaskProgress {
        return self.survey?.progress(ofCurrentStep: step, with: result) ?? ORKTaskProgress()
    }
    
    // MARK: NSCopying
    
    open func copy(with zone: NSZone?) -> Any {
        let copy = type(of: self).init(surveyReference: surveyReference, factory: factory)
        copy.survey = self.survey
        copy.title = self.title
        copy.schemaRevision = self.schemaRevision
        return copy
    }
    
    // MARK: NSSecureCoding
    
    public static var supportsSecureCoding : Bool {
        return true
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.surveyReference.dictionaryRepresentation(), forKey: "surveyReference")
        if let encodableFactory = factory as? NSSecureCoding {
            aCoder.encode(encodableFactory, forKey: "factory")
        }
        aCoder.encode(self.survey, forKey: "survey")
        aCoder.encode(self.title, forKey: "title")
        aCoder.encode(self.schemaRevision, forKey: "schemaRevision")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let surveyReferenceDictionary = aDecoder.decodeObject(forKey: "surveyReference") as? [AnyHashable: Any],
            let surveyReference = SBBSurveyReference(dictionaryRepresentation: surveyReferenceDictionary) else {
                return nil
        }
        self.surveyReference = surveyReference
        self.factory = aDecoder.decodeObject(forKey: "factory") as? SBASurveyFactory ?? SBASurveyFactory()
        self.survey = aDecoder.decodeObject(forKey: "survey") as? ORKOrderedTask
        self.title = aDecoder.decodeObject(forKey: "title") as? String
        self.schemaRevision = aDecoder.decodeObject(forKey: "schemaRevision") as? NSNumber
        super.init()
    }

    // MARK: Equality
    
    override open var hash: Int {
        return self.surveyReference.hash
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
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
    
    var urlSessionTask: URLSessionTask?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadSurvey()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.urlSessionTask?.cancel()
    }
    
    var surveyTask: SBASurveyTask? {
        guard let surveyTask = self.step?.task as? SBASurveyTask else {
            assertionFailure("The task is not of expected type")
            return nil
        }
        return surveyTask
    }
    
    func loadSurvey() {
        self.urlSessionTask = SBABridgeManager.loadSurvey(surveyTask!.surveyReference, completion: { [weak self] (object, error) in
            let survey = object as? SBBSurvey
            self?.handleSurveyLoaded(survey: survey, error: error)
        })
    }
    
    func handleSurveyLoaded(survey: SBBSurvey?, error: Error?) {

        // Nil out the pointer to the url session
        self.urlSessionTask = nil
        
        // load the survey into the task and then go forward
        DispatchQueue.main.async { [weak self] in
            self?.surveyTask!.load(survey: survey, error: error)
            self?.goForward()
        }
    }
    
    override func shouldAnimateNavigation() -> Bool {
        return false
    }
}

