//
//  PbindAdapter.m
//  Pbind
//
//  Created by Galen Lin on 16/9/7.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "PbindAdapter.h"
#import <Pbind/Pbind.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "MyStyle.h"

@implementation PbindAdapter

+ (void)load {
    [super load];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)applicationDidFinishLaunching:(NSNotification *)note {
    // 变量映射
    [PBVariableMapper registerTag:'S' withMapper:^id(id data, id target, UIView *context) {
        return [MyStyle defaultStyle];
    }];
    
    // MBProgressHUD
    [[UIActivityIndicatorView appearanceWhenContainedIn:[MBProgressHUD class], nil] setColor:[UIColor whiteColor]];
    
    // 加载数据
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidStartLoad:) name:PBViewDidStartLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidFinishLoad:) name:PBViewDidFinishLoadNotification object:nil];
    // 处理数据
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientWillLoadRequest:) name:PBClientWillLoadRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientDidLoadRequest:) name:PBClientDidLoadRequestNotification object:nil];
}

+ (void)viewDidStartLoad:(NSNotification *)note {
    UIView *view = note.object;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:.8f];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.textColor = [UIColor whiteColor];
    hud.label.text = @"正在加载，请稍候...";
}

+ (void)viewDidFinishLoad:(NSNotification *)note {
    UIView *view = note.object;
    PBResponse *response = note.userInfo[PBResponseKey];
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
    hud.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:.8f];
    hud.mode = MBProgressHUDModeIndeterminate;
//    hud.backgroundView.color = [UIColor colorWithWhite:0 alpha:.5f];
    hud.label.textColor = [UIColor whiteColor];
    hud.label.text = @"正在处理，请稍候...";
}

+ (void)clientDidLoadRequest:(NSNotification *)note {
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    PBResponse *response = note.userInfo[PBResponseKey];
    NSString *tips = nil;
    if (response.error != nil) {
        tips = [response.error localizedDescription];
    }
    
    if (tips != nil) {
        MBProgressHUD *hud = [MBProgressHUD HUDForView:window];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = tips;
        hud.label.textColor = [UIColor whiteColor];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1.f];
    } else {
        [MBProgressHUD hideHUDForView:window animated:YES];
    }
}

@end
