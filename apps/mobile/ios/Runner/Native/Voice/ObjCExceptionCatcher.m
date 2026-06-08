#import "ObjCExceptionCatcher.h"

@implementation ObjCExceptionCatcher
+ (NSError * _Nullable)catchException:(void (^)(void))tryBlock {
  @try {
    tryBlock();
    return nil;
  } @catch (NSException *exception) {
    return [NSError errorWithDomain:@"com.rarocamera.voice"
                               code:0
                           userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: exception.name}];
  }
}
@end
