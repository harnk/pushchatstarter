//
//  NetworkService.m
//  PushChatStarter
//
//  Extracted from ShowMapViewController to centralize API networking logic.
//

#import "NetworkService.h"
#import "APIClient.h"
#import "Room.h"
#import "Message.h"
#import "defs.h"

NSString * const NetworkServiceErrorDomain = @"NetworkServiceErrorDomain";

@implementation NetworkService

+ (instancetype)sharedService {
    static NetworkService *sharedService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[NetworkService alloc] init];
    });
    return sharedService;
}

#pragma mark - Public API

- (void)findRoomWithUserId:(NSString *)userId
                  location:(NSString *)location
                  roomName:(NSString *)roomName
                completion:(NetworkServiceRoomsCompletion)completion {
    NSDictionary *params = @{@"cmd":@"find",
                             @"user_id":userId,
                             @"location":location,
                             @"text":@"Hey WhereRU?"};
    [self fetchRoomsWithParams:params roomName:roomName completion:completion];
}

- (void)getRoomWithUserId:(NSString *)userId
                 location:(NSString *)location
                 roomName:(NSString *)roomName
               completion:(NetworkServiceRoomsCompletion)completion {
    NSDictionary *params = @{@"cmd":@"getroom",
                             @"user_id":userId,
                             @"location":location,
                             @"text":@"Hey WhereRU?"};
    [self fetchRoomsWithParams:params roomName:roomName completion:completion];
}

- (void)getRoomMessagesWithUserId:(NSString *)userId
                       secretCode:(NSString *)secretCode
                        completion:(NetworkServiceMessagesCompletion)completion {
    NSDictionary *params = @{@"cmd":@"getroommessages",
                             @"user_id":userId,
                             @"location":[[SingletonClass singleObject] myLocStr],
                             @"secret_code":secretCode};
    
    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                         if (httpResponse.statusCode != 200) {
                                             NSError *error = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                  code:httpResponse.statusCode
                                                                              userInfo:@{NSLocalizedDescriptionKey: @"Server returned non-200 status"}];
                                             if (completion) completion(nil, error);
                                             return;
                                         }
                                         NSArray<Message *> *messages = [self parseMessagesFromResponse:responseObject currentUserId:userId];
                                         if (completion) completion(messages, nil);
                                     } failure:^(NSError *error) {
                                         if (completion) completion(nil, error);
                                     }];
}

- (void)leaveWithUserId:(NSString *)userId
             completion:(NetworkServiceSimpleCompletion)completion {
    NSDictionary *params = @{@"cmd":@"leave",
                             @"user_id":userId};
    
    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                         if (httpResponse.statusCode != 200) {
                                             NSError *error = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                  code:httpResponse.statusCode
                                                                              userInfo:@{NSLocalizedDescriptionKey: @"Server returned non-200 status"}];
                                             if (completion) completion(NO, error);
                                             return;
                                         }
                                         if (completion) completion(YES, nil);
                                     } failure:^(NSError *error) {
                                         if (completion) completion(NO, error);
                                     }];
}

- (void)liveUpdateWithUserId:(NSString *)userId
                    location:(NSString *)location
                  completion:(NetworkServiceLiveUpdateCompletion)completion {
    NSDictionary *params = @{@"cmd":@"liveupdate",
                             @"user_id":userId,
                             @"location":location};

    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                         NSString *responseString = [NSString stringWithUTF8String:[responseObject bytes]];
                                         if (responseString.length == 0) {
                                             if (completion) completion(nil, nil);
                                             return;
                                         }
                                         NSError *e = nil;
                                         NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                                                 options:NSJSONReadingMutableContainers
                                                                                                   error:&e];
                                         if (!jsonArray) {
                                             NSError *parseError = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                       code:NetworkServiceErrorInvalidJSON
                                                                                   userInfo:@{NSLocalizedDescriptionKey: e.localizedDescription ?: @"Invalid JSON"}];
                                             if (completion) completion(nil, parseError);
                                             return;
                                         }
                                         if (completion) completion(jsonArray, nil);
                                     } failure:^(NSError *error) {
                                         if (completion) completion(nil, error);
                                     }];
}

- (void)blockUserWithUserId:(NSString *)userId
            blockedUserId:(NSString *)blockedUserId
         blockedNickname:(NSString *)blockedNickname
                completion:(NetworkServiceSimpleCompletion)completion {
    NSDictionary *params = @{@"cmd":@"block",
                             @"user_id":userId,
                             @"blocked_user_id":blockedUserId,
                             @"blocked_nickname":blockedNickname ?: @""};

    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                         if (httpResponse.statusCode != 200) {
                                             NSError *error = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                  code:httpResponse.statusCode
                                                                              userInfo:@{NSLocalizedDescriptionKey: @"Server returned non-200 status"}];
                                             if (completion) completion(NO, error);
                                             return;
                                         }
                                         if (completion) completion(YES, nil);
                                     } failure:^(NSError *error) {
                                         if (completion) completion(NO, error);
                                     }];
}

- (void)unblockUserWithUserId:(NSString *)userId
              blockedUserId:(NSString *)blockedUserId
                  completion:(NetworkServiceSimpleCompletion)completion {
    NSDictionary *params = @{@"cmd":@"unblock",
                             @"user_id":userId,
                             @"blocked_user_id":blockedUserId};

    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                         if (httpResponse.statusCode != 200) {
                                             NSError *error = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                  code:httpResponse.statusCode
                                                                              userInfo:@{NSLocalizedDescriptionKey: @"Server returned non-200 status"}];
                                             if (completion) completion(NO, error);
                                             return;
                                         }
                                         if (completion) completion(YES, nil);
                                     } failure:^(NSError *error) {
                                         if (completion) completion(NO, error);
                                     }];
}

