#import "SMTUserDefaults.h"

@implementation SMTUserDefaults

static NSString *const kDefaultsSuiteName = @"com.dvntm.showmytouches";

+ (SMTUserDefaults *)standardUserDefaults {
    static dispatch_once_t onceToken;
    static SMTUserDefaults *defaults = nil;

    dispatch_once(&onceToken, ^{
        defaults = [[self alloc] initWithSuiteName:kDefaultsSuiteName];
        [defaults registerDefaults];
    });

    return defaults;
}

- (void)reset {
    [self removePersistentDomainForName:kDefaultsSuiteName];
}

- (void)registerDefaults {
    NSData *touchColorData = [self dataWithColor:[UIColor secondaryLabelColor]];
    NSData *borderColorData = [self dataWithColor:[UIColor grayColor]];

    [self registerDefaults:@{
        @"enabled": @YES,
        @"touchColor": touchColorData,
        @"borderColor": borderColorData,
        @"duration": @0.3,
        @"touchSize": @40,
        @"touchRadius": @20,
        @"borderWidth": @3.0
    }];
}

+ (void)resetUserDefaults {
    [[self standardUserDefaults] reset];
}

- (NSData *)dataWithColor:(UIColor *)color {
    return [NSKeyedArchiver archivedDataWithRootObject:color requiringSecureCoding:NO error:nil];
}

@end
