//
//  SBAGenericStepDataSource.swift
//  BridgeAppSDK
//
//  Created by Josh Bruhin on 6/5/17.
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

import UIKit

/**
 SBAGenericStepDataSource: the internal model for SBAGenericStepViewController. It provides the UITableViewDataSource,
 manages and stores answers provided thru user input, and provides an ORKResult with those anwers upon request.
 
 It also provides several convenience methods for saving or selecting answers, checking if all answers are valid,
 and retrieving specific model objects that may be needed by the ViewController.
 
 The tableView data source is comprised of 3 objects:
 
 1) SBAGenericStepTableSection - An object representing a section in the tableView. It has one or more SBAGenericStepTableItemGroups.
 
 2) SBAGenericStepTableItemGroup - An object representing a specific question supplied by ORKStep in the form of ORKFormItem.
 An ORKFormItem can have multiple answer options, such as a boolean question or text choice
 question. Or, it can have just one answer option, in the case of alpha/numeric questions.
 
 Upon init(), the ItemGroup will create one or more SBAGenericStepTableItem representing the answer
 options for the ORKFormItem. The ItemGroup is responsible for storing/computing the answers
 for its ORKFormItem.
 
 3) SBAGenericStepTableItem - An object representing a specific answer option from the ItemGroup (ORKFormItem), such as a Yes or No
 choice in a boolean question or a string or number that's entered thru a text field. There will be
 one TableItem for each indexPath in the tableView.
 */

public protocol SBAGenericStepDataSourceDelegate {
    func answersDidChange()
}

open class SBAGenericStepDataSource: NSObject {
    
    open var delegate: SBAGenericStepDataSourceDelegate?
    open var sections: Array<SBAGenericStepTableSection> = Array()
    open var step: ORKStep?
    
    /**
     Initialize a new SBAGenericStepDataSource.
     @param  step       The ORKStep
     @param  result     The previous ORKResult, if any
     */
    public init(step: ORKStep?, result: ORKResult?) {
        super.init()
        self.step = step
        populate()
        if result != nil {
            updateAnswers(from: result!)
        }
    }
    
    func updateAnswers(from result: ORKResult) {
        
        // iterate the provided results, find the corresponding ItemGroup for each, and save the answer
        // provided in the results
        
        guard let stepResult = result as? ORKStepResult,
            let results = stepResult.results as? [ORKQuestionResult]
            else { return }
        
        for result in results {
            let answer = result.answer ?? ORKNullAnswerValue()
            if let group = itemGroup(with: result.identifier) {
                group.answer = answer as AnyObject
            }
        }
    }
    
    
    public func updateDefaults(_ defaults: NSMutableDictionary) {
        
        // TODO: Josh Bruhin, 6/12/17 - implement. this may require access to a HealthKit source.
        // This has not yet been needed for the onboarding flow
        
        for section in sections {
            section.itemGroups.forEach({
                if let newAnswer = defaults[$0.formItem.identifier] {
                    $0.defaultAnswer = newAnswer as AnyObject
                }
            })
        }
        
        // notify our delegate that the result changed
        if let delegate = delegate {
            delegate.answersDidChange()
        }
    }
    
    /**
     Determine if all answers are valid. Also checks the case where answers are required but one has not been provided.
     @return    A Bool indicating if all answers are valid
     */
    open func allAnswersValid() -> Bool {
        for section in sections {
            for itemGroup in section.itemGroups {
                if !itemGroup.isAnswerValid {
                    return false
                }
            }
        }
        return true
    }
    
    /**
     Retrieve the 'SBAGenericStepTableItemGroup' with a specific ORKFormItem identifier.
     @param   identifier   The identifier of the ORKFormItem assigned to the ItemGroup
     @return               The requested SBAGenericStepTableItemGroup, or nil if it cannot be found
     */
    open func itemGroup(with identifier: String) -> SBAGenericStepTableItemGroup? {
        for section in sections {
            for itemGroup in section.itemGroups {
                if itemGroup.formItem.identifier == identifier {
                    return itemGroup
                }
            }
        }
        return nil
    }
    
    /**
     Retrieve the 'SBAGenericStepTableItemGroup' for a specific IndexPath.
     @param   indexPath   The IndexPath that represents the ItemGroup in the tableView
     @return              The requested SBAGenericStepTableItemGroup, or nil if it cannot be found
     */
    open func itemGroup(at indexPath: IndexPath) -> SBAGenericStepTableItemGroup? {
        let section = sections[indexPath.section]
        for itemGroup in section.itemGroups {
            if itemGroup.beginningRowIndex ... itemGroup.beginningRowIndex + (itemGroup.items.count - 1) ~= indexPath.row {
                return itemGroup
            }
        }
        return nil
    }
    
