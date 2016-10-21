//
//  SBAToggleFormStep.swift
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

public class SBAToggleFormStep: SBANavigationFormStep {
    
    var hasOnlyToggleItems: Bool {
        guard let formItems = self.formItems else { return true }
        for formItem in formItems {
            guard let answerFormat = formItem.answerFormat, answerFormat.isToggleAnswerFormat
            else {
                return false
            }
        }
        return true
    }
    
    public override func instantiateStepViewController(with result: ORKResult) -> ORKStepViewController {
        if hasOnlyToggleItems {
            let vc = SBAToggleFormStepViewController(step: self)
            vc.storedResult = result as? ORKStepResult
            return vc
        }
        else {
            return super.instantiateStepViewController(with: result)
        }
    }
}

extension ORKAnswerFormat {
    var isToggleAnswerFormat: Bool {
        return false
    }
}

extension ORKBooleanAnswerFormat {
    override var isToggleAnswerFormat: Bool {
        return true
    }
}

extension ORKTextChoiceAnswerFormat {
    override var isToggleAnswerFormat: Bool {
        return self.questionType == .singleChoice && self.textChoices.count == 2
    }
}

class SBAToggleFormStepViewController: ORKTableStepViewController, ORKTableStepSource, SBAToggleTableViewCellDelegate {
    
    override var tableStep: ORKTableStepSource? {
        return self
    }
    
    var formItems: [ORKFormItem]? {
        return (self.step as? ORKFormStep)?.formItems
    }
    
    var storedResult: ORKStepResult?
    
    override var result: ORKStepResult? {
        guard let stepResult = super.result else { return nil }
        stepResult.results = storedResult?.results ?? []
        return stepResult
    }
    
    public func numberOfRows(inSection section: Int) -> Int {
        return self.formItems?.count ?? 0
    }
    
    public func reuseIdentifierForRow(at indexPath: IndexPath) -> String {
        return SBAToggleTableViewCell.reuseIdentifier
    }
    
    private var preferredCellHeight: CGFloat = 130
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updatePreferredCellHeight()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredCellHeight()
    }
    
    func updatePreferredCellHeight() {
        let itemCount = self.numberOfRows(inSection: 0)
        if itemCount > 0 {
            let headerHeight = self.tableView.tableHeaderView?.bounds.height ?? 0
            let footerHeight = self.tableView.tableFooterView?.bounds.height ?? 0
            let overallHeight = self.tableView.bounds.size.height;
            let desiredCellHeight = floor((overallHeight - headerHeight - footerHeight)/CGFloat(itemCount))
            if desiredCellHeight != preferredCellHeight {
                preferredCellHeight = desiredCellHeight
                self.tableView.reloadData()
            }
        }
    }
    
    public func registerCells(for tableView: UITableView) {
        // Register the cells
        let bundle = Bundle(for: SBAToggleTableViewCell.classForCoder())
        let nib = UINib(nibName: "SBAToggleTableViewCell", bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: SBAToggleTableViewCell.reuseIdentifier)
    }
    
    public func configureCell(_ cell: UITableViewCell, indexPath: IndexPath, tableView: UITableView) {
        guard let toggleCell = cell as? SBAToggleTableViewCell,
            let items = self.formItems, items.count > indexPath.row else { return }
        toggleCell.configure(formItem: items[indexPath.row], stepResult: storedResult)
        toggleCell.delegate = self
        toggleCell.preferredHeightConstraint.constant = preferredCellHeight
    }
    
    func didChangeAnswer(cell: SBAToggleTableViewCell) {
        guard let cellResult = cell.result else { return }
        
        // Add the result to the stored results
        if storedResult == nil {
            storedResult = ORKStepResult(identifier: self.step!.identifier)
        }
        storedResult?.addResult(cellResult)
        
        updateButtonStates()
    }
    
    override func continueButtonEnabled() -> Bool {
        guard let items = self.formItems else { return false }
    
        // check if all results are answered
        let answerCount = items.filter({ storedResult?.result(forIdentifier: $0.identifier) != nil }).count
        return answerCount == items.count
    }
}