- (void)getBlockedUsersWithUserId:(NSString *)userId
                       completion:(void (^)(NSArray<NSDictionary *> *blockedUsers, NSError *error))completion {
    NSDictionary *params = @{@"cmd":@"getblocked",
                             @"user_id":userId};

    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                         if (httpResponse.statusCode != 200) {
                                             NSError *error = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                  code:httpResponse.statusCode
                                                                              userInfo:@{NSLocalizedDescriptionKey: @"Server returned non-200 status"}];
                                             if (completion) completion(nil, error);
                                             return;
                                         }

                                         NSError *e = nil;
                                         NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                                         options:NSJSONReadingMutableContainers
                                                                                           error:&e];
                                         if (!jsonArray) {
                                             NSError *parseError = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                       code:NetworkServiceErrorInvalidJSON
                                                                                   userInfo:@{NSLocalizedDescriptionKey: e.localizedDescription ?: @"Invalid JSON"}];
                                             if (completion) completion(nil, parseError);
                                             return;
                                         }

                                         if (completion) completion(jsonArray, nil);
                                     } failure:^(NSError *error) {
                                         if (completion) completion(nil, error);
                                     }];
}

#pragma mark - Private Helpers

- (void)fetchRoomsWithParams:(NSDictionary *)params
                    roomName:(NSString *)roomName
                  completion:(NetworkServiceRoomsCompletion)completion {
    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                         if (httpResponse.statusCode != 200) {
                                             NSError *error = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                  code:httpResponse.statusCode
                                                                              userInfo:@{NSLocalizedDescriptionKey: @"Could not send the message to the server"}];
                                             if (completion) completion(nil, error);
                                             return;
                                         }
                                         
                                         NSString *responseString = [NSString stringWithUTF8String:[responseObject bytes]];
                                         
                                         if (responseString.length == 0) {
                                             NSError *error = [NSError errorWithDomain:NetworkServiceErrorDomain
                                                                                  code:NetworkServiceErrorEmptyResponse
                                                                              userInfo:@{NSLocalizedDescriptionKey: @"Empty response from server"}];
                                             if (completion) completion(nil, error);
                                             return;
                                         }
                                         
                                         NSArray<Room *> *rooms = [self parseRoomsFromResponse:responseObject roomName:roomName];
                                         if (completion) completion(rooms, nil);
                                         
                                     } failure:^(NSError *error) {
                                         if (completion) completion(nil, error);
                                     }];
}

- (NSArray<Room *> *)parseRoomsFromResponse:(NSData *)responseObject
                                   roomName:(NSString *)roomName {
    NSMutableArray<Room *> *rooms = [[NSMutableArray alloc] init];
    NSError *e = nil;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject
                                                        options:NSJSONReadingMutableContainers
                                                          error:&e];
    if (!jsonArray) {
        NSLog(@"NetworkService Error parsing JSON: %@", e);
        return rooms;
    }

    NSString *myPinImages[11] = {@"blue.png", @"cyan.png", @"darkgreen.png", @"gold.png",
        @"green.png", @"orange.png", @"pink.png", @"purple.png", @"red.png", @"yellow.png",
        @"cyangray.png"};

    int i = 0;
    for (NSDictionary *item in jsonArray) {
        if (i > 10) { i = 0; }
        NSString *mUserId = [item objectForKey:@"user_id"];
        NSString *mNickName = [item objectForKey:@"nickname"];
        NSString *mLocation = [item objectForKey:@"location"];
        NSString *gmtDateStr = [item objectForKey:@"loc_time"];
        NSString *useThisPinImage = myPinImages[i];

        if (![mLocation isEqual:@"0.000000, 0.000000"]) {
            Room *roomObj = [[Room alloc] initWithRoomName:roomName
                                         andMemberUserId:mUserId
                                        andMemberNickName:mNickName
                                        andMemberLocation:mLocation
                                        andMemberLocTime:gmtDateStr
                                       andMemberPinImage:useThisPinImage];
            [rooms addObject:roomObj];
        }
        i++;
    }

    return rooms;
}

- (NSArray<Message *> *)parseMessagesFromResponse:(NSData *)responseObject
                                   currentUserId:(NSString *)currentUserId {
    NSMutableArray<Message *> *messages = [[NSMutableArray alloc] init];
    NSError *e = nil;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject
                                                        options:NSJSONReadingMutableContainers
                                                          error:&e];
    if (!jsonArray) {
        NSLog(@"NetworkService Error parsing messages JSON: %@", e);
        return messages;
    }
    
    for (NSDictionary *item in jsonArray) {
        Message *message = [[Message alloc] init];
        if ([currentUserId isEqualToString:[item objectForKey:@"user_id"]]) {
            message.senderName = nil;
        } else {
            message.senderName = [item objectForKey:@"nickname"];
        }
        // Parse the date from UTC string
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        message.date = [formatter dateFromString:[item objectForKey:@"time_posted"]];
        message.location = [item objectForKey:@"location"];
        message.text = [item objectForKey:@"message"];
        [messages addObject:message];
    }
    
    return messages;
}

@end
