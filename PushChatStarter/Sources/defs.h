
// Maximum number of bytes that a text message may have. The payload data of
// a push notification is limited to 256 bytes and that includes the JSON 
// overhead and the name of the sender.
#define MaxMessageLength 190
//#define MaxMessageLength 158

// for local testing use the next line
//#define ServerApiURL @"http://10.0.0.27:44447"
// for the real deal on bluehost use the next line
#define ServerApiURL @"https://www.altcoinfolio.com"

//Test
//#define ServerPostPathURL @"/whereru/api/api.php"
//Prod
#define ServerPostPathURL @"/whereruprod/api/api.php"

#define IS_IPHONE5 (([[UIScreen mainScreen] bounds].size.height-568)?NO:YES)
#define IS_OS_9_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)

// Convenience function to show a UIAlertView
void ShowErrorAlert(NSString* text);

#define kAlertViewHarpy 1
#define kAlertViewSignOut 2
#define kAlertViewNotifications 3
