#import <Foundation/Foundation.h>

@interface RPScreenRecorder : NSObject

- (BOOL)isRecording;

+ (instancetype)sharedRecorder;

@end
