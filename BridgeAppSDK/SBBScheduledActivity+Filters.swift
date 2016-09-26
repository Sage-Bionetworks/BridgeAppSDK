//
//  SBBScheduledActivity+Filters.swift
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

extension SBBScheduledActivity {
    
    public static func unfinishedPredicate() -> NSPredicate {
        return NSPredicate(format: "%K == nil", #keyPath(finishedOn))
    }
    
    public static func finishedTodayPredicate() -> NSPredicate {
        return NSPredicate(day: Date(), dateKey: #keyPath(finishedOn))
    }
    
    public static func scheduledTodayPredicate() -> NSPredicate {
        return NSPredicate(day: Date(), dateKey: #keyPath(scheduledOn))
    }
    
    public static func scheduledTomorrowPredicate() -> NSPredicate {
        return NSPredicate(day: Date().addingNumberOfDays(1), dateKey: #keyPath(scheduledOn))
    }
    
    public static func scheduledComingUpPredicate(numberOfDays: Int) -> NSPredicate {
        return NSPredicate(date: Date().addingNumberOfDays(1), dateKey: #keyPath(scheduledOn), numberOfDays: numberOfDays)
    }
    
    public static func expiredYesterdayPredicate() -> NSPredicate {
        return NSPredicate(day: Date().addingNumberOfDays(-1), dateKey: #keyPath(expiresOn))
    }
    
    public static func optionalPredicate() -> NSPredicate {
        return NSPredicate(format: "%K == 1", #keyPath(persistent))
    }
    
    public static func availableTodayPredicate() -> NSPredicate {
        let startOfToday = Date().startOfDay()
        let startOfTomorrow = startOfToday.addingNumberOfDays(1)
        
        // Scheduled today or prior
        let scheduledKey = #keyPath(scheduledOn)
        let todayOrBefore = NSPredicate(format: "%K == nil OR %K < %@", scheduledKey, scheduledKey, startOfTomorrow as CVarArg)
        
        // Unfinished or done today
        let unfinishedOrFinishedToday = NSCompoundPredicate(orPredicateWithSubpredicates: [unfinishedPredicate(), finishedTodayPredicate()])
        
        // Not expired
        let expiredKey = #keyPath(expiresOn)
        let notExpired = NSPredicate(format: "%K == nil OR %K > %@", expiredKey, expiredKey, startOfToday as CVarArg)
        
        // And
        let availableToday = NSCompoundPredicate(andPredicateWithSubpredicates: [todayOrBefore, unfinishedOrFinishedToday, notExpired])
        
        return availableToday
    }
}
