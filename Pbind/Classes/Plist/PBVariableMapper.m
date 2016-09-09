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

@interface PBForm (Private)

- (PBDictionary *)inputTexts;
- (PBDictionary *)inputValues;

@end

@implementation PBVariableMapper

+ (void)load
{
    // `.' -> target
    [self _registerTag:@"."
           withMapper:^id(id data, id target, int index) {
               return target;
           }];
    // `$' -> root data
    [self _registerTag:@"$"
           withMapper:^id(id data, id target, int index) {
               if (![data respondsToSelector:@selector(objectAtIndexedSubscript:)]) return data;
               
               if (index >= [data count]) return nil;
               id value = data[index];
               if ([value isEqual:[NSNull null]]) {
                   return nil;
               }
               return value;
           }];
    // `.$' -> target data
    [self _registerTag:@".$"
           withMapper:^id(id data, id target, int index) {
               return [target data];
           }];
    // `@' -> active controller
    [self _registerTag:@"@"
           withMapper:^id(id data, id target, int index) {
                return [target supercontroller];
           }];
    // `>' -> form input text
    [self _registerTag:@">"
           withMapper:^id(id data, id target, int index) {
               PBForm *form = [target superviewWithClass:PBForm.class];
               if (form == nil) {
                   return nil;
               }
               
               return [form inputTexts];
           }];
    // `>@' -> form input value
    [self _registerTag:@">@"
           withMapper:^id(id data, id target, int index) {
               PBForm *form = [target superviewWithClass:PBForm.class];
               if (form == nil) {
                   return nil;
               }
               
               return [form inputValues];
           }];
}

+ (void)_registerTag:(NSString *)tag withMapper:(id (^)(id data, id target, int index))mapper
{
    if (kMappers == nil) {
        kMappers = [[NSMutableDictionary alloc] init];
    }
    [kMappers setObject:mapper forKey:tag];
}

+ (void)registerTag:(char)tag withMapper:(id (^)(id data, id target, int index))mapper
{
    [self _registerTag:[NSString stringWithFormat:@"$%c.", tag] withMapper:mapper];
}

+ (NSArray *)allTags
{
    return [kMappers allKeys];
}

+ (id (^)(id data, id target, int index))mapperForTag:(NSString *)tag
{
    return [kMappers objectForKey:tag];
}

@end
