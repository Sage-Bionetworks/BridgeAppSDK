//
//  SBAActivityTableViewController.swift
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

import UIKit
import ResearchKit
import BridgeSDK

@objc
public protocol SBAScheduledActivityDataSource: class {
    
    /**
     Reload the data source.
     */
    func reloadData()
    
    /**
     Number of sections in the data source.
     */
    func numberOfSections() -> Int
    
    /**
     Number of rows in the data source.
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
     Should the task associated with the given index path be disabled.
     */
    @objc(shouldShowTaskForIndexPath:)
    func shouldShowTask(for indexPath: IndexPath) -> Bool
    
    /**
     Called when a row is selected.
     */
    @objc(didSelectRowAtIndexPath:)
    optional func didSelectRow(at indexPath: IndexPath)
    
    /**
     Title for the given section (if applicable)
     */
    @objc(titleForSection:)
    optional func title(for section: Int) -> String?
}

open class SBAActivityTableViewController: UITableViewController, SBAScheduledActivityManagerDelegate {
    
    open var scheduledActivityDataSource: SBAScheduledActivityDataSource {
        return _scheduledActivityManager
    }
    lazy fileprivate var _scheduledActivityManager : SBAScheduledActivityManager = {
        return SBAScheduledActivityManager(delegate: self)
    }()
    
    fileprivate var foregroundNotification: NSObjectProtocol?
    
    deinit {
        if let notification = self.foregroundNotification {
            NotificationCenter.default.removeObserver(notification)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // refesh on load
        self.scheduledActivityDataSource.reloadData()
        
        // setup the refresh controller
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self.scheduledActivityDataSource, action: #selector(self.scheduledActivityDataSource.reloadData), for: .valueChanged)
        self.refreshControl = refreshControl
        
        // setup notification to refresh on return to foreground
        foregroundNotification = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: OperationQueue.main) {
            [weak self] _ in
            self?.scheduledActivityDataSource.reloadData()
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    // MARK: data refresh
    
    open func reloadFinished(_ sender: Any?) {
        // reload table
        self.refreshControl?.endRefreshing()
        self.tableView.reloadData()
    }
    
    // MARK: table cell customization
    
    static let defaultReuseIdentifier = "ActivityCell"

    /**
     The cell to dequeue at a given index path. By default, the cell should have a reuse identifier
     of `SBAActivityTableViewController.defaultReuseIdentifier`
     */
    @objc(dequeueReusableCellInTableView:indexPath:)
    open func dequeueReusableCell(in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: SBAActivityTableViewController.defaultReuseIdentifier, for: indexPath)
    }
    
    /**
     Configure the cell.
     */
    @objc(configureCell:tableView:indexPath:)
    open func configure(cell: UITableViewCell, in tableView: UITableView, at indexPath: IndexPath) {
        guard let activityCell = cell as? SBAActivityTableViewCell,
            let schedule = scheduledActivityDataSource.scheduledActivity(at: indexPath) else {
                return
        }
        
        // The only cell type that is supported in the base implementation is an SBAActivityTableViewCell
        let activity = schedule.activity
        activityCell.complete = schedule.isCompleted
        activityCell.titleLabel.text = activity?.label
        
        activityCell.timeLabel?.text = schedule.scheduledTime
        
        // Show a detail that is most appropriate to the schedule status
        if schedule.isCompleted {
            let format = Localization.localizedString("SBA_ACTIVITY_SCHEDULE_COMPLETE_%@")
            let dateString = DateFormatter.localizedString(from: schedule.finishedOn, dateStyle: .medium, timeStyle: .short)
            activityCell.subtitleLabel.text = String.localizedStringWithFormat(format, dateString)
        }
        else if schedule.isExpired {
            let format = Localization.localizedString("SBA_ACTIVITY_SCHEDULE_EXPIRED_%@")
            let dateString = schedule.isToday ? schedule.expiresTime! : DateFormatter.localizedString(from: schedule.expiresOn, dateStyle: .medium, timeStyle: .short)
            activityCell.subtitleLabel.text = String.localizedStringWithFormat(format, dateString)
        }
        else if schedule.isToday {
            activityCell.subtitleLabel.text = activity?.labelDetail
        }
        else if schedule.isTomorrow {
            activityCell.subtitleLabel.text = Localization.localizedString("SBA_ACTIVITY_SCHEDULE_AVAILABLE_TOMORROW")
        }
        else {
            let format = Localization.localizedString("SBA_ACTIVITY_SCHEDULE_AVAILABLE_ON_%@")
            let dateString = DateFormatter.localizedString(from: schedule.scheduledOn, dateStyle: .medium, timeStyle: .none)
            activityCell.subtitleLabel.text = String.localizedStringWithFormat(format, dateString)
        }
        
        // Modify the label colors if disabled
        if (scheduledActivityDataSource.shouldShowTask(for: indexPath)) {
            activityCell.titleLabel.textColor = UIColor.black
        }
        else {
            activityCell.titleLabel.textColor = UIColor.gray
        }
    }
    
    
    // Mark: UITableViewController overrides
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return scheduledActivityDataSource.numberOfSections()
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduledActivityDataSource.numberOfRows(for: section)
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(in: tableView, at: indexPath)
        configure(cell: cell, in: tableView, at: indexPath)
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return scheduledActivityDataSource.shouldShowTask(for: indexPath) ? indexPath : nil
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        scheduledActivityDataSource.didSelectRow?(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return scheduledActivityDataSource.title?(for: section)
    }
}

