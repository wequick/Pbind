//
//  LessAdapter.m
//  Less
//
//  Created by Galen Lin on 16/9/7.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "LessAdapter.h"
#import <Less/Less.h>
#import <MBProgressHUD/MBProgressHUD.h>

@implementation LessAdapter

+ (void)load {
    [super load];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)applicationDidFinishLaunching:(NSNotification *)note {
    // 标注图宽度，用于Plist配置自动换算尺寸
    [Less setSketchWidth:1080];
    
    // Client别名
    [LSClient registerAlias:@{@"im": @"LSExampleClient"}];
    
    // 加载数据
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidStartLoad:) name:LSViewDidStartLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidFinishLoad:) name:LSViewDidFinishLoadNotification object:nil];
    // 处理数据
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientWillLoadRequest:) name:LSClientWillLoadRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientDidLoadRequest:) name:LSClientDidLoadRequestNotification object:nil];
}

+ (void)viewDidStartLoad:(NSNotification *)note {
    UIView *view = note.object;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:.8];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.textColor = [UIColor whiteColor];
    hud.label.text = @"正在加载，请稍候...";
}

+ (void)viewDidFinishLoad:(NSNotification *)note {
    UIView *view = note.object;
    LSResponse *response = note.userInfo[LSResponseKey];
    if (response.error != nil) {
        MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = [response.error localizedDescription];
        hud.label.textColor = [UIColor whiteColor];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1.f];
    } else {
        [MBProgressHUD hideHUDForView:view animated:YES];
    }
}

+ (void)clientWillLoadRequest:(NSNotification *)note {
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
    hud.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:.8];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.activityIndicatorColor = [UIColor whiteColor];
    hud.label.textColor = [UIColor whiteColor];
    hud.label.text = @"正在处理，请稍候...";
}

+ (void)clientDidLoadRequest:(NSNotification *)note {
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    LSResponse *response = note.userInfo[LSResponseKey];
    NSString *tip = note.userInfo[LSResultTipKey];
    if (response.error != nil) {
        if (tip == nil) {
            tip = [response.error localizedDescription];
        }
    }
    
    if (tip != nil) {
        MBProgressHUD *hud = [MBProgressHUD HUDForView:window];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = tip;
        hud.label.textColor = [UIColor whiteColor];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1.f];
    } else {
        [MBProgressHUD hideHUDForView:window animated:YES];
    }
}

@end
