//
//  SBAPerformanceViewController.swift
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

open class SBAPerformanceViewController: UITableViewController, SBAScheduledActivityManagerDelegate {
    
    open var activityManager : SBABaseScheduledActivityManager {
        return _activityManager
    }
    lazy fileprivate var _activityManager : SBABaseScheduledActivityManager = {
        return SBAScheduledActivityManager(delegate: self)
    }()
    
    open var performanceDataSource : SBAPerformanceDataSource {
        return _performanceDataSource
    }
    lazy fileprivate var _performanceDataSource : SBAPerformanceDataSource = {
        return SBAPerformanceDataSource()
    }()
    
    open var completedActivitiesUntilWeCanDisplay: Int {
        return 3
    }
    
    lazy var blankPerformanceCells: [SBAPerformanceCellProtocol] = {
        return [
            SBAPerformanceTitleDetailsTableViewCell(),
            SBAPerformanceTitleIconDetailsTableViewCell(),
            SBAPerformanceProgressLinePlotTableViewCell(),
            SBAPerformanceSingleLinePlotTableViewCell(),
            SBAPerformanceTrendsGraphTableViewCell()]
    }()

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localization.localizedString("SBA_MY_PERFORMANCE_TITLE")
        
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.registerCells()
        
        self.activityManager.reloadData()
    }
    
    // SBAScheduledActivityManagerDelegate method
    open func reloadFinished(_ sender: Any?) {
        self.tableView.reloadData()
    }
    
    open func registerCells() {
        // Register UITableViewCells
        for cell in blankPerformanceCells {
            self.tableView.register(UINib(nibName: cell.cellName, bundle: Bundle(for: object_getClass(cell))), forCellReuseIdentifier: cell.cellName)
        }
        
        // Register UITableViewHeaderFooterViews
        self.tableView.register(UINib.init(nibName: SBAPerformanceSectionHeader.staticCellName, bundle: Bundle(for: SBAPerformanceSectionHeader.self)), forHeaderFooterViewReuseIdentifier: SBAPerformanceSectionHeader.staticCellName)
    }
    
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return performanceDataSource.numberOfSections()
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return performanceDataSource.numberOfRows(for: section)
    }
    
    /**
     * Estimations are based on the dashboard's storyboard view cell heights
     */
    override open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cell = self.tableView(tableView, cellForRowAt: indexPath) as? SBAPerformanceCellProtocol {
            return cell.estimatedCellHeight
        }
        return 0
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let sectionType = performanceDataSource.sectionType(for: indexPath.section) else {
            return self.cellForCustomSection(at: indexPath)
        }
        
        switch sectionType {
        case .studyProgress:
            let cellType = performanceDataSource.studyProgressCellType(for: indexPath.row)
            switch cellType {
                
            case .timeLeftInStudy:
                let cell = tableView.dequeueReusableCell(withIdentifier: SBAPerformanceProgressLinePlotTableViewCell.staticCellName, for: indexPath) as! SBAPerformanceProgressLinePlotTableViewCell
                cell.titleLabel.text = Localization.localizedString("SBA_STUDY_PROGRESS_TIME_LEFT_TITLE")
                cell.detailsLabel.attributedText = attributedTimeLeftStr()
                self.configureStudyProgressTimeLeftCell(cell: cell, for: indexPath)
                return cell
                
            default: //.completedActivities
                let cell = tableView.dequeueReusableCell(withIdentifier: SBAPerformanceTitleDetailsTableViewCell.staticCellName, for: indexPath) as! SBAPerformanceTitleDetailsTableViewCell
                cell.titleLabel.text = Localization.localizedString("SBA_STUDY_PROGRESS_COMPLETED_ACTIVITIES_TITLE")
                cell.detailsLabel.attributedText = self.completedActivitiesStr()
                cell.divider.isHidden = true
                self.configureTitleDetailsCell(cell: cell, for: indexPath)
                return cell
            }
            
        case .activities:
            if let activityIdentifier = self.performanceDataSource.activityIdentifier(for: indexPath.row) {
                let completedCount = self.completedActivities(for: activityIdentifier).count
                if completedCount >= completedActivitiesUntilWeCanDisplay {
                    let cell = tableView.dequeueReusableCell(withIdentifier: SBAPerformanceSingleLinePlotTableViewCell.staticCellName, for: indexPath) as! SBAPerformanceSingleLinePlotTableViewCell
                    self.configureActivityCell(cell: cell, for: indexPath)
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: SBAPerformanceTitleIconDetailsTableViewCell.staticCellName, for: indexPath) as! SBAPerformanceTitleIconDetailsTableViewCell
                    self.configureLockedActivityCell(cell: cell, for: indexPath)
                    return cell
                }
            }
            break
            
        case .healthSummary:
            return self.cellForHealthSummarySection(at: indexPath)
            
        case .myTrends:
            let cell = tableView.dequeueReusableCell(withIdentifier: SBAPerformanceTrendsGraphTableViewCell.staticCellName, for: indexPath) as! SBAPerformanceTrendsGraphTableViewCell
            self.configureMyTrendsCell(cell: cell, for: indexPath)
            return cell
        
        default: break
        }
        
