//
//  APIClient.m
//  PushChatStarter
//
//  Created by Scott Null on 04/06/26.
//  Copyright (c) 2026 Ray Wenderlich. All rights reserved.
//

#import "APIClient.h"
#import "defs.h"
#import "ServerURLManager.h"

extern NSString *gServerApiURL;

@interface APIClient ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation APIClient

+ (instancetype)sharedClient {
    static APIClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[APIClient alloc] init];
    });
    return sharedClient;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupSession];
    }
    return self;
}

- (void)setupSession {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30.0;
    config.HTTPShouldSetCookies = NO;
    
    self.session = [NSURLSession sessionWithConfiguration:config];
}

- (NSURL *)baseURL {
    NSString *serverURL = gServerApiURL;
    if (!serverURL) {
        NSLog(@"⚠️ Server URL not initialized");
        return nil;
    }
    return [NSURL URLWithString:serverURL];
}

- (NSString *)urlEncode:(id)object {
    NSString *string = [object description];
    NSCharacterSet *allowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"] invertedSet];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedChars];
}

#pragma mark - Public Methods

- (void)postToEndpoint:(NSString *)endpoint
            parameters:(NSDictionary *)params
               success:(APISuccessBlock)success
               failure:(APIFailureBlock)failure {
    
    NSURL *base = [self baseURL];
    if (!base) {
        if (failure) failure([NSError errorWithDomain:@"APIClient" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Server URL not set"}]);
        return;
    }
    
    NSURL *url = [base URLByAppendingPathComponent:endpoint];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    if (params) {
        NSMutableArray *queryItems = [NSMutableArray array];
        [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [queryItems addObject:[NSString stringWithFormat:@"%@=%@", key, [self urlEncode:obj]]];
        }];
        NSString *bodyString = [queryItems componentsJoinedByString:@"&"];
        request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSLog(@"🌐 POST %@ params: %@", url.absoluteString, params);
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"❌ POST Error: %@", error.localizedDescription);
                if (failure) failure(error);
                return;
            }
            
            NSLog(@"✅ Response Status: %ld", (long)httpResponse.statusCode);
            
            if (success) {
                success(data, httpResponse);
            }
        });
    }];
    
    [task resume];
}

- (void)getFromEndpoint:(NSString *)endpoint
             parameters:(NSDictionary *)params
                success:(APISuccessBlock)success
                failure:(APIFailureBlock)failure {
    
    NSURL *base = [self baseURL];
    if (!base) {
        if (failure) failure([NSError errorWithDomain:@"APIClient" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Server URL not set"}]);
        return;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:[base URLByAppendingPathComponent:endpoint] resolvingAgainstBaseURL:YES];
    
    if (params.count > 0) {
        NSMutableArray *queryItems = [NSMutableArray array];
        [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:[obj description]]];
        }];
        components.queryItems = queryItems;
    }
    
    NSURL *url = components.URL;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSLog(@"🌐 GET %@", url.absoluteString);
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"❌ GET Error: %@", error.localizedDescription);
                if (failure) failure(error);
                return;
            }
            
            NSLog(@"✅ Response Status: %ld", (long)httpResponse.statusCode);
            
            if (success) {
                success(data, httpResponse);
            }
        });
    }];
    
    [task resume];
}

@end