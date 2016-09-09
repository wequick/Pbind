//
//  NSArray+PBUtils.m
//  Pbind
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015年 galen. All rights reserved.
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