//        cell.layoutIfNeeded() // <- added to fix bug where user had to scroll before correct autolayout height was calculated
        
        return UITableViewCell()
    }
    
    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: SBAPerformanceSectionHeader.staticCellName) as! SBAPerformanceSectionHeader
        sectionHeader.titleLabel.text = self.performanceDataSource.sectionTitle(for: section)
        sectionHeader.helpButton.tag = section
        sectionHeader.helpButton.addTarget(self, action: #selector(helpButtonTapped(with:)), for: .touchUpInside)
        self.configureSectionHeader(view: sectionHeader, for: section)
        return sectionHeader
    }
    
    override open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (self.tableView(tableView, viewForHeaderInSection: section) as? SBAPerformanceSectionHeader)?.estimatedCellHeight ?? 0
    }
    
    open func helpButtonTapped(with sender: UIButton) {
        self.showAlertWithOk(title: nil, message: self.performanceDataSource.helpMessage(for: sender.tag) ?? "", actionHandler: nil)
    }
    
    /**
     Should be overridden and used to adjust the look and feel of this cell
     */
    open func configureSectionHeader(view: SBAPerformanceSectionHeader, for section: Int) {
        
    }
    
    /**
     Override to enable custom cells for custom sections
     */
    open func cellForCustomSection(at indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    /**
     Override to setup and display custom health summary cells
     */
    open func cellForHealthSummarySection(at indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    /**
     Decorates an activity cell with the necessary details once the user has completed 
     enough to make the cell visible
     */
    open func configureActivityCell(cell: SBAPerformanceSingleLinePlotTableViewCell, for indexPath: IndexPath) {
        
        guard let activityIdetifier = performanceDataSource.activityIdentifier(for: indexPath.row) else {
            debugPrint("Could not find any activity identifiers for activity cell")
            return
        }
        
        cell.titleLabel.text = self.performanceDataSource.activityName(for: indexPath.row)
        var min = 40
        var max = 100
        let scoreArray = self.scores(for: activityIdetifier)
        let total = scoreArray.reduce(0, +)
        let average = total / scoreArray.count
        
        if (average < min) {
            min = 0
        }
        if ((average > 100) && (average < 200)) {
            max = 200
        } else if (average > 200) {
            max = average
        }
        
        cell.leftLegendLabel.text = "\(min)"
        cell.rightLegendLabel.text = "\(max)"
        cell.linePlotView.normalizedValue = 1.0 - (Float(average - min) / Float(max - min))
        
        cell.detailsLabel.attributedText = NSMutableAttributedString(
            string: "\(average)",
            attributes: detailNumberAttributes())
    }
    
    /**
     Decorates an activity cell with the necessary details before the user
     has completed the necessary amount of activities to unlock the cell
     */
    open func configureLockedActivityCell(cell: SBAPerformanceTitleIconDetailsTableViewCell, for indexPath: IndexPath) {
        
        guard let activityIdetifier = performanceDataSource.activityIdentifier(for: indexPath.row) else {
            debugPrint("Could not find any activity identifiers for activity cell")
            return
        }
        
        cell.titleLabel.text = self.performanceDataSource.activityName(for: indexPath.row)
        cell.icon.image = UIImage(named: "performance_icon_lock", in: Bundle.init(for: SBAPerformanceViewController.self), compatibleWith: nil)
        
        let remainingActivitiesCount = completedActivitiesUntilWeCanDisplay - self.scores(for: activityIdetifier).count
        if (remainingActivitiesCount == 1) {
            cell.detailsLabel.text = String(format: Localization.localizedString("SBA_ACTIVITIES_INCOMPLETE_%d_MSG"), remainingActivitiesCount)
        } else {
            cell.detailsLabel.text = String(format: Localization.localizedString("SBA_ACTIVITIES_INCOMPLETE_%d_PLURAL_MSG"), remainingActivitiesCount)
        }
    }
    
    /**
     Should be overridden and used to adjust the look and feel of this cell
     */
    open func configureTitleDetailsCell(cell: SBAPerformanceTitleDetailsTableViewCell, for indexPath: IndexPath) {
        
    }
 
    /**
     Should be overridden and used to adjust the look and feel of this cell
     */
    open func configureMyTrendsCell(cell: SBAPerformanceTrendsGraphTableViewCell, for indexPath: IndexPath) {
        cell.buttonBottom.setTitle(Localization.localizedString("SBA_MY_TRENDS_BUTTON_TITLE"), for: .normal)
    }
    
    /**
     * Styles the time left in study progress cell with the title,
     * time left in months and days string in the details,
     * and a progress line plot that is filled up based on time through the study
     */
    open func configureStudyProgressTimeLeftCell(cell: SBAPerformanceProgressLinePlotTableViewCell, for indexPath: IndexPath)
    {
        let appDelegate = UIApplication.shared.delegate as! SBAAppDelegate
        let studyDates = appDelegate.studyDates()
        let startDate = studyDates.startDate
        let endDate = studyDates.endDate
        
        // Convert study start and end dates to a normalized value between 0.0 and 1.0
        let calendar = Calendar.current
        let now = Date().timeIntervalSince1970
        let normalizedValue = Float(now - startDate.timeIntervalSince1970) / Float(endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
        
        // Calculate the number of months between start and end date and set that
        // as the line plot's progress max
        let monthsYearsBetweenStudyDates =  calendar.dateComponents([.year, .month], from: startDate, to: endDate)
        let lengthOfStudyInMonths = (1 + /* +1 for including current month */(monthsYearsBetweenStudyDates.month ?? 0)) + ((monthsYearsBetweenStudyDates.year ?? 0) * 12) // 12 months in a year
        cell.linePlotView.progressMax = lengthOfStudyInMonths
        
        // Apply the value of 0 to 1 to the study's duration
        cell.linePlotView.progress = Int(Float(lengthOfStudyInMonths) * normalizedValue)
        
        // Set the legend text, the study start month, middle month, and study end month
        let monthStrs = DateFormatter().shortMonthSymbols!
        cell.leftLegendLabel.text = monthStrs[(calendar.dateComponents([.month], from: startDate).month! - 1)] // -1 for 0 array indexing
        let midDate = calendar.date(byAdding: .month, value: lengthOfStudyInMonths / 2, to: startDate)!
        cell.midLegendLabel.text = monthStrs[(calendar.dateComponents([.month], from: midDate).month! - 1)] // -1 for 0 array indexing
        let month = calendar.dateComponents([.month], from: endDate).month!
        cell.rightLegendLabel.text = monthStrs[month - 1] // - 1 for 0 array indexing
    }
    
    /**
     * Styles the number of activities the user has done with a large blue number and
     * centered activities word
     */
    open func completedActivitiesStr() -> NSMutableAttributedString {
        let numberOfCompletedActivities = String(completedActivitiesCount())
        let completedActivitiesStr = "\(numberOfCompletedActivities)  \(Localization.localizedString("SBA_ACTIVITIES_TITLE").uppercased())"
        
        let attributedString = NSMutableAttributedString(
            string: completedActivitiesStr,
            attributes: detailTextAttributes())
        
        let completedStrRange = NSString(string: completedActivitiesStr).range(of: String(numberOfCompletedActivities))
        attributedString.setAttributes(detailNumberAttributes(), range: completedStrRange)
        
        return attributedString
    }
    
    /**
     Styles the time left in study string with large blue numbers and
     centered month and day descriptors
     */
    open func attributedTimeLeftStr() -> NSMutableAttributedString {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.month, .day]
        formatter.unitsStyle = .full
        var dateComponents = DateComponents()
        let (months, days) = timeUntilStudyEnds()
        dateComponents.month = months
        dateComponents.day = days
        let timeUntilStudyEndsStr = String(format: "%d MONTHS %d DAYS", months, days)
        let attributedString = NSMutableAttributedString(
            string: timeUntilStudyEndsStr,
            attributes: detailTextAttributes())
        
        let monthsRange = NSString(string: timeUntilStudyEndsStr).range(of: String(months))
        attributedString.setAttributes(detailNumberAttributes(), range: monthsRange)
        let daysRange = NSString(string: timeUntilStudyEndsStr).range(of: String(days))
        attributedString.setAttributes(detailNumberAttributes(), range: daysRange)
        return attributedString
    }
    
    /**
    @return NSAttributedString property map to be applied to the detail text in the cells
    */
    open func detailTextAttributes() -> [String : Any] {
        return [:]
    }
    
    /**
     @return NSAttributedString property map to be applied to the number text in the cells
     */
    open func detailNumberAttributes() -> [String : Any] {
        return [:]
    }
    
    /**
     @return a predicate the finds all the completed activities with a specific identifier
     */
    open func completedActivitiesFilter(identifier: String) -> NSPredicate {
        let taskIdentifiers = [identifier]
        let taskFilter = SBBScheduledActivity.includeTasksPredicate(with: taskIdentifiers)
        let completedFilter = SBBScheduledActivity.completedPredicate()
        return NSCompoundPredicate(andPredicateWithSubpredicates: [taskFilter, completedFilter])
    }
    
    /**
     @return the completed activities for a specific task type
     */
    open func completedActivities(for taskIdentifier: String) -> [SBBScheduledActivity] {
        let activities = self.activityManager.activities
        let completedActivityFilter = completedActivitiesFilter(identifier: taskIdentifier)
        let completedTaskActivities = activities.filter({ completedActivityFilter.evaluate(with: $0) })
        return completedTaskActivities
    }
    
    /**
     @return the total completed activities for all activities in the activities section
     */
    open func completedActivitiesCount() -> Int {
        var count = 0
        for index in 0 ..< self.performanceDataSource.numberOfActivities() {
            if let activityIdentifier = self.performanceDataSource.activityIdentifier(for: index) {
                count = count + completedActivities(for: activityIdentifier).count
            }
        }
        return count
    }
    
    /**
     @return the average score for all completed activities of the corresponding type
     */
    open func scores(for taskIdentifier: String) -> [Int] {
        var scores = [Int]()
        let activities = completedActivities(for: taskIdentifier)
        for activity in activities {
            // Get the score for this activity
            let json = activity.clientData as? [Int]
            let value = json?.last
            if (value != nil) {
                scores.append(value!)
            } else {
                // TODO: Remove this once scores are generated for every activity type.
                // Right now this is a bit of a workaround to generate a score for activities that don't
                // have them yet
                // easieg 6/3/17
                scores.append(0)
            }
        }
        
        return scores
    }
    
    /**
     * @return the number of months and days before the study ends
     */
    func timeUntilStudyEnds() -> (months: Int, days: Int) {
        let studyDates = (UIApplication.shared.delegate as! SBAAppDelegate).studyDates()
        let now = Date()
        let endDate = studyDates.endDate
        let calendar = NSCalendar.current
        var monthDif = calendar.dateComponents([.month], from: now, to: endDate)
        let dateComponents = NSDateComponents.init()
        dateComponents.setValue((0-monthDif.month!), forComponent: [.month])
        var endDateWithCurrentMonth = calendar.date(byAdding: dateComponents as DateComponents, to: endDate)
        var dayDif = calendar.dateComponents([.day], from: now, to: endDateWithCurrentMonth!)
        if (dayDif.day! < 0) {
            // This went too far back, so add 1 more month
            // Admittedly a bit clunky, but handles edge cases
            dateComponents.setValue((0-monthDif.month! + 1), forComponent: [.month])
            endDateWithCurrentMonth = calendar.date(byAdding: dateComponents as DateComponents, to: endDate)
            dayDif = calendar.dateComponents([.day], from: now, to: endDateWithCurrentMonth!)
        }
        return (monthDif.month!, dayDif.day!)
    }
}

open class SBAPerformanceSectionHeader: UITableViewHeaderFooterView, SBAPerformanceCellProtocol {
    
    public static let staticCellName = String(describing: SBAPerformanceSectionHeader.self)
    open var cellName: String {
        return SBAPerformanceSectionHeader.staticCellName
    }
    
    public static let staticEstimatedHeight = CGFloat(65)
    open var estimatedCellHeight: CGFloat {
        return SBAPerformanceSectionHeader.staticEstimatedHeight
    }
    
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var helpButton: UIButton!
    @IBOutlet public weak var shadowGradient: SBAShadowGradient!
}

open class SBAPerformanceTitleDetailsTableViewCell: UITableViewCell, SBAPerformanceCellProtocol {
    
    public static let staticCellName = String(describing: SBAPerformanceTitleDetailsTableViewCell.self)
    open var cellName: String {
        return SBAPerformanceTitleDetailsTableViewCell.staticCellName
    }
    
    open var estimatedCellHeight: CGFloat {
        return 136
    }
    
    open var smallDividerSpace: CGFloat {
        return 20
    }
    
    @IBOutlet public weak var titleLabel   : UILabel!
    @IBOutlet public weak var detailsLabel : UILabel!
    @IBOutlet public weak var divider      : UIView!
}

open class SBAPerformanceTitleIconDetailsTableViewCell: UITableViewCell, SBAPerformanceCellProtocol {
    
    public static let staticCellName = String(describing: SBAPerformanceTitleIconDetailsTableViewCell.self)
    open var cellName: String {
        return SBAPerformanceTitleIconDetailsTableViewCell.staticCellName
    }
    
    open var estimatedCellHeight: CGFloat {
        return 180
    }
    
    @IBOutlet public weak var titleLabel   : UILabel!
    @IBOutlet public weak var detailsLabel : UILabel!
    @IBOutlet public weak var icon         : UIImageView!
}

open class SBAPerformanceProgressLinePlotTableViewCell: UITableViewCell, SBAPerformanceCellProtocol {
    
    public static let staticCellName = String(describing: SBAPerformanceProgressLinePlotTableViewCell.self)
    open var cellName: String {
        return SBAPerformanceProgressLinePlotTableViewCell.staticCellName
    }
    
    open var estimatedCellHeight: CGFloat {
        return 180
    }
    
    @IBOutlet public weak var titleLabel           : UILabel!
    @IBOutlet public weak var detailsLabel         : UILabel!
    @IBOutlet public weak var linePlotView         : SBAProgressLinePlotView!
    @IBOutlet public weak var leftLegendLabel      : UILabel!
    @IBOutlet public weak var midLegendLabel       : UILabel!
    @IBOutlet public weak var rightLegendLabel     : UILabel!
}

open class SBAPerformanceSingleLinePlotTableViewCell: UITableViewCell, SBAPerformanceCellProtocol {
    
    public static let staticCellName = String(describing: SBAPerformanceSingleLinePlotTableViewCell.self)
    open var cellName: String {
        return SBAPerformanceSingleLinePlotTableViewCell.staticCellName
    }
    
    open var estimatedCellHeight: CGFloat {
        return 180
    }
    
    @IBOutlet public weak var titleLabel           : UILabel!
    @IBOutlet public weak var detailsLabel         : UILabel!
    @IBOutlet public weak var linePlotView         : SBASingleLinePlotView!
    @IBOutlet public weak var leftLegendLabel      : UILabel!
    @IBOutlet public weak var rightLegendLabel     : UILabel!
}

open class SBAPerformanceTrendsGraphTableViewCell: UITableViewCell, SBAPerformanceCellProtocol {
    
    public static let staticCellName = String(describing: SBAPerformanceTrendsGraphTableViewCell.self)
    open var cellName: String {
        return SBAPerformanceTrendsGraphTableViewCell.staticCellName
    }
    
    open var estimatedCellHeight: CGFloat {
        return 540
    }
    
    @IBOutlet public weak var buttonLeft           : UIButton!
    @IBOutlet public weak var buttonMid            : UIButton!
    @IBOutlet public weak var buttonRight          : UIButton!
    @IBOutlet public weak var buttonBottom         : UIButton!
    @IBOutlet public weak var graphView            : UIView!
}

public protocol SBAPerformanceCellProtocol {
    var cellName: String {get}
    var estimatedCellHeight: CGFloat {get}
}
