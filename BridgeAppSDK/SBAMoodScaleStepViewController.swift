//
//  SBAMoodScaleStepViewController.swift
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

import UIKit

protocol SBAChoiceAnswerFormat: class {
    var questionChoices: [SBAChoice] { get }
}

extension ORKImageChoiceAnswerFormat: SBAChoiceAnswerFormat {
    var questionChoices: [SBAChoice] {
        return self.imageChoices as [SBAChoice]
    }
}

extension ORKTextChoiceAnswerFormat: SBAChoiceAnswerFormat {
    var questionChoices: [SBAChoice] {
        return self.textChoices as [SBAChoice]
    }
}

open class SBAMoodScaleStep: ORKQuestionStep {
    
    public override required init(identifier: String) {
        super.init(identifier: identifier)
        commonInit(inputItem:nil)
    }
    
    public init(inputItem: SBASurveyItem) {
        super.init(identifier: inputItem.identifier)
        commonInit(inputItem:inputItem)
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(step: ORKStep, images:[UIImage]?) {
        super.init(identifier: step.identifier)
        
        let defaultChoices = defaultImageChoices()
        let choices:[ORKImageChoice] = {
            guard let qStep = step as? SBAFormStepProtocol,
                let formItem = qStep.formItems?.first,
                let format = formItem.answerFormat as? SBAChoiceAnswerFormat,
                format.questionChoices.count == defaultChoices.count
            else {
                return defaultChoices
            }
            
            let replacementImages = images ?? defaultChoices.map({ $0.normalStateImage })
            let imageChoices = format.questionChoices.enumerated().map { (idx: Int, moodChoice: SBAChoice) -> ORKImageChoice in
                return ORKImageChoice(normalImage: replacementImages[idx],
                                      selectedImage: nil,
                                      text: moodChoice.choiceText,
                                      value: moodChoice.choiceValue)
            }
            return imageChoices
        }()
        
        self.answerFormat = ORKMoodScaleAnswerFormat(imageChoices: choices)
        setPrompt(with: step.title, and: step.text)
        self.isOptional = step.isOptional
    }
    
    open func commonInit(inputItem: SBASurveyItem?) {
        
        // Set title and text
        setPrompt(with: inputItem?.stepTitle?.trim(), and: inputItem?.stepText?.trim())
        
        // Set the answer format as a mapping from the default if there isn't an item defined
        let defaultChoices = defaultImageChoices()
        guard let surveyItem = inputItem as? SBAFormStepSurveyItem
        else {
            self.answerFormat = ORKMoodScaleAnswerFormat(imageChoices: defaultChoices)
            return
        }
        self.answerFormat = surveyItem.createMoodScaleAnswerFormat(with: defaultChoices)
        
        // Update optional value
        self.isOptional = surveyItem.optional
    }
    
    open func setPrompt(with prompt:String?, and detail:String?) {
        self.title = prompt ?? detail
        if (prompt != nil) {
            self.text = detail
        }
    }
    
    open func defaultImageChoices() -> [ORKImageChoice] {
        let scaleValues = Array(1...5)
        return scaleValues.map({ (scale) -> ORKImageChoice in
            let image = SBAResourceFinder.shared.image(forResource: "moodScale\(scale)")
            let text = Localization.localizedString("MOOD_SCALE_CHOICE_\(scale)")
            return ORKImageChoice(normalImage: image, selectedImage: nil, text: text, value: NSNumber(value: scale))
        })
    }

    open override func stepViewControllerClass() -> AnyClass {
        guard let scaleFormat = self.answerFormat as? ORKImageChoiceAnswerFormat,
            scaleFormat.imageChoices.count == 5
        else {
            return super.stepViewControllerClass()
        }
        return SBAMoodScaleStepViewController.self
    }
}

open class SBAMoodScaleStepViewController: ORKStepViewController {
    
    @IBOutlet open var titleLabel: UILabel?
    @IBOutlet open var textLabel: UILabel?
    @IBOutlet open var imageButtons: Array<UIButton>!
    @IBOutlet open var choiceLabels: Array<UILabel>!
    @IBOutlet open var largerChoiceLabel: UILabel?
    @IBOutlet open var nextButton: SBARoundedButton?
    @IBOutlet open var leadingLabel: UILabel?
    @IBOutlet open var trailingLabel: UILabel?
    @IBOutlet open var largerLabelToEmojiConstraint: NSLayoutConstraint?
    
    @IBAction func nextTapped(_ sender: Any) {
        self.goForward()
    }
    
    
    // MARK: Selection
    
    public var selectedIndex: Int {
        return _selectedIndex
    }
    private var _selectedIndex: Int = -1
    
    public var hasSelected: Bool {
        return _selectedIndex != -1
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        guard let tappedIndex = imageButtons.index(of: sender) else { return }
        if tappedIndex == _selectedIndex {
            _selectedIndex = -1
        }
        else {
            _selectedIndex = tappedIndex
        }
        updateSelectionState()
    }
    
    
    // MARK: Initialization

