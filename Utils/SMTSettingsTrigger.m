#import "SMTSettingsTrigger.h"
#import "DVNRootListController.h"
#import <SMTUserDefaults/SMTUserDefaults.h>
#import <SMTTouchSettings/SMTTouchSettings.h>

#define SMTDistance(a, b) hypot((a).x - (b).x, (a).y - (b).y)

@implementation SMTSettingsTrigger {
    NSMapTable<UITouch *, NSValue *> *_startPoints;
    NSInteger _activeCount;

    CFTimeInterval _gestureStart;
    NSInteger _maxFingers;
    BOOL _moved;
    BOOL _consumed;
    BOOL _holdScheduled;

    CFTimeInterval _lastFourFingerTap;
    CFTimeInterval _lastOpen;
}

+ (instancetype)sharedTrigger {
    static SMTSettingsTrigger *trigger = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        trigger = [[self alloc] init];
    });

    return trigger;
}

+ (void)handleEvent:(UIEvent *)event {
    [[self sharedTrigger] handleEvent:event];
}

- (instancetype)init {
    self = [super init];

    if (self) {
        _startPoints = [NSMapTable weakToStrongObjectsMapTable];
    }

    return self;
}

#pragma mark - Events

- (void)handleEvent:(UIEvent *)event {
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        if ([SMTUserDefaults standardUserDefaults].shakeOpensSettings) [self openSettings];
        return;
    }

    if (event.type == UIEventTypeTouches) [self trackTouches:[event allTouches]];
}

- (void)trackTouches:(NSSet<UITouch *> *)touches {
    CFTimeInterval now = CACurrentMediaTime();
    NSInteger active = 0;
    BOOL cancelled = NO;

    if (_activeCount == 0) [self beginGestureAt:now];

    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:nil];

        if (touch.phase == UITouchPhaseBegan) {
            [_startPoints setObject:[NSValue valueWithCGPoint:location] forKey:touch];
        } else if (SMTDistance(location, [[_startPoints objectForKey:touch] CGPointValue]) > SMTTouchSettings.settingsGestureTolerance) {
            _moved = YES;
        }

        if (touch.phase == UITouchPhaseCancelled) cancelled = YES;
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled) active++;
    }

    _maxFingers = MAX(_maxFingers, (NSInteger)touches.count);
    _activeCount = active;

    [self updateHoldWithActiveCount:active];

    if (active == 0) [self finishGestureAt:now cancelled:cancelled];
}

- (void)beginGestureAt:(CFTimeInterval)now {
    _gestureStart = now;
    _maxFingers = 0;
    _moved = NO;
    _consumed = NO;
}

- (void)finishGestureAt:(CFTimeInterval)now cancelled:(BOOL)cancelled {
    BOOL tap = _maxFingers == 4 && !_moved && !_consumed && !cancelled && now - _gestureStart <= SMTTouchSettings.settingsTapDuration;

    if (!tap) {
        _lastFourFingerTap = 0;
        return;
    }

    if (_lastFourFingerTap > 0 && now - _lastFourFingerTap <= SMTTouchSettings.settingsDoubleTapInterval) {
        _lastFourFingerTap = 0;
        if ([SMTUserDefaults standardUserDefaults].fourFingerTapOpensSettings) [self openSettings];
        return;
    }

    _lastFourFingerTap = now;
}

#pragma mark - Three finger hold

- (void)updateHoldWithActiveCount:(NSInteger)active {
    BOOL holding = active == 3 && _maxFingers == 3 && !_moved && !_consumed;

    if (holding && !_holdScheduled) {
        _holdScheduled = YES;
        [self performSelector:@selector(holdFired) withObject:nil afterDelay:SMTTouchSettings.settingsHoldDuration];
    } else if (!holding && _holdScheduled) {
        _holdScheduled = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(holdFired) object:nil];
    }
}

- (void)holdFired {
    _holdScheduled = NO;
    _consumed = YES;

    if ([SMTUserDefaults standardUserDefaults].threeFingerHoldOpensSettings) [self openSettings];
}

#pragma mark - Presentation

- (void)openSettings {
    CFTimeInterval now = CACurrentMediaTime();
    if (now - _lastOpen < 1.0) return;
    _lastOpen = now;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *top = [self topViewController];
        if (!top || [self isShowingSettings:top]) return;

        [top presentViewController:[self settingsSheet] animated:YES completion:nil];
    });
}

- (UINavigationController *)settingsSheet {
    DVNRootListController *settings = [[DVNRootListController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;

    __weak UINavigationController *weakNavigation = navigation;
    settings.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose primaryAction:[UIAction actionWithHandler:^(UIAction *action) {
        [weakNavigation dismissViewControllerAnimated:YES completion:nil];
    }]];

    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = navigation.sheetPresentationController;
        sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent, UISheetPresentationControllerDetent.largeDetent];
        sheet.prefersGrabberVisible = YES;
    }

    return navigation;
}

- (BOOL)isShowingSettings:(UIViewController *)controller {
    return [controller isKindOfClass:[UINavigationController class]] && [((UINavigationController *)controller).viewControllers.firstObject isKindOfClass:[DVNRootListController class]];
}

- (UIViewController *)topViewController {
    UIWindow *keyWindow = nil;

    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;

        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) keyWindow = window;
        }
    }

    UIViewController *top = keyWindow.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }

    return top;
}

@end
