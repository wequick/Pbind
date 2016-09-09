//
//  PBMessageInterceptor.m
//  Pbind
//
//  Created by galen on 15/2/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBMessageInterceptor.h"

@implementation PBMessageInterceptor
@synthesize receiver;
@synthesize middleMan;

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([middleMan respondsToSelector:aSelector]) { return middleMan; }
    if ([receiver respondsToSelector:aSelector]) { return receiver; }
    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([middleMan respondsToSelector:aSelector]) { return YES; }
    if ([receiver respondsToSelector:aSelector]) { return YES; }
    return [super respondsToSelector:aSelector];
}

- (void)dealloc {
    middleMan = nil;
    receiver = nil;
}

@end