    open class var nibName: String {
        return String(describing: SBAMoodScaleStepViewController.self)
    }
    
    open class var bundle: Bundle {
        return Bundle(for: SBAMoodScaleStepViewController.classForCoder())
    }
    
    override public init(step: ORKStep?) {
        super.init(nibName: type(of: self).nibName, bundle: type(of: self).bundle)
        self.step = step
    }
    
    override public convenience init(step: ORKStep, result: ORKResult) {
        self.init(step: step)
        guard let stepResult = result as? ORKStepResult,
            let moodResult = stepResult.results?.first as? ORKMoodScaleQuestionResult,
            let moodScale = moodResult.scaleAnswer
        else {
            return
        }
        _selectedIndex = moodScale.intValue - 1
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    // MARK: Step Management
    
    public var moodStep: SBAMoodScaleStep? {
        return self.step as? SBAMoodScaleStep
    }
    
    public var moodChoices: [ORKImageChoice] {
        return (self.moodStep?.answerFormat as? ORKMoodScaleAnswerFormat)?.imageChoices ?? []
    }
    
    override open var result: ORKStepResult? {
        guard let stepResult = super.result else { return nil }
        if hasSelected {
            let moodResult = ORKMoodScaleQuestionResult(identifier: stepResult.identifier)
            moodResult.scaleAnswer = NSNumber(value: selectedIndex)
            stepResult.addResult(moodResult)
        }
        return stepResult
    }
    
    
    // MARK: Set up the view
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel?.textColor = UIColor.appTextDark
        textLabel?.textColor = UIColor.appTextDark
        largerChoiceLabel?.textColor = UIColor.appTextDark
        
        nextButton?.backgroundColor = UIColor.roundedButtonBackgroundDark
        nextButton?.shadowColor = UIColor.roundedButtonShadowDark
        nextButton?.titleColor = UIColor.roundedButtonTextLight
        nextButton?.corners = 26.0
        
        // Set up the button and label values
        guard moodChoices.count == imageButtons.count, moodChoices.count == choiceLabels.count
        else {
            return
        }
        
        for (index, button) in imageButtons.enumerated() {
            button.setImage(moodChoices[index].normalStateImage, for: .normal)
        }
        
        for (index, label) in choiceLabels.enumerated() {
            label.text = moodChoices[index].text
            label.textColor = UIColor.appTextDark
        }
        
        leadingLabel?.text = moodChoices.first!.text
        trailingLabel?.text = moodChoices.last!.text
        
        titleLabel?.text = self.step?.title
        textLabel?.text = self.step?.text
    }
    
    private var _isTruncated = false
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Check the text for sizing
        // syoung 07/10/2017 For consistency, always use the same layout on all devices
        _isTruncated = true // choiceLabels.reduce(false, { $0 || $1.isTruncated() })
        updateSelectionState()
    }
    
    func updateSelectionState() {
        
        for (index, button) in imageButtons.enumerated() {
            button.alpha = !hasSelected || (_selectedIndex == index) ? 1.0 : 0.3
        }
        
        for (index, label) in choiceLabels.enumerated() {
            label.isHidden = _isTruncated
            label.alpha = !hasSelected || (_selectedIndex == index) ? 1.0 : 0.3
        }
        
        let showLargerLabel = _isTruncated
        largerChoiceLabel?.isHidden = !showLargerLabel
        if showLargerLabel {
            largerChoiceLabel?.isEnabled = hasSelected
            if hasSelected {
                largerChoiceLabel?.text = moodChoices[_selectedIndex].text
            }
        }
        largerLabelToEmojiConstraint?.isActive = showLargerLabel
        
        // Only show the leading and trailing labels if nothing is selected and the 
        // choice labels are hidden.
        leadingLabel?.isHidden = !_isTruncated || hasSelected
        trailingLabel?.isHidden = !_isTruncated || hasSelected
        
        // Update the enabled state
        nextButton?.isEnabled = self.step!.isOptional || hasSelected
    }
}

extension UILabel {
    
    func isTruncated() -> Bool {
        guard let string = self.text else { return false }
        
        let constrainedWidthSize = calculateSize(for: string,
                                                 with: CGSize(width: self.frame.size.width,
                                                              height: CGFloat.greatestFiniteMagnitude))
        
        if (constrainedWidthSize.height > self.bounds.size.height) {
            return true
        }
        
        let singleLineSize = calculateSize(for: string,
                                           with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                        height: CGFloat.greatestFiniteMagnitude))
        
        if (singleLineSize.width > self.bounds.size.width) {
            let wordCount = string.components(separatedBy: .whitespacesAndNewlines).count
            let allowedWrapHeight = singleLineSize.height * CGFloat(wordCount)
            let actualWrapHeight = constrainedWidthSize.height
            let isTruncated = (actualWrapHeight > allowedWrapHeight)
            return isTruncated
        }
        
        return false
    }
    
    func calculateSize(for string:String, with boundingSize: CGSize) -> CGSize {
        return (string as NSString).boundingRect(
            with: boundingSize,
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: self.font],
            context: nil).size
    }
}