    /**
     Retrieve the 'SBAGenericStepTableItem' for a specific IndexPath.
     @param   indexPath   The IndexPath that represents the TableItem in the tableView
     @return              The requested SBAGenericStepTableItem, or nil if it cannot be found
     */
    open func tableItem(at indexPath: IndexPath) -> SBAGenericStepTableItem? {
        if let itemGroup = itemGroup(at: indexPath) {
            let index = indexPath.row - itemGroup.beginningRowIndex
            return itemGroup.items[index]
        }
        return nil
    }
    
    /**
     Save an answer for a specific IndexPath.
     @param   answer      The object to be save as the answer
     @param   indexPath   The IndexPath that represents the TableItemGroup in the tableView
     */
    open func saveAnswer(_ answer: AnyObject, at indexPath: IndexPath) {
        
        let itemGroup = self.itemGroup(at: indexPath)
        itemGroup?.answer = answer
        
        // inform delegate that answers have changed
        if let delegate = delegate {
            delegate.answersDidChange()
        }
    }
    
    /**
     Select or deselect the answer option for a specific IndexPath.
     @param   indexPath   The IndexPath that represents the TableItemGroup in the tableView
     */
    open func selectAnswer(selected: Bool, at indexPath: IndexPath) {
        
        let itemGroup = self.itemGroup(at: indexPath)
        itemGroup?.select(selected, indexPath: indexPath)
        
        // inform delegate that answers have changed
        if let delegate = delegate {
            delegate.answersDidChange()
        }
    }
    
    /**
     Retrieve the current ORKStepResult.
     @return    An ORKStepResult object with the current answers for all of its ORKFormItems
     */
    open func results(parentResult: ORKStepResult) -> ORKStepResult {
        
        if let formItems = formItemsWithAnswerFormat() {
            
            // "Now" is the end time of the result, which is either actually now,
            // or the last time we were in the responder chain.
            
            let now = parentResult.endDate
            var qResults: Array<ORKResult> = Array()
            
            for formItem: ORKFormItem in formItems {
                
                var answer = ORKNullAnswerValue()
                var answerDate = now
                var systemCalendar = Calendar.current
                var systemTimeZone = NSTimeZone.system
                
                if let itemGroup = itemGroup(with: formItem.identifier) {
                    
                    answer = itemGroup.answer
                    
                    // check that answer is not NSNull (ORKNullAnswerValue)
                    // Skipped forms report a "null" value for every item -- by skipping, the user has explicitly said they don't want
                    // to report any values from this form.
                    if !(answer is NSNull) {
                        answerDate = itemGroup.answerDate ?? now
                        systemCalendar = itemGroup.calendar
                        systemTimeZone = itemGroup.timezone
                    }
               }
                
                guard let result = formItem.answerFormat?.result(withIdentifier: formItem.identifier, answer: answer) else {
                    continue
                }
                
                let impliedAnswerFormat = formItem.answerFormat?.implied()
                
                if let dateAnswerFormat = impliedAnswerFormat as? ORKDateAnswerFormat,
                    let dateQuestionResult = result as? ORKDateQuestionResult,
                    let _ = dateQuestionResult.dateAnswer {
                    
                    let usedCalendar = dateAnswerFormat.calendar ?? systemCalendar
                    dateQuestionResult.calendar = usedCalendar
                    dateQuestionResult.timeZone = systemTimeZone
                    
                }
                else if let numericAnswerFormat = impliedAnswerFormat as? ORKNumericAnswerFormat,
                    let numericQuestionFormat = result as? ORKNumericQuestionResult,
                    numericQuestionFormat.unit == nil {
                    
                    numericQuestionFormat.unit = numericAnswerFormat.unit
                }
                
                result.startDate = answerDate
                result.endDate = answerDate
                
                qResults.append(result)
            }
            
            qResults.forEach({ parentResult.addResult($0) })
        }
        
        return parentResult
    }
    
    fileprivate func formItemsWithAnswerFormat() -> Array<ORKFormItem>? {
        return self.formItems()?.filter { $0.answerFormat != nil }
    }
    
    fileprivate func formItems() -> [ORKFormItem]? {
        guard let formStep = self.step as? SBAFormStepProtocol else { return nil }
        return formStep.formItems
    }
    
