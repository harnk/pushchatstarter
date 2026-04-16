#import <Foundation/Foundation.h>

@interface ServerURLManager : NSObject

+ (void)initializeServerURL:(void (^)(BOOL success))completion;
+ (NSString *)serverURL;

@end
