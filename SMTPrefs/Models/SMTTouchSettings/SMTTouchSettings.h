#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMTTouchSettings : NSObject

@property (class, nonatomic, readonly) CGFloat followRate;
@property (class, nonatomic, readonly) CGFloat maxTail;
@property (class, nonatomic, readonly) CGFloat minBendRadius;
@property (class, nonatomic, readonly) CGFloat tailThinning;
@property (class, nonatomic, readonly) CGFloat headThinning;
@property (class, nonatomic, readonly) CGFloat blend;
@property (class, nonatomic, readonly) CGFloat gridStep;

@property (class, nonatomic, readonly) CGFloat breathScale;
@property (class, nonatomic, readonly) CFTimeInterval breathDuration;
@property (class, nonatomic, readonly) CFTimeInterval breathIdleDelay;
@property (class, nonatomic, readonly) CFTimeInterval breathSettleDuration;
@property (class, nonatomic, readonly) CGFloat restTolerance;

@property (class, nonatomic, readonly) CFTimeInterval trailLifetime;
@property (class, nonatomic, readonly) CGFloat trailWidth;
@property (class, nonatomic, readonly) CGFloat trailSpacing;

@property (class, nonatomic, readonly) CGFloat releaseScale;

#if SIDELOADING
@property (class, nonatomic, readonly) CFTimeInterval settingsTapDuration;
@property (class, nonatomic, readonly) CFTimeInterval settingsDoubleTapInterval;
@property (class, nonatomic, readonly) CFTimeInterval settingsHoldDuration;
@property (class, nonatomic, readonly) CGFloat settingsGestureTolerance;
#endif

@end

NS_ASSUME_NONNULL_END
