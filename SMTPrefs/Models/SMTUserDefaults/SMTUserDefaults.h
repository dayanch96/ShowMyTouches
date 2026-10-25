#import <UIKit/UIKit.h>

#define smtBool(key) [[SMTUserDefaults standardUserDefaults] boolForKey:key]

// Largest touch is 60 pt, at @3x that's 180 px; anything bigger is never shown
#define kSMTTouchImageMaxPixels 180

NS_ASSUME_NONNULL_BEGIN

@interface SMTUserDefaults : NSUserDefaults

@property (class, readonly, strong) SMTUserDefaults *standardUserDefaults;

@property (nonatomic, readonly, getter=isEnabled) BOOL enabled;
@property (nonatomic, readonly) BOOL onlyWhileRecording;
@property (nonatomic, readonly, getter=isMorphEnabled) BOOL morphEnabled;
@property (nonatomic, readonly, getter=isCometEnabled) BOOL cometEnabled;
@property (nonatomic, readonly, getter=isImageEnabled) BOOL imageEnabled;

#if SIDELOADING
@property (class, nonatomic, readonly) NSArray<NSString *> *openSettingsKeys;
@property (nonatomic, readonly) BOOL fourFingerTapOpensSettings;
@property (nonatomic, readonly) BOOL threeFingerHoldOpensSettings;
@property (nonatomic, readonly) BOOL shakeOpensSettings;
#endif

@property (nonatomic, strong, nullable) UIImage *touchImage;

@property (nonatomic, readonly, nullable) UIColor *touchColor;
@property (nonatomic, readonly, nullable) UIColor *borderColor;

@property (nonatomic, readonly) CGFloat touchSize;
@property (nonatomic, readonly) CGFloat touchRadius;
@property (nonatomic, readonly) CGFloat borderWidth;
@property (nonatomic, readonly) CGFloat duration;

- (nullable UIColor *)colorForKey:(NSString *)key;
- (void)setColor:(UIColor *)color forKey:(NSString *)key;

- (void)reset;
+ (void)resetUserDefaults;

@end

NS_ASSUME_NONNULL_END
