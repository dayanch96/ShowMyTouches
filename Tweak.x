#import <UIKit/UIKit.h>
#import "Utils/SMTManager.h"

#if SIDELOADING
#import "Utils/SMTSettingsTrigger.h"
#endif

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;

#if SIDELOADING
    [SMTSettingsTrigger handleEvent:event];
#endif

    if (event.type != UIEventTypeTouches || !SMTManager.shouldShowTouches) {
        return;
    }

    for (UITouch *touch in [event allTouches]) {
        switch (touch.phase) {
            case UITouchPhaseBegan:
                [SMTManager showTouch:touch];
                break;
            case UITouchPhaseMoved:
                [SMTManager moveTouch:touch withEvent:event];
                break;
            case UITouchPhaseEnded:
            case UITouchPhaseCancelled:
                [SMTManager removeTouch:touch];
                break;
            default:
                break;
        }
    }
}
%end
