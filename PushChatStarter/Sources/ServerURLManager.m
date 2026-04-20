#import "ServerURLManager.h"
#import "defs.h"

// Global variable to hold the server URL (defined here, declared extern in defs.h)
NSString *gServerApiURL = nil;

@implementation ServerURLManager

+ (void)initializeServerURL:(void (^)(BOOL success))completion {
    // Clear any cached response for this URL to ensure we get fresh content
    NSURL *configURL = [NSURL URLWithString:FetchServerApiURL];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[NSURLRequest requestWithURL:configURL]];
    NSURLRequest *request = [NSURLRequest requestWithURL:configURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"❌ Failed to fetch server URL: %@", error.localizedDescription);
            completion(NO);
            return;
        }
        
        NSString *urlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (urlString && urlString.length > 0 && ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"])) {
            gServerApiURL = urlString;
            NSLog(@"✅ Server URL initialized: %@", gServerApiURL);
            completion(YES);
        } else {
            NSLog(@"❌ Invalid server URL from config: %@", urlString);
            completion(NO);
        }
    }];
    
    [task resume];
}

+ (NSString *)serverURL {
    return gServerApiURL;
}

@end
