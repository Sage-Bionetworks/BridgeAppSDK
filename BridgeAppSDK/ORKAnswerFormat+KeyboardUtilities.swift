//
//  ORKAnswerFormat+KeyboardUtilities.swift
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

// Extend UITextAutocapitalizationType to support keyword init
extension UITextAutocapitalizationType {
    init(key: String?) {
        guard let key = key else {
            self.init(rawValue: 0)!
            return
        }
        switch key {
        case "words":
            self.init(rawValue:UITextAutocapitalizationType.Words.rawValue)!
        case "sentences":
            self.init(rawValue:UITextAutocapitalizationType.Sentences.rawValue)!
        case "all":
            self.init(rawValue:UITextAutocapitalizationType.AllCharacters.rawValue)!
        default:
            let intValue = Int(key) ?? 0
            self.init(rawValue: intValue)!
        }
    }
}

// Extend UIKeyboardType to support keyword init
extension UIKeyboardType {
    init(key: String?) {
        guard let key = key else {
            self.init(rawValue: 0)!
            return
        }
        switch key {
        case "ascii":
            self.init(rawValue: UIKeyboardType.ASCIICapable.rawValue)!
        case "numbersAndPunctuation":
            self.init(rawValue: UIKeyboardType.NumbersAndPunctuation.rawValue)!
        case "url":
            self.init(rawValue: UIKeyboardType.URL.rawValue)!
        case "numberPad":
            self.init(rawValue: UIKeyboardType.NumberPad.rawValue)!
        case "phonePad":
            self.init(rawValue: UIKeyboardType.PhonePad.rawValue)!
        case "namePhonePad":
            self.init(rawValue: UIKeyboardType.NamePhonePad.rawValue)!
        case "emailAddress":
            self.init(rawValue: UIKeyboardType.EmailAddress.rawValue)!
        case "decimalPad":
            self.init(rawValue: UIKeyboardType.DecimalPad.rawValue)!
        default:
            let intValue = Int(key) ?? 0
            self.init(rawValue: intValue)!
        }
    }
}
