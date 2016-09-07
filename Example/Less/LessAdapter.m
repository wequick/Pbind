//
//  LessAdapter.m
//  Less
//
//  Created by Galen Lin on 16/9/7.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "LessAdapter.h"
#import <Less/Less.h>

@implementation LessAdapter

+ (void)load {
    [super load];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)applicationDidFinishLaunching:(NSNotification *)note {
    [Less setSketchWidth:1080];
}

@end
