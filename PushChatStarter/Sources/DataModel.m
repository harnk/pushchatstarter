//
//  DataModel.m
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "DataModel.h"
#import "Message.h"
#import <Security/Security.h>

// We store our settings in the NSUserDefaults dictionary using these keys
static NSString* const NicknameKey = @"Nickname";
static NSString* const SecretCodeKey = @"SecretCode";
static NSString* const JoinedChatKey = @"JoinedChat";
static NSString * const UserId = @"UserId";
static NSString * const DeviceTokenKey = @"DeviceToken";

@implementation DataModel

@synthesize messages;

- (NSString*)deviceToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:DeviceTokenKey];
}

- (void)setDeviceToken:(NSString*)token
{
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:DeviceTokenKey];
}

+ (void)initialize
{
	if (self == [DataModel class])
    {
        // Register default values for our settings
        [[NSUserDefaults standardUserDefaults] registerDefaults:
         @{NicknameKey: @"",
           SecretCodeKey: @"",
           JoinedChatKey: @0,
           
           //ADD THESE LINE
           DeviceTokenKey: @"0",
           UserId:@""}];
    }
}

// Returns the path to the Messages.plist file in the app's Documents directory
- (NSString*)messagesPath
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = paths[0];
	return [documentsDirectory stringByAppendingPathComponent:@"Messages.plist"];
}

// Loads the messages from the API call
- (void)loadRoomMessages:(NSMutableArray*)roomMessages {

    
}

- (void)loadMessages:(NSString*)myLoc
{
//    NSString* path = [self messagesPath];
//    NSLog(@"loadMessages - messagesPath: %@", path);
    NSString *checkStartingLoc = [[SingletonClass singleObject] myLocStr];
    if (nil == checkStartingLoc) {
        CLLocation *startingPoint = [[CLLocation alloc] initWithLatitude:40.689124 longitude:-74.044611];
        [[SingletonClass singleObject] setMyNewLocation:startingPoint];
        CLLocation *newLoc = startingPoint;
        [[SingletonClass singleObject] setMyLocStr: [NSString stringWithFormat:@"%f, %f", newLoc.coordinate.latitude, newLoc.coordinate.longitude]];
    }
//    NSLog(@"myLoc: %@", [[SingletonClass singleObject] myLocStr]);
    
    _myLoc = myLoc;
    
    self.messages = [NSMutableArray arrayWithCapacity:20];
}

- (void)saveMessages
{
	NSMutableData* data = [[NSMutableData alloc] init];
	NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:self.messages forKey:@"Messages"];
	[archiver finishEncoding];
	[data writeToFile:[self messagesPath] atomically:YES];
}

- (int)addMessage:(Message*)message
{
	[self.messages addObject:message];
    // SCXTT COMMENTING THIS NEXT LINE CUTS AWAY FROM STORING ON DEVICE
    //	[self saveMessages];

	return (int)self.messages.count - 1;
}

- (NSString*)nickname
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:NicknameKey];
}

- (void)setNickname:(NSString*)name
{
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:NicknameKey];
}

- (NSString*)secretCode
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:SecretCodeKey];
}

- (void)setSecretCode:(NSString*)string
{
	[[NSUserDefaults standardUserDefaults] setObject:string forKey:SecretCodeKey];
}

- (BOOL)joinedChat
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:JoinedChatKey];
}

- (void)setJoinedChat:(BOOL)value
{
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:JoinedChatKey];
}

// for these next two methods reference this http://useyourloaf.com/blog/simple-iphone-keychain-access/

static NSString *serviceName = @"com.harnk.whereru.myAppServiceName";

- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    [searchDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(id)kSecAttrAccount];
    [searchDictionary setObject:serviceName forKey:(id)kSecAttrService];
    
    return searchDictionary;
}

- (CFDataRef *)searchKeychainCopyMatching:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    
    // Add search attributes
    [searchDictionary setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    
    // Add search return types
    [searchDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    
    CFDataRef *result = nil;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)searchDictionary, (CFTypeRef *)&result);
    
//    [searchDictionary release];
    return result;
}

- (NSString*)userId
{
    
    CFDataRef *passwordData = [self searchKeychainCopyMatching:@"Password"];
    if (passwordData) {
        NSData *myData = (__bridge_transfer NSData *)passwordData;
        NSString *password = [[NSString alloc] initWithData:passwordData
                                                   encoding:NSUTF8StringEncoding];
        [passwordData release];
    }
    
    
//    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:UserId];
    NSString *userId = [_keychain objectForKey:(__bridge id)(kSecAttrAccount)];
    NSLog(@"GETTING userId from keychain:%@", userId);
    
    if (userId == nil || userId.length == 0) {
        NSLog(@"USERID IS NULL userId from keychain:%@", userId);

        userId = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSLog(@"USERID IS NEW userId:%@", userId);
        
        // LETS STORE THIS IN THE KEYCHAIN INSTEAD OF NSUserDefaults
        _keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"WhereRU" accessGroup:nil];
        [_keychain setObject:userId forKey:(__bridge id)(kSecAttrAccount)];
        NSLog(@"USERID IS STORED in _keychain:%@", userId);
        userId = [_keychain objectForKey:(__bridge id)(kSecAttrAccount)];
        NSLog(@"USERID READBACK from Keychain:%@", userId);
        
//        [[NSUserDefaults standardUserDefaults] setObject:userId forKey:UserId];
    }
    return userId;
}

@end
