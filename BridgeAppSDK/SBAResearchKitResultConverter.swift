//
//  SBAResearchKitResultConverter.swift
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

import Foundation

/**
 Protocol for use in extending ResearchKit model objects and view controllers to 
 process the results.
 */
public protocol SBAResearchKitResultConverter: class {
    
    /**
     Returns an answer format finder that can be used to get the answer format for a 
     given identifier.
    */
    var answerFormatFinder: SBAAnswerFormatFinder? { get }
    
    /**
     Find the result associated with a given identifier.
    */
    func findResult(for identifier: String) -> ORKResult?
}

/**
 The base class of a step view controller can be extended to return the step as a `SBAAnswerFormatFinder`
 and to search for a form result as a subresult of this step view controller's `ORKStepResult`
 */
extension ORKStepViewController: SBAResearchKitResultConverter {
    
    public var answerFormatFinder: SBAAnswerFormatFinder? {
        return self.step as? SBAAnswerFormatFinder
    }
    
    public func findResult(for identifier: String) -> ORKResult? {
        // Use the answer format finder to find the result identifier associated with this result
        guard let resultIdentifier = self.answerFormatFinder?.resultIdentifier(for: identifier) else { return nil }
        // If found, return the result from the results included in this step result
        return self.result?.result(forIdentifier: resultIdentifier.identifier)
    }
}

/**
 Various convenience methods for converting a result into the appropriate object that defines that result.
 */
extension SBAResearchKitResultConverter {
    
    /**
     Look for an `ORKTimeOfDayQuestionResult` and get the date components from the result.
    */
    public func timeOfDay(for identifier: String) -> DateComponents? {
        guard let result = self.findResult(for: identifier) as? ORKTimeOfDayQuestionResult
            else {
                return nil
        }
        return result.dateComponentsAnswer
    }
    
    /**
     If the associated identifier can be mapped to a result from an `HKQuantitySample` then
     return the object created from that result.
    */
    public func quantitySample(for identifier: String) -> HKQuantitySample? {
        guard let profileResult = findResult(for: identifier) as? ORKQuestionResult,
            let quantity = quantity(for: identifier),
            let quantityType = quantityType(for: identifier)
            else {
                return nil
        }
        return HKQuantitySample(type: quantityType, quantity: quantity, start: profileResult.startDate, end: profileResult.endDate)
    }
    
    /**
     Get the `HKQuantity` associated with a given result to an `ORKFormItem` with a matching type.
    */
    public func quantity(for identifier: String) -> HKQuantity? {
        guard let profileResult = findResult(for: identifier) as? ORKQuestionResult,
            let answer = profileResult.jsonSerializedAnswer(),
            let doubleValue = (answer.value as? NSNumber)?.doubleValue,
            let unitString = answer.unit
            else {
                return nil
        }
        return HKQuantity(unit: HKUnit(from: unitString), doubleValue: doubleValue)
    }
    
    /**
     Get the `HKQuantityType` associated with a given answer format with a matching type.
    */
    public func quantityType(for identifier: String) -> HKQuantityType? {
        if let answerFormat = self.answerFormatFinder?.find(for: identifier) as? ORKHealthKitQuantityTypeAnswerFormat {
            return answerFormat.quantityType
        }
        else if let option = SBAProfileInfoOption(rawValue: identifier) {
            switch (option) {
            case .height:
                return HKObjectType.quantityType(forIdentifier: .height)
            case .weight:
                return HKObjectType.quantityType(forIdentifier: .bodyMass)
            default:
                break
            }
        }
        return HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier))
    }
    
    /**
     Convert an `ORKHealthKitCharacteristicTypeAnswerFormat` survey question into 
     an `HKBiologicalSex` enum value.
    */
    public func convertBiologicalSex(for identifier:String) -> HKBiologicalSex? {
        guard let result = self.findResult(for: identifier) as? ORKChoiceQuestionResult
            else { return nil }
        if  let answer = (result.choiceAnswers?.first as? NSNumber)?.intValue {
            return HKBiologicalSex(rawValue: answer)
        }
        else if let answer = result.choiceAnswers?.first as? String {
            // The ORKHealthKitCharacteristicTypeAnswerFormat uses a string rather
            // than using the HKBiologicalSex enum directly so you have to convert
            let biologicalSex = ORKBiologicalSexIdentifier(rawValue: answer)
            return biologicalSex.healthKitBiologicalSex()
        }
        else {
            return nil
        }
    }
    
    /**
     Convert an `ORKTextQuestionResult` for a given result into a string.
    */
    public func textAnswer(for identifier:String) -> String? {
        guard let result = self.findResult(for: identifier) as? ORKTextQuestionResult else { return nil }
        return result.textAnswer
    }
    
}

