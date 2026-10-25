#import <Foundation/Foundation.h>
#import "DVNRootListController.h"

#define TAG_FOR_INDEX_PATH(section, row) ((section << 16) | (row & 0xFFFF))
#define SECTION_FROM_TAG(tag) (tag >> 16)
#define ROW_FROM_TAG(tag) (tag & 0xFFFF)

@implementation DVNRootListController
{
    NSArray *_sections;
    NSArray *_main;
#if SIDELOADING
    NSArray *_access;
#endif
    NSArray *_effects;
    NSArray *_color;
    NSArray *_image;
    NSArray *_duration;
    NSArray *_size;
    NSArray *_radius;
    NSArray *_bwidth;
    NSArray *_reset;
    NSArray *_developer;
}

- (instancetype)init {

    self = [super init];

    if (self) {
        _main = @[
            @{@"title": @"Enable", @"icon": @"power", @"type": @"bool", @"key": @"enable", @"id": @"mainCell"},
            @{@"title": @"OnlyRecording", @"desc": @"OnlyRecordingDesc", @"icon": @"record.circle", @"type": @"bool", @"key": @"recording", @"id": @"mainCell"}
        ];

#if SIDELOADING
        _access = @[
            @{@"title": @"FourFingerDoubleTap", @"icon": @"hand.raised", @"type": @"bool", @"key": @"openFourFingerTap", @"id": @"mainCell"},
            @{@"title": @"ThreeFingerHold", @"icon": @"hand.point.up.left", @"type": @"bool", @"key": @"openThreeFingerHold", @"id": @"mainCell"},
            @{@"title": @"Shake", @"icon": @"iphone.radiowaves.left.and.right", @"type": @"bool", @"key": @"openShake", @"id": @"mainCell"}
        ];
#endif

        _effects = @[
            @{@"title": @"Morph", @"desc": @"MorphDesc", @"icon": @"drop", @"type": @"bool", @"key": @"morph", @"id": @"mainCell"},
            @{@"title": @"Comet", @"desc": @"CometDesc", @"icon": @"sparkles", @"type": @"bool", @"key": @"comet", @"id": @"mainCell"}
        ];

        _color = @[
            @{@"title": @"TouchColor", @"icon": @"hand.tap", @"type": @"colorpicker", @"key": @"touchColor", @"id": @"colorCell"},
            @{@"title": @"BorderColor", @"icon": @"circle", @"type": @"colorpicker", @"key": @"borderColor", @"id": @"colorCell"}
        ];

        _image = @[
            @{@"title": @"UseImage", @"desc": @"UseImageDesc", @"icon": @"photo", @"type": @"bool", @"key": @"useImage", @"id": @"mainCell"},
            @{@"title": @"ChooseImage", @"icon": @"photo.on.rectangle", @"type": @"image", @"key": @"touchImage", @"id": @"imageCell"}
        ];

        _duration = @[
            @{@"type": @"slider", @"min": @0, @"max": @3, @"divider": @0.1, @"key": @"duration", @"id": @"durationCell", @"style": @(UITableViewCellStyleValue1)}
        ];

        _size = @[
            @{@"type": @"slider", @"min": @20, @"max": @60, @"divider": @1, @"key": @"touchSize", @"id": @"touchSizeCell", @"style": @(UITableViewCellStyleValue1)}
        ];

        _radius = @[
            @{@"type": @"slider", @"min": @0, @"max": @30, @"divider": @1, @"key": @"touchRadius", @"id": @"touchRadiusCell", @"style": @(UITableViewCellStyleValue1)}
        ];

        _bwidth = @[
            @{@"type": @"slider", @"min": @0, @"max": @10, @"divider": @0.1, @"key": @"borderWidth", @"id": @"borderWidthCell", @"style": @(UITableViewCellStyleValue1)}
        ];

        _reset = @[
            @{@"title": @"ResetSettings", @"icon": @"trash",@"type": @"reset", @"key": @"reset", @"id": @"resetCell"},
        ];

        _developer = @[
            @{@"title": @"Dayanch96", @"desc": @"FollowMe", @"icon": @"dvn", @"type": @"link", @"key": @"https://twitter.com/dayanch96", @"id": @"devCell"},
            @{@"title": @"Github", @"desc": @"SourceCode", @"icon": @"github", @"type": @"link", @"key": @"https://github.com/dayanch96/ShowMyTouches", @"id": @"devCell"},
            @{@"title": @"Boosty", @"desc": @"Donate.Boosty", @"icon": @"boosty", @"type": @"link", @"key": @"https://boosty.to/dayanch96", @"id": @"devCell"},
            @{@"title": @"BuyMeACoffee", @"desc": @"Donate.BMC", @"icon": @"bmc", @"type": @"link", @"key": @"https://buymeacoffee.com/dayanch96", @"id": @"devCell"}
        ];

#if SIDELOADING
        _sections = @[_main, _access, _effects, _color, _image, _duration, _size, _radius, _bwidth, _reset, _developer];
#else
        _sections = @[_main, _effects, _color, _image, _duration, _size, _radius, _bwidth, _reset, _developer];
#endif
    }

    return self;
}

