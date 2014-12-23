
// Maximum number of bytes that a text message may have. The payload data of
// a push notification is limited to 256 bytes and that includes the JSON 
// overhead and the name of the sender.
#define MaxMessageLength 190

// for local testing use the next line
//#define ServerApiURL @"http://10.0.0.27:44447"
// for the real deal on bluehost use the next line
#define ServerApiURL @"http://www.altcoinfolio.com"

// Convenience function to show a UIAlertView
void ShowErrorAlert(NSString* text);
