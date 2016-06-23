//
//  SBAProgressStep.swift
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

import ResearchKit

public class SBAProgressStep: ORKInstructionStep {
    
    public var index: Int {
        return _index
    }
    private var _index: Int!
    
    public var stepTitles: [String] {
        return _stepTitles
    }
    private var _stepTitles: [String]!
    
    // MARK: Default initializer

    public init(identifier: String, stepTitles:[String], index: Int) {
        let progessIdentifier = "\(identifier).\(stepTitles[index])"
        super.init(identifier: progessIdentifier)
        self._index = index
        self._stepTitles = stepTitles
        self.title = Localization.localizedString("SBA_PROGRESS_STEP_TITLE")
    }
    
    // MARK: Default view controller
    
    override public func instantiateStepViewControllerWithResult(result: ORKResult) -> ORKStepViewController {
        return SBAProgressStepViewController(step: self)
    }
    
    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _index = Int(aDecoder.decodeIntForKey("index"))
        _stepTitles = aDecoder.decodeObjectForKey("stepTitles") as? [String]
    }
    
    public override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(stepTitles, forKey: "stepTitles")
        aCoder.encodeInt(Int32(index), forKey: "index")
    }
    
    // MARK: Copying
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    public override func copyWithZone(zone: NSZone) -> AnyObject {
        let aCopy = super.copyWithZone(zone)
        guard let copy = aCopy as? SBAProgressStep else { return aCopy }
        copy._index = self.index
        copy._stepTitles = self.stepTitles
        return copy
    }
    
    // MARK: Equality
    
    public override var hash: Int {
        return super.hash | self.index | (self.stepTitles as NSArray).hash
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        guard let obj = object as? SBAProgressStep else { return false }
        return super.isEqual(object) &&
            self.index == obj.index &&
            self.stepTitles == obj.stepTitles
    }

}

public class SBAProgressStepViewController: ORKTableStepViewController {
    
    public var progressStep: SBAProgressStep? {
        return self.step as? SBAProgressStep
    }
    
    override public func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return self.progressStep?.stepTitles.count ?? 0
    }
    
    override public func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        // Get the cell and the progress step
        let reuseIdentifier = "ProgressCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: reuseIdentifier)
        }
        guard let step = progressStep else { return cell! }
        
        // Use unicode checkmark so that other languages can define the checkmark differently
        let checkmarkKey = (indexPath.row <= step.index) ? "SBA_PROGRESS_CHECKMARK" : "SBA_PROGRESS_UNCHECKED"
        let mark = Localization.localizedString(checkmarkKey)
        cell!.textLabel?.text = "\(mark) \(step.stepTitles[indexPath.row])"
        
        return cell!
    }
    
    override public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        // Do not highlight the cell
        return nil
    }
}