- (NSString *)title {
    return @"ShowMyTouches";
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tintColor = [UIColor colorWithRed:0.75 green:0.50 blue:0.90 alpha:1.0];

    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.tableView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.tableView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
        [self.tableView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor]
    ]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_sections[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *header;

#if SIDELOADING
    if (section == [_sections indexOfObject:_access]) {
        header = @"OpenSettings";
    }
#endif

    if (section == [_sections indexOfObject:_effects]) {
        header = @"Effects";
    }

    if (section == [_sections indexOfObject:_image]) {
        header = @"TouchImage";
    }

    if (section == [_sections indexOfObject:_duration]) {
        header = @"AnimationDuration";
    }

    if (section == [_sections indexOfObject:_size]) {
        header = @"TouchSize";
    }

    if (section == [_sections indexOfObject:_radius]) {
        header = @"CornerRadius";
    }

    if (section == [_sections indexOfObject:_bwidth]) {
        header = @"BorderWidth";
    }

    return [header smt_localized];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == _sections.count - 1 ? @"v" PACKAGE_VERSION : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }

    if (_sections[indexPath.section]) {
        NSArray *settingsData = _sections[indexPath.section];
        NSDictionary *data = settingsData[indexPath.row];

        cell = [[UITableViewCell alloc] initWithStyle:[data[@"style"] integerValue] ?: UITableViewCellStyleSubtitle reuseIdentifier:data[@"id"]];

        if (data[@"title"]) {
            cell.textLabel.text = [data[@"title"] smt_localized];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
        }

        if (data[@"desc"]) {
            cell.detailTextLabel.text = [data[@"desc"] smt_localized];
            cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            cell.detailTextLabel.numberOfLines = 0;
        }

        if ([data[@"type"] isEqualToString:@"bool"]) {
            cell.imageView.image = [UIImage systemImageNamed:data[@"icon"]];

            UISwitch *switchControl = [self switchForKey:data[@"key"]];
            switchControl.tag = TAG_FOR_INDEX_PATH(indexPath.section, indexPath.row);

            cell.accessoryView = switchControl;
        }

        if ([data[@"type"] isEqualToString:@"colorpicker"]) {
            cell.imageView.image = [UIImage systemImageNamed:data[@"icon"]];

            UIColorWell *colorWell = [self colorWellForKey:data[@"key"] title:[data[@"title"] smt_localized]];
            colorWell.tag = TAG_FOR_INDEX_PATH(indexPath.section, indexPath.row);

            cell.accessoryView = colorWell;
        }

        if ([data[@"type"] isEqualToString:@"image"]) {
            cell.imageView.image = [UIImage systemImageNamed:data[@"icon"]];
            cell.accessoryView = [self touchImagePreview];
        }

        if ([data[@"type"] isEqualToString:@"slider"]) {
            UISlider *slider = [self sliderWithKey:data[@"key"] min:[data[@"min"] floatValue] max:[data[@"max"] floatValue]];
            slider.tag = TAG_FOR_INDEX_PATH(indexPath.section, indexPath.row);

            if (slider.value == (NSInteger)slider.value) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (NSInteger)slider.value];
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", slider.value];
            }

            [cell.contentView addSubview:slider];

            [slider.leadingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.leadingAnchor constant:5.0].active = YES;
            [slider.trailingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.trailingAnchor constant:-50.0].active = YES;
            [slider.centerYAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.centerYAnchor].active = YES;
        }

        if ([data[@"type"] isEqualToString:@"reset"]) {
            cell.tintColor = [UIColor redColor];
            cell.textLabel.textColor = [UIColor redColor];
            cell.imageView.image = [UIImage systemImageNamed:data[@"icon"]];
        }

        if ([data[@"type"] isEqualToString:@"link"]) {
            UIImage *image = [UIImage imageNamed:data[@"icon"] inBundle:NSBundle.smt_defaultBundle compatibleWithTraitCollection:nil];

            cell.imageView.image = image;
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"safari"]];

            if ([data[@"icon"] isEqualToString:@"github"]) {
                cell.imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.imageView.tintColor = [UIColor labelColor];
            }
        }

        return cell;
    }

    return cell;
}

