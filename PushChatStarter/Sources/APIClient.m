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
#import <AFNetworking/AFNetworking.h>

extern NSString *gServerApiURL;

@interface APIClient ()
@property (nonatomic, strong, readwrite) AFHTTPSessionManager *sessionManager;
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
        // Get the server URL that was initialized on app launch
        NSString *serverURL = gServerApiURL;
        if (serverURL) {
            NSURL *baseURL = [NSURL URLWithString:serverURL];
            self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
            self.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            NSLog(@"✅ APIClient initialized with server URL: %@", serverURL);
        } else {
            NSLog(@"⚠️ Server URL not yet initialized");
        }
    }
    return self;
}

- (void)postToEndpoint:(NSString *)endpoint
            parameters:(NSDictionary *)params
               success:(APISuccessBlock)success
               failure:(APIFailureBlock)failure {
    
    NSLog(@"🌐 POST %@%@ params:%@", self.sessionManager.baseURL.absoluteString, endpoint, params);
    
    [self.sessionManager POST:endpoint
                   parameters:params
                      headers:nil
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
                          NSLog(@"✅ Response Status: %ld", (long)httpResp.statusCode);
                          if (success) success(responseObject, httpResp);
                      } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          NSLog(@"❌ Error: %@", error.localizedDescription);
                          if (failure) failure(error);
                      }];
}

- (void)getFromEndpoint:(NSString *)endpoint
             parameters:(NSDictionary *)params
                success:(APISuccessBlock)success
                failure:(APIFailureBlock)failure {
    
    NSLog(@"🌐 GET %@%@ params:%@", self.sessionManager.baseURL.absoluteString, endpoint, params);
    
    [self.sessionManager GET:endpoint
                  parameters:params
                     headers:nil
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
                         NSLog(@"✅ Response Status: %ld", (long)httpResp.statusCode);
                         if (success) success(responseObject, httpResp);
                     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         NSLog(@"❌ Error: %@", error.localizedDescription);
                         if (failure) failure(error);
                     }];
}

@end
