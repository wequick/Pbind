//
//  PBVariableEvaluator.h
//  Pbind
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBVariableEvaluator : NSObject

+ (void)registerTag:(NSString *)tag withEvaluator:(id (^)(NSString *tag, NSString *format, NSArray *args))formatter;

+ (NSArray *)allTags;
+ (id (^)(NSString *tag, NSString *format, NSArray *args))evaluatorForTag:(NSString *)tag;

@end
