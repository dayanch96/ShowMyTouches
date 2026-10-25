#import <SMTTouchSettings/SMTTouchSettings.h>

@implementation SMTTouchSettings

#pragma mark - Morph settings

+ (CGFloat)followRate {
    return 40.0;
}

+ (CGFloat)maxTail {
    return 0.5;
}

+ (CGFloat)minBendRadius {
    return 0.8;
}

+ (CGFloat)tailThinning {
    return 0.25;
}

+ (CGFloat)headThinning {
    return 0.06;
}

+ (CGFloat)blend {
    return 0.25;
}

+ (CGFloat)gridStep {
    return 1.0;
}

#pragma mark - Idle breathing settings

+ (CGFloat)breathScale {
    return 1.07;
}

+ (CFTimeInterval)breathDuration {
    return 0.9;
}

+ (CFTimeInterval)breathIdleDelay {
    return 0.35;
}

+ (CFTimeInterval)breathSettleDuration {
    return 0.2;
}

+ (CGFloat)restTolerance {
    return 1.5;
}

#pragma mark - Comet settings

+ (CFTimeInterval)trailLifetime {
    return 0.3;
}

+ (CGFloat)trailWidth {
    return 0.75;
}

+ (CGFloat)trailSpacing {
    return 1.5;
}

#pragma mark - Release settings

+ (CGFloat)releaseScale {
    return 1.5;
}

#if SIDELOADING
#pragma mark - Settings gestures settings

+ (CFTimeInterval)settingsTapDuration {
    return 0.35;
}

+ (CFTimeInterval)settingsDoubleTapInterval {
    return 0.4;
}

+ (CFTimeInterval)settingsHoldDuration {
    return 0.8;
}

+ (CGFloat)settingsGestureTolerance {
    return 20.0;
}
#endif

@end
