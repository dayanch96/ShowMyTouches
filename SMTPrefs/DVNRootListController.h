#if SIDELOADING
#import <UIKit/UIKit.h>
#else
#import <Preferences/PSViewController.h>
#endif
#import <PhotosUI/PhotosUI.h>
#import <Private/UISwitch+Private.h>
#import <Private/UIColorWell+Private.h>
#import <Private/UISlider+Private.h>
#import <NSBundle+SMTPrefs/NSBundle+SMTPrefs.h>
#import <NSString+SMTPrefs/NSString+SMTPrefs.h>
#import <SMTUserDefaults/SMTUserDefaults.h>

#if SIDELOADING
@interface DVNRootListController : UIViewController <UITableViewDelegate, UITableViewDataSource, PHPickerViewControllerDelegate>
#else
@interface DVNRootListController : PSViewController <UITableViewDelegate, UITableViewDataSource, PHPickerViewControllerDelegate>
#endif

@property (nonatomic, strong) UITableView *tableView;

@end
