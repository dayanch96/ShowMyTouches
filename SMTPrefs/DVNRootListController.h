#import <Preferences/PSViewController.h>
#import "NSBundle+SMTPrefs.h"
#import "SMTUserDefaults.h"

@interface DVNRootListController : PSViewController <UITableViewDelegate, UITableViewDataSource> 
@property (nonatomic, strong) UITableView *tableView;
@end

@interface UISwitchVisualElement : UIView
@property (nonatomic, assign) BOOL showsOnOffLabel;
@end

@interface UISwitch (Private)
@property (nonatomic, strong) UISwitchVisualElement *visualElement;
@end

@interface UIColorWell (Private)
- (void)styleRequestedColorPickerPresentation;
- (void)invokeColorPicker:(id)colorPicker;
@end

@interface UISlider (Private)
- (void)setShowValue:(BOOL)showValue;
@end