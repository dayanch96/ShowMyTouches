#import <UIKit/UIKit.h>

#define smtBool(key) [[SMTUserDefaults standardUserDefaults] boolForKey:key]

NS_ASSUME_NONNULL_BEGIN

@interface SMTUserDefaults : NSUserDefaults 

@property (class, readonly, strong) SMTUserDefaults *standardUserDefaults;

- (void)reset;
+ (void)resetUserDefaults;

@end

NS_ASSUME_NONNULL_END
