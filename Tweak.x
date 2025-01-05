#import <UIKit/UIKit.h>
#import "SMTPrefs/SMTUserDefaults.h"

#define kTouchViewKey @selector(ShowMyTouches_TouchView)

@interface RPScreenRecorder : NSObject
- (BOOL)isRecording;

+ (instancetype)sharedRecorder;
@end

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;

    if (!smtBool(@"enable")) {
        return;
    }

    if (smtBool(@"recording") && ![[%c(RPScreenRecorder) sharedRecorder] isRecording]) {
        return;
    }

    if (event.type == UIEventTypeTouches) {
        NSSet *touches = [event allTouches];
        for (UITouch *touch in touches) {
            CGPoint touchPoint = [touch locationInView:nil];

            UIView *touchView = nil;

            if (touch.phase == UITouchPhaseBegan) {
                if (!touchView) {
                    NSData *touchData = [[SMTUserDefaults standardUserDefaults] objectForKey:@"touchColor"];
                    UIColor *touchColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:touchData error:nil];

                    NSData *borderData = [[SMTUserDefaults standardUserDefaults] objectForKey:@"borderColor"];
                    UIColor *borderColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:borderData error:nil];

                    CGFloat size = [[SMTUserDefaults standardUserDefaults] floatForKey:@"touchSize"];
                    CGFloat cornerRadius = [[SMTUserDefaults standardUserDefaults] floatForKey:@"touchRadius"];
                    CGFloat borderWidth = [[SMTUserDefaults standardUserDefaults] floatForKey:@"borderWidth"];

                    touchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
                    touchView.center = CGPointMake(touchPoint.x, touchPoint.y);
                    touchView.backgroundColor = touchColor;
                    touchView.layer.cornerRadius = cornerRadius;
                    touchView.layer.borderColor = borderColor.CGColor;
                    touchView.layer.borderWidth = borderWidth;
                    touchView.clipsToBounds = (size / 2) <= cornerRadius;
                    touchView.userInteractionEnabled = NO;

                    if (smtBool(@"luminescence")) {
                        touchView.layer.shadowColor = borderColor.CGColor;
                        touchView.layer.shadowOpacity = 0.8;
                        touchView.layer.shadowRadius = 8.0;
                        touchView.layer.shadowOffset = CGSizeMake(0, 0);
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [touch.window addSubview:touchView];
                    });

                    objc_setAssociatedObject(touch, kTouchViewKey, touchView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }
            }

            if (touch.phase == UITouchPhaseMoved) {
                touchView = objc_getAssociatedObject(touch, kTouchViewKey);
                if (touchView) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        touchView.center = CGPointMake(touchPoint.x, touchPoint.y);

                        if (!smtBool(@"Swipetrajectory")) {
                            return;
                        }

                        NSData *touchData = [[SMTUserDefaults standardUserDefaults] objectForKey:@"touchColor"];
                        UIColor *trailColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:touchData error:nil];
                        CGFloat size = [[SMTUserDefaults standardUserDefaults] floatForKey:@"touchSize"] * 1;

                        UIView *trailView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
                        trailView.center = CGPointMake(touchPoint.x, touchPoint.y);
                        trailView.backgroundColor = trailColor;
                        trailView.layer.cornerRadius = size / 2.0;
                        trailView.userInteractionEnabled = NO;

                        trailView.layer.borderColor = touchView.layer.borderColor;
                        trailView.layer.borderWidth = touchView.layer.borderWidth;

                        if (smtBool(@"luminescence")) {
                            trailView.layer.shadowColor = touchView.layer.borderColor;
                            trailView.layer.shadowOpacity = 0.8;
                            trailView.layer.shadowRadius = 8.0;
                            trailView.layer.shadowOffset = CGSizeMake(0, 0);
                        }

                        [touch.window addSubview:trailView];

                        [UIView animateWithDuration:0.5 animations:^{
                            trailView.alpha = 0.0;
                            trailView.transform = CGAffineTransformMakeScale(0.2, 0.2);
                        } completion:^(BOOL finished) {
                            [trailView removeFromSuperview];
                        }];
                    });
                }
            }

            if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
                touchView = objc_getAssociatedObject(touch, kTouchViewKey);
                if (touchView) {
                    if (touch.tapCount > 1) {
                        [touchView removeFromSuperview];
                    } else {
                        CGFloat duration = [[SMTUserDefaults standardUserDefaults] floatForKey:@"duration"];
                        [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                            touchView.alpha = 0.0;
                            touchView.transform = CGAffineTransformMakeScale(1.5, 1.5);
                        } completion:^(BOOL finished) {
                            [touchView removeFromSuperview];
                        }];
                    }
                    objc_setAssociatedObject(touch, kTouchViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }
            }
        }
    }
}
%end