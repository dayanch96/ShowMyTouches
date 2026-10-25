#import "NSString+SMTPrefs.h"
#import <NSBundle+SMTPrefs/NSBundle+SMTPrefs.h>

@implementation NSString (SMTPrefs)

- (NSString *)smt_localized {
    NSString *localizedString = [NSBundle.smt_defaultBundle localizedStringForKey:self value:nil table:nil];
    return (localizedString.length) ? localizedString : self;
}

@end
