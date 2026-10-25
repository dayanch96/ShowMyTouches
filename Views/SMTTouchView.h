#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMTTouchView : UIView

- (instancetype)initWithCenter:(CGPoint)center;
- (void)moveToPoint:(CGPoint)point;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
