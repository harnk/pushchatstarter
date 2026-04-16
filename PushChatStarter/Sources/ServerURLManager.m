#import "ServerURLManager.h"
#import "defs.h"

// Global variable to hold the server URL (defined here, declared extern in defs.h)
NSString *gServerApiURL = @"https://began-possibilities-stable-ids.trycloudflare.com";

@implementation ServerURLManager

+ (void)initializeServerURL:(void (^)(BOOL success))completion {
    // Fetch the server URL from the gist
    NSURL *configURL = [NSURL URLWithString:FetchServerApiURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:configURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    
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
