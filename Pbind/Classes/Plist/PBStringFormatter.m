//
//  PBVariableFormatter.m
//  Pbind
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBStringFormatter.h"
#import "UIView+Pbind.h"

static NSMutableDictionary *kFormatters;

@implementation PBStringFormatter

+ (void)load
{
    // Date format
    [self registerTag:@"t" withFormatterer:^NSString *(NSString *format, id value) {
        NSDate *date = value;
        if ([value isKindOfClass:[NSNumber class]]) {
            date = [NSDate dateWithTimeIntervalSince1970:[value longLongValue]];
        }
        if (![date isKindOfClass:[NSDate class]]) {
            return @"<nil>";
        }
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:format];
        return [formatter stringFromDate:date];
    }];
    // Date template
    [self registerTag:@"T" withFormatterer:^NSString *(NSString *format, id value) {
        NSDate *date = value;
        if ([value isKindOfClass:[NSNumber class]]) {
            date = [NSDate dateWithTimeIntervalSince1970:[value longLongValue]];
        }
        if (![date isKindOfClass:[NSDate class]]) {
            return @"<nil>";
        }
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:format options:0 locale:[NSLocale currentLocale]];
        [formatter setDateFormat:dateFormat];
        return [formatter stringFromDate:date];
    }];
    // Encoding json
    [self registerTag:@"UE" withFormatterer:^NSString *(NSString *format, id value) {
        return PBHrefEncode(value);
    }];
    // Encoding json
    [self registerTag:@"UEJ" withFormatterer:^NSString *(NSString *format, id value) {
        return PBParameterJson(value);
    }];
}

+ (void)registerTag:(NSString *)tag withFormatterer:(NSString * (^)(NSString *format, id value))formatter
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

+ (NSString * (^)(NSString *format, id value))formatterForTag:(NSString *)tag
{
    return [kFormatters objectForKey:tag];
}

@end
