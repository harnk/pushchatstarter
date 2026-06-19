//
//  ProgressHUD.h
//  PushChatStarter
//
//  Created by Scott Null on 06/18/26.
//  Copyright (c) 2026 Ray Wenderlich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressHUD : UIView

+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;
+ (void)hideHUDForView:(UIView *)view animated:(BOOL)animated;

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *detailsLabel;
@property (nonatomic) CGFloat cornerRadius;

+ (void)showToast:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration;
+ (void)showToast:(NSString *)message detail:(NSString *)detail inView:(UIView *)view duration:(NSTimeInterval)duration;

@end
