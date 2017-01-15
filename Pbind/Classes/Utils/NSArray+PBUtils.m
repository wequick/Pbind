//
//  NSArray+PBUtils.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "NSArray+PBUtils.h"

@implementation NSArray (PBUtils)

- (NSArray *)arrayByReplacingObjectsWithBlock:(id (^)(NSInteger index, id object))block
{
    if (block == nil) {
        return self;
    }
    
    NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
    for (NSInteger index = 0; index < [self count]; index++) {
        id object = [self objectAtIndex:index];
        [newArray addObject:block(index, object)];
    }
    return newArray;
}

- (NSArray *)arrayByReplacingDictionariesWithClass:(Class)aClass
{
    return [self arrayByReplacingObjectsWithBlock:^id(NSInteger index, id object) {
        if ([aClass instancesRespondToSelector:@selector(initWithDictionary:)]) {
            return [[aClass alloc] initWithDictionary:object];
        } else {
            id newObject = [[aClass alloc] init];
            [newObject setValuesForKeysWithDictionary:object];
            return newObject;
        }
    }];
}

@end
