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


/**
 Data converter to use as a factory for converting objects to to an archivable object 
 for upload or saving to user defaults.
 */
public protocol SBADemographicDataConverter {
    
    /**
     Key/Value pair to insert into a dictionary for upload.
    */
    func uploadObject(for identifier: SBADemographicDataIdentifier) -> SBAAnswerKeyAndValue?
    
    /**
     Object that can be stored to the user's keychain using the secure coding protocol.
    */
    //func keychainObject(for identifier: String) -> NSSecureCoding?
}

/**
 Demographics converter for shared key/value pairs included in the base implementation.
 */
public protocol SBABaseDemographicsUtility {
    
    var gender: HKBiologicalSex? { get }
    var biologicalSex: HKBiologicalSex? { get }
    var birthdate: Date? { get }
    var bloodType: HKBloodType? { get }
    var fitzpatrickSkinType: HKFitzpatrickSkinType? { get }
    var wheelchairUse: Bool? { get }
    
    func quantity(for identifier: SBADemographicDataIdentifier) -> HKQuantity?
}

extension SBABaseDemographicsUtility {
    
    public func demographicsValue(for identifier: SBADemographicDataIdentifier) -> NSSecureCoding? {
        if identifier == SBADemographicDataIdentifier.currentAge,
            let currentAge = self.birthdate?.currentAge() {
            return NSNumber(value:currentAge)
        }
        else if identifier == SBADemographicDataIdentifier.biologicalSex {
            return self.biologicalSex?.demographicDataValue
        }
        else if identifier == SBADemographicDataIdentifier.heightInches,
            let quantity = quantityValue(for: identifier, with: HKUnit(from: .inch)) {
            return quantity
        }
        else if identifier == SBADemographicDataIdentifier.weightPounds,
            let quantity = quantityValue(for: identifier, with: HKUnit(from: .pound)) {
            return quantity
        }
        return nil
    }
    
    func quantityValue(for identifier: SBADemographicDataIdentifier, with unit:HKUnit) -> NSNumber? {
        guard let quantity = quantity(for: identifier),
            quantity.is(compatibleWith: unit)
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
open class SBADemographicDataTaskConverter: NSObject, SBADemographicDataConverter, SBAResearchKitProfileResultConverter, SBABaseDemographicsUtility {

    let answerFormatFinder: SBAAnswerFormatFinder
    let results: [ORKStepResult]
    
    public init(answerFormatFinder: SBAAnswerFormatFinder, results: [ORKStepResult]) {
        self.results = results
        self.answerFormatFinder = answerFormatFinder
        super.init()
    }
    
    public convenience init(answerFormatFinder: SBAAnswerFormatFinder, taskResult: ORKTaskResult) {
        self.init(answerFormatFinder: answerFormatFinder, results: taskResult.consolidatedResults())
    }
    
    open func uploadObject(for identifier:SBADemographicDataIdentifier) -> SBAAnswerKeyAndValue? {
        if let valueOnly = demographicsValue(for: identifier) {
            return SBAAnswerKeyAndValue(key: identifier.rawValue, value: valueOnly, questionType: .none)
        }
        else if let profileResult = profileResult(for: identifier.rawValue) as? ORKQuestionResult {
            return profileResult.jsonSerializedAnswer()
        }
        return nil
    }

    /**
     If the profile result can be converted to an HKQuantitySample and a matching healthKit quantity type
     can be found in the answer format finder, then create the given quantity sample with the appropriate unit.
     @param identifier      The demographic data identifier associated with this result
     @return                The quantity sample
     */
    open func quantitySample(for identifier: SBADemographicDataIdentifier) -> HKQuantitySample? {
        guard let profileResult = profileResult(for: identifier.rawValue) as? ORKQuestionResult,
            let quantity = quantity(for: identifier),
            let quantityType = quantityType(for: identifier)
            else {
                return nil
        }
        return HKQuantitySample(type: quantityType, quantity: quantity, start: profileResult.startDate, end: profileResult.endDate)
    }
    
    /**
     If the profile result can be converted to an HKQuantity, then create the given quantity
     with the appropriate unit.
     @param identifier      The demographic data identifier associated with this result
     @return                The quantity
     */
    open func quantity(for identifier: SBADemographicDataIdentifier) -> HKQuantity? {
        guard let profileResult = profileResult(for: identifier.rawValue) as? ORKQuestionResult,
            let answer = profileResult.jsonSerializedAnswer(),
            let doubleValue = (answer.value as? NSNumber)?.doubleValue,
            let unitString = answer.unit
            else {
                return nil
        }
        return HKQuantity(unit: HKUnit(from: unitString), doubleValue: doubleValue)
    }
    
    /**
     Find the quantity type associated with this identifier.
     @param identifier      The demographic data identifier associated with this result
     @return                The quantity type
     */
    open func quantityType(for identifier: SBADemographicDataIdentifier) -> HKQuantityType? {
        if let answerFormat = answerFormatFinder.find(for: identifier.rawValue) as? ORKHealthKitQuantityTypeAnswerFormat {
            return answerFormat.quantityType
        }
        else if identifier == SBADemographicDataIdentifier.heightInches {
            return HKObjectType.quantityType(forIdentifier: .height)
        }
        else if identifier == SBADemographicDataIdentifier.weightPounds {
            return HKObjectType.quantityType(forIdentifier: .bodyMass)
        }
        return nil
    }
    
    /**
     Return the result to be used for setting values in a profile.  Allow override. Default implementation
     iterates through the `ORKStepResult` objects until an `ORKResult` is found with a matching identifier.
     @return                Result for the given identifier
    */
    open func profileResult(for identifier:String) -> ORKResult? {
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
