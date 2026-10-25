#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMTManager : NSObject

@property (class, nonatomic, readonly) BOOL shouldShowTouches;

+ (void)showTouch:(UITouch *)touch;
+ (void)moveTouch:(UITouch *)touch withEvent:(UIEvent *)event;
+ (void)removeTouch:(UITouch *)touch;

@end

NS_ASSUME_NONNULL_END