    fileprivate func populate() {
        
        guard let items = formItems(), items.count > 0 else {
            return
        }
        
        let singleSelectionTypes: [ORKQuestionType] = [.boolean, .singleChoice, .multipleChoice, .location]
        
        for item in items {
            
            // some form items need to be in their own section
            var needExclusiveSection = false
            
            if let answerFormat = item.answerFormat?.implied() {

                let multiCellChoice = singleSelectionTypes.contains(answerFormat.questionType) && !(answerFormat is ORKValuePickerAnswerFormat)
                let multiLineTextEntry = answerFormat.questionType == .text
                let scale = answerFormat.questionType == .scale

                needExclusiveSection =  multiCellChoice || multiLineTextEntry || scale
            }
            
            // if we don't need an exclusive section and we have an existing section and it's not exclusive ('singleFormItem'),
            // then add this item to that existing section, otherwise create a new one
            if !needExclusiveSection, let lastSection = sections.last, !lastSection.singleFormItem {
                lastSection.add(formItem: item)
            }
            else {
                let section = SBAGenericStepTableSection(sectionIndex: sections.count)
                section.add(formItem: item)
                section.title = item.text
                section.singleFormItem = needExclusiveSection
                sections.append(section)
            }
        }
    }
}


open class SBAGenericStepTableSection: NSObject {
    
    open var itemGroups: Array<SBAGenericStepTableItemGroup> = Array()
    
    private var _title: String?
    var title: String? {
        get { return _title }
        set (newValue) { _title = newValue?.uppercased(with: Locale.current) }
    }
    
    /**
     Indicates whether this section is exclusive to a single form item or can contain multiple form items.
    */
    public var singleFormItem = false
    
    
    let index: Int!
    
    public init(sectionIndex: Int) {
        self.index = sectionIndex
        super.init()
    }
    
    /**
     Add a new ORKFormItem, which results in the creation and addition of a new SBAGenericStepTableItemGroup to the section.
     The ItemGroup essectially represents the FormItem and is reponsible for storing and providing answers for the FormItem
     when a ORKStepResult is requested.
     
     @param   formItem    The ORKFormItem to add to the section
     */
    public func add(formItem: ORKFormItem) {
        
        guard itemGroups.find({ $0.formItem.identifier == formItem.identifier }) == nil else {
            assertionFailure("Cannot add ORKFormItem with duplicate identifier.")
            return
        }
        
        itemGroups.append(SBAGenericStepTableItemGroup(formItem: formItem, beginningRowIndex: itemCount()))
    }
    
    /**
     Returns the total count of all Items in this section.
     @return    The total number of SBAGenericStepTableItems in this section
     */
    public func itemCount() -> Int {
        return itemGroups.reduce(0, {$0 + $1.items.count})
    }
}


open class SBAGenericStepTableItemGroup: NSObject {
    
    let formItem: ORKFormItem!
    
    var items: [SBAGenericStepTableItem]!
    var beginningRowIndex = 0
    
    var singleSelection: Bool = true
    
    var answerDate: Date?
    var calendar = Calendar.current
    var timezone = TimeZone.current
    
    var defaultAnswer: Any = ORKNullAnswerValue() as Any
    private var _answer: Any?
    
    /**
     Save an answer for this ItemGroup (FormItem). This is used only for those questions that have single answers,
     such as text and numeric answers, as opposed to booleans or text choice answers.
     */
    public var answer: Any! {
        get { return internalAnswer() }
        set { setInternalAnswer(newValue) }
    }
    
    /**
     Determine if the current answer is valid. Also checks the case where answer is required but one has not been provided.
     @return    A Bool indicating if answer is valid
     */
    public var isAnswerValid: Bool {
        
        // if answer is NOT optional and it equals Null (ORKNullAnswerValue()), or is nil, then it's invalid
        if !formItem.isOptional, answer is NSNull || answer == nil {
            return false
        }
        
        return formItem.answerFormat?.implied().isAnswerValid(answer) ?? false
    }
    
    /**
     Initialize a new ItemGroup with an ORKFormItem. Pass a beginningRowIndex since sections can have multiple ItemGroups.
     @param  formItem   The ORKFormItem to add to the model
     @param  beginningRowIndex  The row index in the section at which this formItem begins
     */
    fileprivate init(formItem: ORKFormItem, beginningRowIndex: Int) {
        
        self.formItem = formItem
        
        super.init()
        
        if let textChoiceAnswerFormat = formItem.answerFormat?.implied() as? ORKTextChoiceAnswerFormat {
            singleSelection = textChoiceAnswerFormat.style == .singleChoice
            self.items = textChoiceAnswerFormat.textChoices.enumerated().map { (index, _) -> SBAGenericStepTableItem in
                SBAGenericStepTableItem(formItem: formItem, choiceIndex: index, rowIndex: beginningRowIndex + index)
            }
        } else {
            let tableItem = SBAGenericStepTableItem(formItem: formItem, choiceIndex: 0, rowIndex: beginningRowIndex)
            self.items = [tableItem]
        }
        
    }
    
