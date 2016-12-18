//
//  PBCustomUIAction.m
//  Pbind
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "PBCustomUIAction.h"
#import "MBProgressHUD.h"

@implementation PBCustomUIAction

@pbaction(@"toast")
- (void)run {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.context.supercontroller.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:.8f];
    hud.label.textColor = [UIColor whiteColor];
    hud.label.text = self.params[@"message"];
    hud.label.textColor = [UIColor whiteColor];
    [hud hideAnimated:YES afterDelay:1.f];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dispatchNext:@"done"];
    });
}

@end