- (UISwitch *)switchForKey:(NSString *)key {
    UISwitch *switchControl = [[UISwitch alloc] init];
    switchControl.onTintColor = [UIColor colorWithRed:0.75 green:0.50 blue:0.90 alpha:1.0];
    switchControl.on = smtBool(key);
    switchControl.visualElement.showsOnOffLabel = YES;

    [switchControl addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];

    return switchControl;
}

- (UIColorWell *)colorWellForKey:(NSString *)key title:(NSString *)title {
    UIColor *color = [[SMTUserDefaults standardUserDefaults] colorForKey:key];

    UIColorWell *colorWell = [[UIColorWell alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    colorWell.title = title;
    colorWell.supportsAlpha = YES;
    colorWell.selectedColor = color;

    [colorWell addTarget:self action:@selector(colorWellTap:) forControlEvents:UIControlEventValueChanged];

    return colorWell;
}

- (UISlider *)sliderWithKey:(NSString *)key min:(CGFloat)min max:(CGFloat)max {
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = [[SMTUserDefaults standardUserDefaults] floatForKey:key];
    slider.translatesAutoresizingMaskIntoConstraints = NO;

    // [slider setShowValue:YES];
    [slider setThumbImage:[UIImage imageNamed:@"thumb" inBundle:NSBundle.smt_defaultBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

    [slider.heightAnchor constraintEqualToConstant:30.0].active = YES;
    
    return slider;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *settingsData = _sections[indexPath.section];
    NSDictionary *data = settingsData[indexPath.row];

    if ([data[@"type"] isEqualToString:@"bool"]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *switchControl = (UISwitch *)cell.accessoryView;

        [switchControl setOn:!switchControl.on animated:YES];
        [self toggleSwitch:switchControl];
    }

    if ([data[@"type"] isEqualToString:@"colorpicker"]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIColorWell *colorWell = (UIColorWell *)cell.accessoryView;

        if ([colorWell respondsToSelector:@selector(styleRequestedColorPickerPresentation)]) {
            [colorWell styleRequestedColorPickerPresentation];
        } else {
            [colorWell performSelector:@selector(invokeColorPicker:)];
        }
    }

    if ([data[@"type"] isEqualToString:@"image"]) {
        [self chooseTouchImageFromCell:[tableView cellForRowAtIndexPath:indexPath]];
    }

    if ([data[@"type"] isEqualToString:@"reset"]) {
        [SMTUserDefaults resetUserDefaults];
        [tableView reloadData];
    }

    if ([data[@"type"] isEqualToString:@"link"]) {
        NSURL *url = [NSURL URLWithString:data[@"key"]];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (void)toggleSwitch:(UISwitch *)sender {
    NSInteger tag = sender.tag;
    NSInteger section = SECTION_FROM_TAG(tag);
    NSInteger row = ROW_FROM_TAG(tag);

    NSDictionary *data = _sections[section][row];
    if (data) {
#if SIDELOADING
        if (!sender.isOn && [self isLastOpenSettingsKey:data[@"key"]]) {
            [sender setOn:YES animated:YES];
            [self showKeepOneOpenMethodAlert];
            return;
        }

#endif
        [[SMTUserDefaults standardUserDefaults] setBool:sender.isOn forKey:data[@"key"]];
    }
}

#if SIDELOADING
#pragma mark - Settings access

- (BOOL)isLastOpenSettingsKey:(NSString *)key {
    NSArray<NSString *> *keys = SMTUserDefaults.openSettingsKeys;
    if (![keys containsObject:key]) return NO;

    for (NSString *other in keys) {
        if (![other isEqualToString:key] && smtBool(other)) return NO;
    }

    return YES;
}

- (void)showKeepOneOpenMethodAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[@"KeepOneWayToOpenSettings" smt_localized] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[@"OK" smt_localized] style:UIAlertActionStyleDefault handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}
#endif

- (void)colorWellTap:(UIColorWell *)sender {
    NSInteger tag = sender.tag;
    NSInteger section = SECTION_FROM_TAG(tag);
    NSInteger row = ROW_FROM_TAG(tag);

    NSDictionary *data = _sections[section][row];

    if (data) {
        [[SMTUserDefaults standardUserDefaults] setColor:sender.selectedColor forKey:data[@"key"]];
    }
}

- (void)sliderValueChanged:(UISlider *)sender {
    NSInteger tag = sender.tag;
    NSInteger section = SECTION_FROM_TAG(tag);
    NSInteger row = ROW_FROM_TAG(tag);

    NSDictionary *data = _sections[section][row];

    if (data) {
        sender.value = round(sender.value / [data[@"divider"] floatValue]) * [data[@"divider"] floatValue];
        [[SMTUserDefaults standardUserDefaults] setFloat:sender.value forKey:data[@"key"]];

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

        if (sender.value == (NSInteger)sender.value) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (NSInteger)sender.value];
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", sender.value];
        }
    }
}

- (UIView *)touchImagePreview {
    UIImageView *preview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];
    UIImage *image = [SMTUserDefaults standardUserDefaults].touchImage;

    preview.image = image ?: [UIImage systemImageNamed:@"plus.circle"];
    preview.contentMode = image ? UIViewContentModeScaleAspectFit : UIViewContentModeCenter;
    preview.tintColor = [UIColor tertiaryLabelColor];

    return preview;
}

- (void)chooseTouchImageFromCell:(UITableViewCell *)cell {
    if (![SMTUserDefaults standardUserDefaults].touchImage) {
        [self presentImagePicker];
        return;
    }

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:[@"ChooseFromPhotos" smt_localized] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentImagePicker];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:[@"RemoveImage" smt_localized] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self saveTouchImage:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:[@"Cancel" smt_localized] style:UIAlertActionStyleCancel handler:nil]];

    sheet.popoverPresentationController.sourceView = cell;
    sheet.popoverPresentationController.sourceRect = cell.bounds;

    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentImagePicker {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.filter = [PHPickerFilter imagesFilter];
    configuration.selectionLimit = 1;

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];

    NSItemProvider *provider = results.firstObject.itemProvider;
    if (![provider canLoadObjectOfClass:[UIImage class]]) {
        return;
    }

    [provider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
        if ([object isKindOfClass:[UIImage class]]) {
            [self saveTouchImage:(UIImage *)object];
        }
    }];
}

- (void)saveTouchImage:(UIImage *)image {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        SMTUserDefaults *defaults = [SMTUserDefaults standardUserDefaults];
        defaults.touchImage = image;
        [defaults setBool:image != nil forKey:@"useImage"];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[self->_sections indexOfObject:self->_image]] withRowAnimation:UITableViewRowAnimationNone];
        });
    });
}

@end
