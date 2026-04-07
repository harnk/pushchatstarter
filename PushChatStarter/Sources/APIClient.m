//
//  APIClient.m
//  PushChatStarter
//
//  Created by Scott Null on 04/06/26.
//  Copyright (c) 2026 Ray Wenderlich. All rights reserved.
//

#import "APIClient.h"
#import "defs.h"
#import <AFNetworking/AFNetworking.h>

@interface APIClient ()
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
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
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:ServerApiURL]];
        self.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return self;
}

- (void)postToEndpoint:(NSString *)endpoint
            parameters:(NSDictionary *)params
               success:(APISuccessBlock)success
               failure:(APIFailureBlock)failure {
    
    // Debug log: show full POST URL and params
    NSLog(@"🌐 API POST %@%@ params:%@", ServerApiURL, endpoint, params);
    
    [self.sessionManager POST:endpoint
                   parameters:params
                      headers:nil
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
                          NSLog(@"✅ API Response Status: %ld", (long)httpResp.statusCode);
                          
                          if (success) {
                              success(responseObject, httpResp);
                          }
                      } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          NSLog(@"❌ API Error: %@", error.localizedDescription);
                          
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)getFromEndpoint:(NSString *)endpoint
             parameters:(NSDictionary *)params
                success:(APISuccessBlock)success
                failure:(APIFailureBlock)failure {
    
    // Debug log: show full GET URL and params
    NSLog(@"🌐 API GET %@%@ params:%@", ServerApiURL, endpoint, params);
    
    [self.sessionManager GET:endpoint
                  parameters:params
                     headers:nil
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)task.response;
                         NSLog(@"✅ API Response Status: %ld", (long)httpResp.statusCode);
                         
                         if (success) {
                             success(responseObject, httpResp);
                         }
                     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         NSLog(@"❌ API Error: %@", error.localizedDescription);
                         
                         if (failure) {
                             failure(error);
                         }
                     }];
}

@end
