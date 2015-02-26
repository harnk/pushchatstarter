//
//  ServiceConnector.h
//  PushChatStarter
//
//  Created by Scott Null on 2/22/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServiceConnectorDelegate <NSObject>
-(void)requestReturnedData:(NSData*)data;
@end

@interface ServiceConnector : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (strong,nonatomic) id <ServiceConnectorDelegate> delegate;

-(void)getTest;
-(void)postTest;

@end
