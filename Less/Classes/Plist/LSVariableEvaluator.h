//
//  LSVariableEvaluator.h
//  Less
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSVariableEvaluator : NSObject

+ (void)registerTag:(NSString *)tag withEvaluator:(id (^)(NSString *tag, NSString *format, NSArray *args))formatter;

+ (NSArray *)allTags;
+ (id (^)(NSString *tag, NSString *format, NSArray *args))evaluatorForTag:(NSString *)tag;

@end
