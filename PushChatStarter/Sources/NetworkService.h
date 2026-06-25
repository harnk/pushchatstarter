//
//  NetworkService.h
//  PushChatStarter
//
//  Extracted from ShowMapViewController to centralize API networking logic.
//

#import <Foundation/Foundation.h>

@class Room;
@class Message;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const NetworkServiceErrorDomain;

typedef NS_ENUM(NSUInteger, NetworkServiceErrorCode) {
    NetworkServiceErrorEmptyResponse = 1,
    NetworkServiceErrorInvalidJSON = 2,
};

typedef void (^NetworkServiceRoomsCompletion)(NSArray<Room *> * _Nullable rooms, NSError * _Nullable error);
typedef void (^NetworkServiceMessagesCompletion)(NSArray<Message *> * _Nullable messages, NSError * _Nullable error);
typedef void (^NetworkServiceSimpleCompletion)(BOOL success, NSError * _Nullable error);
typedef void (^NetworkServiceLiveUpdateCompletion)(NSArray * _Nullable jsonArray, NSError * _Nullable error);

@interface NetworkService : NSObject

+ (instancetype)sharedService;

// Find devices in a room (cmd: "find")
- (void)findRoomWithUserId:(NSString *)userId
                  location:(NSString *)location
                  roomName:(NSString *)roomName
                completion:(NetworkServiceRoomsCompletion)completion;

// Get room data (cmd: "getroom")
- (void)getRoomWithUserId:(NSString *)userId
                 location:(NSString *)location
                 roomName:(NSString *)roomName
               completion:(NetworkServiceRoomsCompletion)completion;

// Get messages for a room (cmd: "getroommessages")
- (void)getRoomMessagesWithUserId:(NSString *)userId
                       secretCode:(NSString *)secretCode
                        completion:(NetworkServiceMessagesCompletion)completion;

// Leave a room (cmd: "leave")
- (void)leaveWithUserId:(NSString *)userId
             completion:(NetworkServiceSimpleCompletion)completion;

// Live update - set looking status (cmd: "liveupdate")
- (void)liveUpdateWithUserId:(NSString *)userId
                    location:(NSString *)location
                  completion:(NetworkServiceLiveUpdateCompletion)completion;

// Block a user (cmd: "block")
- (void)blockUserWithUserId:(NSString *)userId
            blockedUserId:(NSString *)blockedUserId
                completion:(NetworkServiceSimpleCompletion)completion;

// Unblock a user (cmd: "unblock")
- (void)unblockUserWithUserId:(NSString *)userId
              blockedUserId:(NSString *)blockedUserId
                  completion:(NetworkServiceSimpleCompletion)completion;

// Get list of blocked users (cmd: "getblocked")
- (void)getBlockedUsersWithUserId:(NSString *)userId
                       completion:(void (^)(NSArray<NSString *> *blockedUserIds, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
