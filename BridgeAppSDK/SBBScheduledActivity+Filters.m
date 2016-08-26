//
//  SBBScheduledActivity+Filters.m
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

#import "SBBScheduledActivity+Filters.h"
#import <BridgeAppSDK/BridgeAppSDK-Swift.h>

@implementation SBBScheduledActivity (SBAFilters)

+ (NSPredicate *) unfinishedPredicate {
    return [NSPredicate predicateWithFormat:@"%K == nil", NSStringFromSelector(@selector(finishedOn))];
}

+ (NSPredicate *) finishedTodayPredicate {
    return [[NSPredicate alloc] initWithDay:[NSDate date] dateKey:NSStringFromSelector(@selector(finishedOn))];
}

+ (NSPredicate *) scheduledTodayPredicate {
    return [[NSPredicate alloc] initWithDay:[NSDate date] dateKey:NSStringFromSelector(@selector(scheduledOn))];
}

+ (NSPredicate *) availableTodayPredicate {
    
    // Scheduled today or prior
    NSString *scheduledKey = NSStringFromSelector(@selector(scheduledOn));
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *tomorrowMidnight = [calendar startOfDayForDate:[NSDate dateWithTimeIntervalSinceNow:24*60*60]];
    NSPredicate *todayOrBefore = [NSPredicate predicateWithFormat:@"%K == nil OR %K < %@", scheduledKey, scheduledKey, tomorrowMidnight];
    
    // Unfinished or done today
    NSPredicate *unfinishedOrFinishedToday = [NSCompoundPredicate orPredicateWithSubpredicates:@[[self unfinishedPredicate], [self finishedTodayPredicate]]];
    
    // Not expired
    NSString *expiredKey = NSStringFromSelector(@selector(expiresOn));
    NSPredicate *notExpired = [NSPredicate predicateWithFormat:@"%K == nil OR %K > %@", expiredKey, expiredKey, [calendar startOfDayForDate:[NSDate date]]];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[todayOrBefore, unfinishedOrFinishedToday, notExpired]];
}

+ (NSPredicate *) scheduledTomorrowPredicate {
    return [[NSPredicate alloc] initWithDay:[NSDate dateWithTimeIntervalSinceNow:24*60*60] dateKey:NSStringFromSelector(@selector(scheduledOn))];
}

+ (NSPredicate *) scheduledComingUpPredicate: (NSInteger)numberOfDays {
    return [[NSPredicate alloc] initWithDate:[NSDate dateWithTimeIntervalSinceNow:24*60*60] dateKey:NSStringFromSelector(@selector(scheduledOn)) numberOfDays:numberOfDays];
}

+ (NSPredicate *) expiredYesterdayPredicate {
    return [[NSPredicate alloc] initWithDay:[NSDate dateWithTimeIntervalSinceNow:-24*60*60] dateKey:NSStringFromSelector(@selector(expiresOn))];
}

+ (NSPredicate *) optionalPredicate {
    return [NSPredicate predicateWithFormat:@"%K == 1", NSStringFromSelector(@selector(persistent))];
}

@end
