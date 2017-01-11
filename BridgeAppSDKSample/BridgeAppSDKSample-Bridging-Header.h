//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
//

// This will import all of the ResearchKit public headers
#import <ResearchKit/ResearchKit.h>

// Enter ResearchKit private header additions below

///// For LoginViewController

@interface ORKFormStepViewController (Resilience)
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)continueButtonEnabled;
- (void)showValidityAlertWithMessage:(NSString *)text;
@end

@interface ORKFormItemCell : UITableViewCell
-(ORKFormItem*)formItem;
@end

@interface ORKFormItemTextFieldBasedCell : ORKFormItemCell <UITextFieldDelegate>
- (UITextField *)textField;
- (void)inputValueDidChange;
@end


@interface ORKFormItemTextFieldCell : ORKFormItemTextFieldBasedCell
@end

@protocol ORKPickerDelegate <NSObject>
- (void)picker:(id)picker answerDidChangeTo:(id)answer;
@end

@protocol ORKPicker <NSObject>
@property (nonatomic, weak) id<ORKPickerDelegate> pickerDelegate;
- (UIView *)pickerView;
@property (nonatomic, strong) id answer;
@end

@interface ORKFormItemPickerCell : ORKFormItemTextFieldBasedCell <ORKPickerDelegate>
- (id<ORKPicker>)picker;
@end

//// End For LoginViewController

//// For Surveys

@interface ORKTableViewCell : UITableViewCell
@end

@interface ORKSurveyAnswerCell : ORKTableViewCell
- (void)ork_setAnswer:(id)answer;
- (void)showValidityAlertWithMessage:(NSString *)text;
@end

@interface ORKAnswerTextView : UITextView
@end

@interface ORKSurveyAnswerCellForText: ORKSurveyAnswerCell <UITextViewDelegate>
@property (nonatomic, strong) ORKAnswerTextView *textView;
- (void)textDidChange;
@end

@interface ORKQuestionStepViewController (Private) <UITableViewDelegate, UITableViewDataSource>
- (instancetype)initWithStep:(ORKStep *)step result:(ORKResult *)result;
- (instancetype)initWithStep:(ORKStep *)step;
- (ORKSurveyAnswerCell *)answerCellForTableView:(UITableView *)tableView;
- (BOOL)skipButtonEnabled;
- (void)skipForward;
- (BOOL)continueButtonEnabled;
@property (nonatomic, copy) id<NSCopying, NSObject, NSCoding> answer;
@end

@interface ORKLabel : UILabel
@end

@interface ORKSelectionTitleLabel : ORKLabel
@end

@interface ORKChoiceViewCell : UITableViewCell
- (void)setSelectedItem:(BOOL)selectedItem;
@property (nonatomic, strong, readonly) ORKSelectionTitleLabel *shortLabel;
@end

@interface ORKStepViewController (Private)
@property (nonatomic, strong) UIBarButtonItem *cancelButtonItem;
@property (nonatomic, strong) UIBarButtonItem *backButtonItem;
@property (nonatomic, strong) UIBarButtonItem *continueButtonItem;
@end

@interface ORKTaskViewController (Private)
- (NSArray *)managedResults;
- (IBAction)cancelAction:(UIBarButtonItem *)sender;
@end

////
