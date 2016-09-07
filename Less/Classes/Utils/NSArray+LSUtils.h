//
//  NSArray+LSUtils.h
//  Less
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (LSUtils)

- (NSArray *)arrayByReplacingObjectsWithBlock:(id (^)(NSInteger index, id object))block;
- (NSArray *)arrayByReplacingDictionariesWithClass:(Class)aClass;

@end
