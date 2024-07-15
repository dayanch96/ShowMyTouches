#import "NSBundle+SMTPrefs.h"

@implementation NSBundle (ShowMyTouches)

+ (NSBundle *)smt_defaultBundle {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"SMTPrefs" ofType:@"bundle"];
        NSString *rootlessBundlePath = ROOT_PATH_NS(@"/Library/Application Support/SMTPrefs.bundle");

        bundle = [NSBundle bundleWithPath:tweakBundlePath ?: rootlessBundlePath];
    });

    return bundle;
}

@end