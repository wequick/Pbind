//
//  PBVariableMapper.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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

+ (BOOL)registersTag:(char)tag
{
    return [[kMappers allKeys] containsObject:@(tag)];
}

+ (id (^)(id data, id target, UIView *context))mapperForTag:(char)tag
{
    return [kMappers objectForKey:@(tag)];
}

@end
