//
//  LoginViewController.m
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "LoginViewController.h"
#import "DataModel.h"

@interface LoginViewController()
@property (nonatomic, retain) IBOutlet UITextField* nicknameTextField;
@property (nonatomic, retain) IBOutlet UITextField* secretCodeTextField;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.nicknameTextField.text = [self.dataModel nickname];
	self.secretCodeTextField.text = [self.dataModel secretCode];
    _secretCodeTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _nicknameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    UIViewController *c = [[UIViewController alloc]init];
    [self presentViewController:c animated:NO completion:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
	if (self.nicknameTextField.text.length == 0)
		[self.nicknameTextField becomeFirstResponder];
	else
		[self.secretCodeTextField becomeFirstResponder];
}

-(void)viewDidAppear:(BOOL)animated {    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (BOOL)shouldAutorotate {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
//    CGFloat screenHeight = screenRect.size.height;
    if (screenWidth == 320) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark Actions

- (void)userDidJoin
{
	// Close the Login screen
	[self.dataModel setJoinedChat:YES];
	[self dismissViewControllerAnimated:YES completion:nil];
    //Send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userJoinedRoom" object:nil userInfo:nil];
}

- (void)postJoinRequest {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Connecting", nil);
    
    NSDictionary *params = @{@"cmd":@"join",
                             @"user_id":[_dataModel userId],
                             @"token":[_dataModel deviceToken],
                             @"name":[_dataModel nickname],
                             @"location":[[SingletonClass singleObject] myLocStr],
                             @"code":[_dataModel secretCode]};
    
    [_client postPath:ServerPostPathURL
           parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  
                  if ([self isViewLoaded]) {
                      [MBProgressHUD hideHUDForView:self.view animated:YES];
                      if([operation.response statusCode] != 200) {
                          ShowErrorAlert(NSLocalizedString(@"There was an error communicating with the server", nil));
                      } else {
                          [self userDidJoin];
                      }
                  }
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  if ([self isViewLoaded]) {
                      [MBProgressHUD hideHUDForView:self.view animated:YES];
                      
                      ShowErrorAlert([error localizedDescription]);
                  }
              }];
}

- (IBAction)loginAction
{
	if (self.nicknameTextField.text.length == 0)
	{
		ShowErrorAlert(NSLocalizedString(@"Fill in your nickname", nil));
		return;
	}

	if (self.secretCodeTextField.text.length == 0)
	{
		ShowErrorAlert(NSLocalizedString(@"Fill in a secret code", nil));
		return;
	}

	[self.dataModel setNickname:self.nicknameTextField.text];
	[self.dataModel setSecretCode:self.secretCodeTextField.text];

	// Hide the keyboard
	[self.nicknameTextField resignFirstResponder];
	[self.secretCodeTextField resignFirstResponder];

//	[self userDidJoin];
    [self postJoinRequest];
}

@end
