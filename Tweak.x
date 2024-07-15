#import <UIKit/UIKit.h>
#import "SMTPrefs/SMTUserDefaults.h"

BOOL isRecording(void) {
	for (UIScreen *screen in [UIScreen screens]) {
		if ([screen isCaptured]) {
			return YES;
		}
	}

	return NO;
}

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
	%orig;

	if (!smtBool(@"enable")) {
		return;
	}

	if (smtBool(@"recording") && !isRecording()) {
		return;
	}

	if (event.type == UIEventTypeTouches) {
		NSSet *touches = [event allTouches];
		for (UITouch *touch in touches) {
			CGPoint touchPoint = [touch locationInView:nil];

			UIView *touchView = nil;
			UIWindow *keyWindow = nil;

			NSArray *windows = [UIApplication sharedApplication].windows;
			for (UIWindow *window in windows) {
				if (!window.hidden && (!keyWindow || window.windowLevel > keyWindow.windowLevel)) {
					keyWindow = window;
				}
			}

			if (touch.phase == UITouchPhaseBegan) {
				if (!touchView) {
					NSData *touchData = [[SMTUserDefaults standardUserDefaults] objectForKey:@"touchColor"];
    				UIColor *touchColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:touchData error:nil];

					NSData *borderData = [[SMTUserDefaults standardUserDefaults] objectForKey:@"borderColor"];
    				UIColor *borderColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:borderData error:nil];

					touchView = [[UIView alloc] initWithFrame:CGRectMake(touchPoint.x - 20, touchPoint.y - 20, 40, 40)];
					touchView.backgroundColor = touchColor;
					touchView.layer.cornerRadius = 20;
					touchView.layer.borderColor = borderColor.CGColor;
					touchView.layer.borderWidth = 3.0;
					touchView.clipsToBounds = YES;
					touchView.userInteractionEnabled = NO;

					dispatch_async(dispatch_get_main_queue(), ^{
						[keyWindow addSubview:touchView];
					});

					objc_setAssociatedObject(touch, @"TouchView", touchView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
				}
			}

			if (touch.phase == UITouchPhaseMoved) {
				touchView = objc_getAssociatedObject(touch, @"TouchView");
				if (touchView) {
					dispatch_async(dispatch_get_main_queue(), ^{
						touchView.center = CGPointMake(touchPoint.x, touchPoint.y);
					});
				}
			}

			if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
				touchView = objc_getAssociatedObject(touch, @"TouchView");
				if (touchView) {
					CGFloat duration = smtBool(@"accelerated") ? 0.1 : 0.3;
					[UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
						touchView.alpha = 0.0;
						touchView.transform = CGAffineTransformMakeScale(1.5, 1.5);
					} completion:^(BOOL finished) {
						[touchView removeFromSuperview];
					}];
					objc_setAssociatedObject(touch, @"TouchView", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
				}
			}
		}
	}
}
%end