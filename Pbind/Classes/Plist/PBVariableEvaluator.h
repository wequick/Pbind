//
//  PBVariableEvaluator.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

@interface PBVariableEvaluator : NSObject

+ (void)registerTag:(NSString *)tag withEvaluator:(id (^)(NSString *tag, NSString *format, NSArray *args))formatter;

+ (NSArray *)allTags;
+ (id (^)(NSString *tag, NSString *format, NSArray *args))evaluatorForTag:(NSString *)tag;

@end
