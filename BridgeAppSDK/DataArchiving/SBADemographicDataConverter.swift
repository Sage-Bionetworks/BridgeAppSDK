//
//  SBADemographicDataConverter.swift
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

// ===== WORK IN PROGRESS =====
// TODO: WIP syoung 12/06/2016 This is unfinished but b/c it is wrapped up with the profile
// and onboarding stuff, I don't want the branch lingering unmerged. This is ported from 
// AppCore and is still untested and *not* intended for production use.
// ============================


/**
 Data converter to use as a factory for converting objects to to an archivable object 
 for upload or saving to user defaults.
 */
public protocol SBADemographicDataConverter {
    
    /**
     Key/Value pair to insert into a dictionary for upload.
    */
    func uploadObject(for identifier: SBADemographicDataIdentifier) -> SBAAnswerKeyAndValue?
}

/**
 Demographics converter for shared key/value pairs included in the base implementation.
 */
public protocol SBABaseDemographicsUtility {
    var birthdate: Date? { get }
    var gender: HKBiologicalSex? { get }
    var height: HKQuantity? { get }
    var weight: HKQuantity? { get }
    var wakeTime: DateComponents? { get }
    var sleepTime: DateComponents? { get }
}

extension SBABaseDemographicsUtility {
    
    public func demographicsValue(for identifier: SBADemographicDataIdentifier) -> NSSecureCoding? {
        if identifier == SBADemographicDataIdentifier.currentAge,
            let currentAge = self.birthdate?.currentAge() {
            return NSNumber(value:currentAge)
        }
        else if identifier == SBADemographicDataIdentifier.biologicalSex {
            return self.gender?.demographicDataValue
        }
        else if identifier == SBADemographicDataIdentifier.heightInches,
            let quantity = quantityValue(for: self.height, with: HKUnit(from: .inch)) {
            return quantity
        }
        else if identifier == SBADemographicDataIdentifier.weightPounds,
            let quantity = quantityValue(for: self.weight, with: HKUnit(from: .pound)) {
            return quantity
        }
        else if identifier == SBADemographicDataIdentifier.wakeUpTime {
            return jsonTimeOfDay(for: self.wakeTime)
        }
        else if identifier == SBADemographicDataIdentifier.sleepTime {
            return jsonTimeOfDay(for: self.sleepTime)
        }
        return nil
    }
    
    public func jsonTimeOfDay(for dateComponents: DateComponents?) -> NSSecureCoding? {
        guard let dateComponents = dateComponents else { return nil }
        var time = dateComponents
        time.day = 0
        time.month = 0
        time.year = 0
        return (time as NSDateComponents).jsonObject()
    }
    
    public func quantityValue(for quantity: HKQuantity?, with unit:HKUnit) -> NSNumber? {
        guard let quantity = quantity, quantity.is(compatibleWith: unit)
        else {
            return nil
        }
        return NSNumber(value: quantity.doubleValue(for: unit))
    }
}

/**
 Demographic Data converter to use as a factory for converting from a task/result pairing to
 to an archivable object for upload or saving to user defaults.
 */
@objc
open class SBADemographicDataTaskConverter: NSObject, SBADemographicDataConverter, SBAResearchKitResultConverter, SBABaseDemographicsUtility {

    let results: [ORKStepResult]

    public var answerFormatFinder: SBAAnswerFormatFinder? {
        return _answerFormatFinder
    }
    let _answerFormatFinder: SBAAnswerFormatFinder
    
    public init(answerFormatFinder: SBAAnswerFormatFinder, results: [ORKStepResult]) {
        self.results = results
        self._answerFormatFinder = answerFormatFinder
        super.init()
    }
    
    public convenience init(answerFormatFinder: SBAAnswerFormatFinder, taskResult: ORKTaskResult) {
        self.init(answerFormatFinder: answerFormatFinder, results: taskResult.consolidatedResults())
    }
    
    open func uploadObject(for identifier:SBADemographicDataIdentifier) -> SBAAnswerKeyAndValue? {
        if let valueOnly = demographicsValue(for: identifier) {
            return SBAAnswerKeyAndValue(key: identifier.rawValue, value: valueOnly, questionType: .none)
        }
        else if let profileResult = findResult(for: identifier.rawValue) as? ORKQuestionResult,
            let answer = profileResult.jsonSerializedAnswer() {
            let result = SBAAnswerKeyAndValue(key: identifier.rawValue, value: answer.value, questionType: answer.questionType)
            result.unit = answer.unit
            return result
        }
        return nil
    }

    /**
     Return the result to be used for setting values in a profile.  Allow override. Default implementation
     iterates through the `ORKStepResult` objects until an `ORKResult` is found with a matching identifier.
     @return                Result for the given identifier
    */
    open func findResult(for identifier:String) -> ORKResult? {
        for stepResult in results {
            if let profileResult = stepResult.result(forIdentifier: identifier) {
                return profileResult
            }
        }
        return nil
    }
}

extension HKBiologicalSex {
    public var demographicDataValue: NSString? {
        switch (self) {
        case .female:
            return "Female"
        case .male:
            return "Male"
        case .other:
            return "Other"
        default:
            return nil
        }
    }
}

extension Date {
    public func currentAge() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.dateComponents([.year], from: self, to: Date()).year ?? 0
    }
}
