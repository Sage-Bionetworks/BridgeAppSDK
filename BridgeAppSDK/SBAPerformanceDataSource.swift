//
//  SBAPerformanceDataSource.swift
//  BridgeAppSDK
//
//  Created by Michael L DePhillips on 6/24/17.
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//

import Foundation

public enum SBAPerformanceSection: Int {
    case studyProgress
    case activities
    case healthSummary
    case myTrends
    case count
}

public enum SBAPerformanceStudyProgressCellType: Int {
    case timeLeftInStudy
    case completedActivities
}

open class SBAPerformanceDataSource {
    
    public init() {
        // needed for subclass
    }
    
    open var orderedSections: [SBAPerformanceSection] {
        return [.studyProgress, .activities, .healthSummary, .myTrends]
    }
    
    /**
     Number of sections in the data source.
     @return    Number of sections.
     */
    open func numberOfSections() -> Int {
        return SBAPerformanceSection.count.rawValue
    }
    
    /**
     Number of rows in the data source.
     @param     section    The section of the collection
     @return               The number of rows in the given section.
     */
    open func numberOfRows(for section: Int) -> Int {
        guard let sectionType = sectionType(for: section) else {
            return 0
        }
        switch sectionType {
        case SBAPerformanceSection.studyProgress:
            return numberOfStudyProgress()
        case SBAPerformanceSection.activities:
            return numberOfActivities()
        case SBAPerformanceSection.healthSummary:
            return numberOfHealthSummaries()
        case SBAPerformanceSection.myTrends:
            return numberOfMyTrends()
        default:
            return 0
        }
    }
    
    /**
     @return the section type for the section number, nil if not the usual section
     */
    open func sectionType(for section: Int) -> SBAPerformanceSection? {
        return (orderedSections.filter { shouldShowSection(section: $0) })[section]
    }
    
    /**
     @return true if seciton should be shown, false to hide it
     */
    open func shouldShowSection(section: SBAPerformanceSection) -> Bool {
        return true
    }
    
    /**
     @return the number of study progress cells
     */
    open func numberOfStudyProgress() -> Int {
        return 2
    }
    
    /**
     @return the study progress cell type
     */
    open func studyProgressCellType(for row: Int) -> SBAPerformanceStudyProgressCellType {
        return SBAPerformanceStudyProgressCellType(rawValue: row)!
    }
    
    /**
     @return the number of activities to show in activities section
     */
    open func numberOfActivities() -> Int {
        return 0
    }
    
    /**
     @return the activity identifier for activities section cell row
     */
    open func activityIdentifier(for row: Int) -> String? {
        return nil
    }
    
    /**
     @return the activity name for activities section cell row
     */
    open func activityName(for row: Int) -> String? {
        return nil
    }
    
    /**
     @return the number of health summary cells
     */
    open func numberOfHealthSummaries() -> Int {
        return 0
    }
    
    /**
     @return the number of my trends cells
     */
    open func numberOfMyTrends() -> Int {
        return 1
    }
    
    /**
     @return the section title for the cell
     */
    open func sectionTitle(for section: Int) -> String? {
        guard let sectionType = sectionType(for: section) else {
            return nil
        }
        switch sectionType {
        case SBAPerformanceSection.studyProgress:
            return Localization.localizedString("SBA_STUDY_PROGRES_TITLE")
        case SBAPerformanceSection.activities:
            return Localization.localizedString("SBA_ACTIVITIES_TITLE")
        case SBAPerformanceSection.healthSummary:
            return Localization.localizedString("SBA_HEALTH_SUMMARY_TITLE")
        case SBAPerformanceSection.myTrends:
            return Localization.localizedString("SBA_MY_TRENDS_BALANCE_TITLE")
        default:
            return nil
        }
    }
    
    /**
     @return the message that shows when the help button is tapped in the section header
     */
    open func helpMessage(for section: Int) -> String? {
        guard let sectionType = sectionType(for: section) else {
            return nil
        }
        switch sectionType {
        case SBAPerformanceSection.studyProgress:
            return Localization.localizedString("SBA_STUDY_PROGRES_TITLE")
        case SBAPerformanceSection.activities:
            return Localization.localizedString("SBA_ACTIVITIES_TITLE")
        case SBAPerformanceSection.healthSummary:
            return Localization.localizedString("SBA_HEALTH_SUMMARY_TITLE")
        case SBAPerformanceSection.myTrends:
            return Localization.localizedString("SBA_MY_TRENDS_BALANCE_TITLE")
        default:
            return nil
        }
    }
}
