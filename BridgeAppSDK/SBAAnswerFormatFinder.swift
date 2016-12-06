//
//  SBAAnswerFormatFinder.swift
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

import ResearchKit

public class SBAResultIdentifier: NSObject {
    let stepIdentifier: String
    let identifier: String
    
    public init(identifier: String, stepIdentifier: String?) {
        self.identifier = identifier
        self.stepIdentifier = stepIdentifier ?? identifier
        super.init()
    }
}

public protocol SBAAnswerFormatFinder: class {
    func find(for identifier:String) -> ORKAnswerFormat?
    func resultIdentifier(for identifier:String) -> SBAResultIdentifier?
}

extension ORKOrderedTask: SBAAnswerFormatFinder {
    
    public func find(for identifier:String) -> ORKAnswerFormat? {
        for step in steps.reversed() {
            if let finder = step as? SBAAnswerFormatFinder,
                let answerFormat = finder.find(for: identifier) {
                return answerFormat
            }
        }
        return nil
    }
    
    public func resultIdentifier(for identifier: String) -> SBAResultIdentifier? {
        for step in steps.reversed() {
            if let finder = step as? SBAAnswerFormatFinder,
                let resultIdentifier = finder.resultIdentifier(for: identifier) {
                return resultIdentifier
            }
        }
        return nil
    }
}

extension ORKQuestionStep: SBAAnswerFormatFinder {
    
    public func find(for identifier:String) -> ORKAnswerFormat? {
        guard identifier == self.identifier else { return nil }
        return self.answerFormat
    }
    
    public func resultIdentifier(for identifier: String) -> SBAResultIdentifier? {
        guard identifier == self.identifier else { return nil }
        return SBAResultIdentifier(identifier: identifier, stepIdentifier: nil)
    }
}

extension ORKFormStep: SBAAnswerFormatFinder {
    
    public func find(for identifier:String) -> ORKAnswerFormat? {
        guard let formItems = self.formItems else { return nil }
        for formItem in formItems {
            if formItem.identifier == identifier {
                return formItem.answerFormat
            }
        }
        return nil
    }
    
    public func resultIdentifier(for identifier: String) -> SBAResultIdentifier? {
        guard find(for: identifier) != nil else { return nil }
        return SBAResultIdentifier(identifier: identifier, stepIdentifier: self.identifier)
    }
}

extension ORKPageStep: SBAAnswerFormatFinder {
    
    public func find(for identifier:String) -> ORKAnswerFormat? {
        for step in steps.reversed() {
            if let finder = step as? SBAAnswerFormatFinder,
                let answerFormat = finder.find(for: identifier) {
                return answerFormat
            }
        }
        return nil
    }
    
    public func resultIdentifier(for identifier: String) -> SBAResultIdentifier? {
        for step in steps.reversed() {
            if let finder = step as? SBAAnswerFormatFinder,
                let resultIdentifier = finder.resultIdentifier(for: identifier) {
                let mergedIdentifier = "\(resultIdentifier.stepIdentifier).\(resultIdentifier.identifier)"
                return SBAResultIdentifier(identifier: mergedIdentifier, stepIdentifier: self.identifier)
            }
        }
        return nil
    }
}

extension SBASubtaskStep: SBAAnswerFormatFinder {
    
    public func find(for identifier:String) -> ORKAnswerFormat? {
        guard let finder = self.subtask as? SBAAnswerFormatFinder else { return nil }
        return finder.find(for: identifier)
    }
    
    public func resultIdentifier(for identifier: String) -> SBAResultIdentifier? {
        guard let finder = self.subtask as? SBAAnswerFormatFinder,
            let resultIdentifier = finder.resultIdentifier(for: identifier)
        else {
            return nil
        }
        let stepIdentifier = "\(self.subtask.identifier).\(resultIdentifier.stepIdentifier)"
        return SBAResultIdentifier(identifier: identifier, stepIdentifier: stepIdentifier)
    }
}
