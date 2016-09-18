//
//  PBVariableMapper.m
//  Pbind
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBVariableMapper.h"
#import "UIView+Pbind.h"
#import <UIKit/UIKit.h>
#import "PBForm.h"
#import "PBDictionary.h"

static NSMutableDictionary *kMappers;

@implementation PBVariableMapper

+ (void)registerTag:(char)tag withMapper:(id (^)(id data, id target, UIView *context))mapper
{
    if (tag >= '0' && tag <= '9') {
        NSLog(@"Failed to register variable mapper tag: 0 ~ 9 are reserved!");
        return;
    }
    
    if (kMappers == nil) {
        kMappers = [[NSMutableDictionary alloc] init];
    }
    [kMappers setObject:mapper forKey:@(tag)];
}

+ (NSArray *)allTags
{
    return [kMappers allKeys];
}

+ (id (^)(id data, id target, int index))mapperForTag:(char)tag
{
    return [kMappers objectForKey:@(tag)];
}

@end