    /**
     Select or de-select an item (answer) at a specific indexPath. This is used for text choice and boolean answers.
     @param  selected   A bool indicating if item should be selected
     @param  indexPath  The IndexPath of the item
     */
    fileprivate func select(_ selected: Bool, indexPath: IndexPath) {
        
        // to get index of our item, add our beginningRowIndex to indexPath.row
        let index = beginningRowIndex + indexPath.row
        if items.count > index {
            items[index].selected = selected
        }
        
        // if we selected an item and this is a single-selection group, then we iterate
        // our other items and de-select them
        if singleSelection {
            for (ii, item) in items.enumerated() {
                item.selected = (ii == index)
            }
        }
    }
    
    fileprivate func internalAnswer() -> Any {
        
        guard let answerFormat = items.first?.formItem?.answerFormat else {
            return _answer ?? defaultAnswer
        }
        
        switch answerFormat {
        case is ORKBooleanAnswerFormat:
            return answerForBoolean()
            
        case is ORKMultipleValuePickerAnswerFormat,
             is ORKTextChoiceAnswerFormat:
            return answerForTextChoice()
            
        default:
            return _answer ?? defaultAnswer
        }
    }
    
    fileprivate func setInternalAnswer(_ answer: Any) {
        
        guard let answerFormat = items.first?.formItem?.answerFormat else {
            return
        }

        switch answerFormat {
        case is ORKBooleanAnswerFormat:
            
            // iterate our items and find the item with a value equal to our answer,
            // then select that item
            
            let formattedAnswer = answer as? NSNumber
            for item in items {
                if (item.choice?.value as? NSNumber)?.boolValue == formattedAnswer?.boolValue {
                    item.selected = true
                }
            }
            
        case is ORKTextChoiceAnswerFormat:
            
            // iterate our items and find the items with a value that is contained in our
            // answer, which should be an array, then select those items
            
            if let arrayAnswer = answer as? Array<AnyObject> {
                for item in items {
                    for selectedValue in arrayAnswer {
                        if let choiceString = item.choice?.value as? String, let selectedString = selectedValue as? String {
                            item.selected = choiceString == selectedString
                        }
                        else if let choiceNumber = item.choice?.value as? NSNumber, let selectedNumber = selectedValue as? NSNumber {
                            item.selected = choiceNumber.intValue == selectedNumber.intValue
                        }
                    }
                }
            }
            
        case is ORKMultipleValuePickerAnswerFormat:
            
            // TODO: Josh Bruhin, 6/12/17 - implement this answer format.
            fatalError("setInternalAnswer for ORKMultipleValuePickerAnswerFormat not implemented")
            
        default:
            _answer = answer
        }
    }
    
    private func answerForTextChoice() -> AnyObject {
        var array: Array<AnyObject> = Array()
        for item in items {
            if item.selected {
                array.append(item.choice!.value)
            }
        }
        return array.count > 0 ? array as AnyObject : ORKNullAnswerValue() as AnyObject
    }
    
    private func answerForBoolean() -> AnyObject {
        for item in items {
            if item.selected {
                if let value = item.choice?.value as? NSNumber {
                    return NSDecimalNumber(value: value.boolValue)
                }
            }
        }
        return ORKNullAnswerValue() as AnyObject
    }
}

open class SBAGenericStepTableItem: NSObject {
    
    // the same formItem assigned to the group that this item belongs to
    var formItem: ORKFormItem?
    var answerFormat: ORKAnswerFormat?
    var choice: ORKTextChoice?
    
    var choiceIndex = 0
    var rowIndex = 0
    
    var selected: Bool = false
    
    /**
     Initialize a new SBAGenericStepTableItem
     @param   formItem      The ORKFormItem representing this tableItem.
     @param   choiceIndex   The index of this item relative to all the choices in this ItemGroup
     @param   rowIndex      The index of this item relative to all rows in the section in which this item resides
     */
    fileprivate init(formItem: ORKFormItem!, choiceIndex: Int, rowIndex: Int) {
        super.init()
        commonInit(formItem: formItem)
        self.choiceIndex = choiceIndex
        self.rowIndex = rowIndex
        if let textChoiceFormat = textChoiceAnswerFormat() {
            choice = textChoiceFormat.textChoices[choiceIndex]
        }
    }
    
    func commonInit(formItem: ORKFormItem!) {
        self.formItem = formItem
        self.answerFormat = formItem.answerFormat?.implied()
    }
    
    func textChoiceAnswerFormat() -> ORKTextChoiceAnswerFormat? {
        guard let textChoiceFormat = self.answerFormat as? ORKTextChoiceAnswerFormat else { return nil }
        return textChoiceFormat
    }
}

