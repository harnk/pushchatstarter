//
//  APIClient.h
//  PushChatStarter
//
//  Created by Scott Null on 04/06/26.
//  Copyright (c) 2026 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^APISuccessBlock)(id responseObject, NSHTTPURLResponse *httpResponse);
typedef void (^APIFailureBlock)(NSError *error);

@interface APIClient : NSObject

+ (instancetype)sharedClient;

/**
 * Make a POST request to the server API
 * @param endpoint The API endpoint path (e.g., @"/api.php")
 * @param params Dictionary of parameters to send
 * @param success Success callback block with response object and HTTP response
 * @param failure Failure callback block with error
 */
- (void)postToEndpoint:(NSString *)endpoint
            parameters:(NSDictionary *)params
               success:(APISuccessBlock)success
               failure:(APIFailureBlock)failure;

/**
 * Make a GET request to the server API
 * @param endpoint The API endpoint path
 * @param params Dictionary of query parameters
 * @param success Success callback block
 * @param failure Failure callback block
 */
- (void)getFromEndpoint:(NSString *)endpoint
             parameters:(NSDictionary *)params
                success:(APISuccessBlock)success
                failure:(APIFailureBlock)failure;

@end
