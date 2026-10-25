#import "SMTManager.h"
#import "../Views/SMTTouchView.h"
#import <SMTUserDefaults/SMTUserDefaults.h>
#import <Private/RPScreenRecorder.h>
#import <objc/runtime.h>

#define kTouchViewKey @selector(ShowMyTouches_TouchView)

@implementation SMTManager

+ (BOOL)shouldShowTouches {
    SMTUserDefaults *defaults = [SMTUserDefaults standardUserDefaults];
    if (!defaults.enabled) return NO;

    return !defaults.onlyWhileRecording || [[objc_getClass("RPScreenRecorder") sharedRecorder] isRecording];
}

+ (void)showTouch:(UITouch *)touch {
    SMTTouchView *touchView = [[SMTTouchView alloc] initWithCenter:[touch locationInView:nil]];
    [touch.window addSubview:touchView];

    objc_setAssociatedObject(touch, kTouchViewKey, touchView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)moveTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    SMTTouchView *touchView = objc_getAssociatedObject(touch, kTouchViewKey);
    if (!touchView) return;

    NSArray<UITouch *> *samples = [event coalescedTouchesForTouch:touch] ?: @[touch];
    for (UITouch *sample in samples) {
        [touchView moveToPoint:[sample locationInView:nil]];
    }
}

+ (void)removeTouch:(UITouch *)touch {
    SMTTouchView *touchView = objc_getAssociatedObject(touch, kTouchViewKey);
    objc_setAssociatedObject(touch, kTouchViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [touchView dismiss];
}

@end
