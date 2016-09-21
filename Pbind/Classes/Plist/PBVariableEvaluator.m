//
//  PBVariableEvaluator.m
//  Pbind
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015年 galen. All rights reserved.
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
