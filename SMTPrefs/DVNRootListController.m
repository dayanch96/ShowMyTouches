#import <Foundation/Foundation.h>
#import "DVNRootListController.h"

#define LOC(key) [NSBundle.smt_defaultBundle localizedStringForKey:key value:nil table:nil]

#define TAG_FOR_INDEX_PATH(section, row) ((section << 16) | (row & 0xFFFF))
#define SECTION_FROM_TAG(tag) (tag >> 16)
#define ROW_FROM_TAG(tag) (tag & 0xFFFF)

@implementation DVNRootListController
{
    NSArray *_sections;
    NSArray *_main;
    NSArray *_color;
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

        _color = @[
            @{@"title": @"TouchColor", @"icon": @"hand.tap", @"type": @"colorpicker", @"key": @"touchColor", @"id": @"colorCell"},
            @{@"title": @"BorderColor", @"icon": @"circle", @"type": @"colorpicker", @"key": @"borderColor", @"id": @"colorCell"}
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
            @{@"title": @"TipJar", @"desc": @"Donate.PayPal", @"icon": @"paypal", @"type": @"link", @"key": @"https://paypal.me/dayanch96", @"id": @"devCell"},
            @{@"title": @"Support", @"desc": @"Donate.KoFi", @"icon": @"kofi", @"type": @"link", @"key": @"https://ko-fi.com/dayanch96", @"id": @"devCell"}
        ];

        _sections = @[_main, _color, _duration, _size, _radius, _bwidth, _reset, _developer];
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

#pragma mark - Table view stuff
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

    return LOC(header);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == _sections.count - 1 ? @"v1.1.2" : nil;
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
            cell.textLabel.text = LOC(data[@"title"]);
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
        }

        if (data[@"desc"]) {
            cell.detailTextLabel.text = LOC(data[@"desc"]);
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

            UIColorWell *colorWell = [self colorWellForKey:data[@"key"] title:LOC(data[@"title"])];
            colorWell.tag = TAG_FOR_INDEX_PATH(indexPath.section, indexPath.row);

            cell.accessoryView = colorWell;
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
    NSData *colorData = [[SMTUserDefaults standardUserDefaults] objectForKey:key];
    UIColor *color = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:colorData error:nil];

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

#pragma mark - UITableViewDelegate
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
        [[SMTUserDefaults standardUserDefaults] setBool:sender.isOn forKey:data[@"key"]];
    }
}

- (void)colorWellTap:(UIColorWell *)sender {
    NSInteger tag = sender.tag;
    NSInteger section = SECTION_FROM_TAG(tag);
    NSInteger row = ROW_FROM_TAG(tag);

    NSDictionary *data = _sections[section][row];

    if (data) {
        NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:sender.selectedColor requiringSecureCoding:NO error:nil];
        [[SMTUserDefaults standardUserDefaults] setObject:colorData forKey:data[@"key"]];
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

@end
