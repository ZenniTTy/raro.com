#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjCExceptionCatcher : NSObject
+ (NSError * _Nullable)catchException:(void (^)(void))tryBlock;
@end

NS_ASSUME_NONNULL_END
