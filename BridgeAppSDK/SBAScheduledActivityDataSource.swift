//
//  SBAScheduledActivityDataSource.swift
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
import ResearchKit
import BridgeSDK

/**
 The activity data source provides a source for vending `SBBScheduledActivity` objects.
 This can be used by a `UITableView` or `UICollectionView` to display the relevent information
 to the user.
 */
@objc
public protocol SBAScheduledActivityDataSource: class {
    
    /**
     Reload the data source.
     */
    func reloadData()
    
    /**
     Number of sections in the data source.
     @return    Number of sections.
     */
    func numberOfSections() -> Int
    
    /**
     Number of rows in the data source.
     @param     section    The section of the collection
     @return               The number of rows in the given section.
     */
    @objc(numberOfRowsInSection:)
    func numberOfRows(for section: Int) -> Int
    
    /**
     The scheduled activity at the given index.
     @param indexPath   The index path for the schedule
     */
    @objc(scheduledActivityAtIndexPath:)
    func scheduledActivity(at indexPath: IndexPath) -> SBBScheduledActivity?
    
    /**
     Whether or not the task should be enabled. This is different from whether or not a task is "available"
     in that it *only* applies to activities that are "greyed out" because they are expired, or because
     the task does not allow multiple runs of a completed activity.
     
     @param indexPath   The index path for the schedule
     @return            `YES` if the task should be displayed as enabled. `NO` if it is disabled.
     */
    @objc(shouldShowTaskForIndexPath:)
    func shouldShowTask(for indexPath: IndexPath) -> Bool
    
    /**
     Called when a row is selected.
     @param indexPath   The index path for the schedule
     */
    @objc(didSelectRowAtIndexPath:)
    optional func didSelectRow(at indexPath: IndexPath)
    
    /**
     Title for the given section (if applicable)
     @param     section    The section of the collection
     @return               The title for this section or `nil` if no title.
     */
    @objc(titleForSection:)
    optional func title(for section: Int) -> String?
}
