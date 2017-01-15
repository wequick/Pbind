//
//  PBVariableEvaluator.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBVariableEvaluator.h"
#import <JavascriptCore/JavascriptCore.h>

static NSMutableDictionary *kFormatters;

@implementation PBVariableEvaluator

+ (void)registerTag:(NSString *)tag withEvaluator:(id (^)(NSString *tag, NSString *format, NSArray *args))formatter
{
    if (kFormatters == nil) {
        kFormatters = [[NSMutableDictionary alloc] init];
    }
    [kFormatters setObject:formatter forKey:tag];
}

+ (NSArray *)allTags
{
    return [kFormatters allKeys];
}

+ (id (^)(NSString *tag, NSString *format, NSArray *args))evaluatorForTag:(NSString *)tag
{
    return [kFormatters objectForKey:tag];
}

@end
