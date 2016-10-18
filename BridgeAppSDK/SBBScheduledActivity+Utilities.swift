//
//  SBBScheduledActivity+Utilities.swift
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

public extension SBBScheduledActivity {
    
    public var isCompleted: Bool {
        return self.finishedOn != nil
    }
    
    public var isExpired: Bool {
        return (self.expiresOn != nil) && ((Date() as NSDate).earlierDate(self.expiresOn) == self.expiresOn)
    }
    
    public var isNow: Bool {
        return !isCompleted && ((self.scheduledOn == nil) || ((self.scheduledOn.timeIntervalSinceNow < 0) && !isExpired))
    }
    
    var isToday: Bool {
        return SBBScheduledActivity.availableTodayPredicate().evaluate(with: self)
    }
    
    var isTomorrow: Bool {
        return SBBScheduledActivity.scheduledTomorrowPredicate().evaluate(with: self)
    }
    
    var scheduledTime: String {
        if isCompleted {
            return ""
        }
        else if isNow {
            return Localization.localizedString("SBA_NOW")
        }
        else {
            return DateFormatter.localizedString(from: scheduledOn, dateStyle: .none, timeStyle: .short)
        }
    }
    
    var expiresTime: String? {
        if expiresOn == nil { return nil }
        return DateFormatter.localizedString(from: expiresOn, dateStyle: .none, timeStyle: .short)
    }
    
    public dynamic var taskIdentifier: String? {
        return (self.activity.task != nil) ? self.activity.task.identifier : nil
    }
    
    public dynamic var surveyIdentifier: String? {
        guard self.activity.survey != nil else { return nil }
        return self.activity.survey.identifier
    }
    
    public dynamic var scheduleIdentifier: String {
        // Strip out the unique part of the guid
        if let range = self.guid.range(of: ":") {
            return self.guid.substring(to: range.lowerBound)
        }
        else {
            return self.guid
        }
    }
}
