//
//  MyStyle.m
//  Pbind
//
//  Created by Galen Lin on 2017/8/8.
//  Copyright © 2017年 galenlin. All rights reserved.
//

#import "MyStyle.h"
#import <Pbind/Pbind.h>

@implementation MyStyle

+ (instancetype)defaultStyle {
    static MyStyle *o;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        o = [[MyStyle alloc] init];
    });
    return o;
}

- (instancetype)init {
    if (self = [super init]) {
        self.primaryColor = PBColorMake(@"5F76E6");
    }
    return self;
}

@end
