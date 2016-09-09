//
//  PBVariableFormatter.h
//  Pbind
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBStringFormatter : NSObject

+ (void)registerTag:(NSString *)tag withFormatterer:(NSString * (^)(NSString *format, id value))formatter;

+ (NSArray *)allTags;
+ (NSString * (^)(NSString *format, id value))formatterForTag:(NSString *)tag;

@end
