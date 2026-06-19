//
//  ProgressHUD.m
//  PushChatStarter
//
//  Created by Scott Null on 06/18/26.
//  Copyright (c) 2026 Ray Wenderlich. All rights reserved.
//

#import "ProgressHUD.h"

@interface ProgressHUD ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) UIView *parentView;
@end

@implementation ProgressHUD

+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated {
    ProgressHUD *hud = [[ProgressHUD alloc] initWithFrame:view.bounds];
    hud.parentView = view;
    hud.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    hud.layer.cornerRadius = 10;
    hud.clipsToBounds = YES;
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    [hud addSubview:indicator];
    hud.activityIndicator = indicator;
    
    hud.label = [[UILabel alloc] init];
    hud.label.textColor = [UIColor whiteColor];
    hud.label.font = [UIFont boldSystemFontOfSize:16];
    hud.label.textAlignment = NSTextAlignmentCenter;
    hud.label.translatesAutoresizingMaskIntoConstraints = NO;
    [hud addSubview:hud.label];
    
    [NSLayoutConstraint activateConstraints:@[
        [indicator.centerXAnchor constraintEqualToAnchor:hud.centerXAnchor],
        [indicator.centerYAnchor constraintEqualToAnchor:hud.centerYAnchor constant:-20],
        [hud.label.leadingAnchor constraintEqualToAnchor:hud.leadingAnchor constant:20],
        [hud.label.trailingAnchor constraintEqualToAnchor:hud.trailingAnchor constant:-20],
        [hud.label.topAnchor constraintEqualToAnchor:indicator.bottomAnchor constant:15],
        [hud.label.heightAnchor constraintGreaterThanOrEqualToConstant:20]
    ]];
    
    [view addSubview:hud];
    hud.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [hud.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [hud.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
        [hud.widthAnchor constraintEqualToConstant:120],
        [hud.heightAnchor constraintEqualToConstant:120]
    ]];
    
    [indicator startAnimating];
    
    if (animated) {
        hud.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            hud.alpha = 1;
        }];
    }
    
    return hud;
}

- (void)hideAnimated:(BOOL)animated {
    void (^hideBlock)(void) = ^{
        [self.activityIndicator stopAnimating];
        [self removeFromSuperview];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            hideBlock();
        }];
    } else {
        hideBlock();
    }
}

+ (void)hideHUDForView:(UIView *)view animated:(BOOL)animated {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[ProgressHUD class]]) {
            [(ProgressHUD *)subview hideAnimated:animated];
        }
    }
}

+ (void)showToast:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration {
    [self showToast:message detail:nil inView:view duration:duration];
}

+ (void)showToast:(NSString *)message detail:(NSString *)detail inView:(UIView *)view duration:(NSTimeInterval)duration {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:message message:detail preferredStyle:UIAlertControllerStyleAlert];
    [view.window.rootViewController presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

@end
