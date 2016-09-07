//
//  LSVariableFormatter.h
//  Less
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSStringFormatter : NSObject

+ (void)registerTag:(NSString *)tag withFormatterer:(NSString * (^)(NSString *format, id value))formatter;

+ (NSArray *)allTags;
+ (NSString * (^)(NSString *format, id value))formatterForTag:(NSString *)tag;

@end
