//
//  NSArray+PBUtils.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

@interface NSArray (PBUtils)

- (NSArray *)arrayByReplacingObjectsWithBlock:(id (^)(NSInteger index, id object))block;
- (NSArray *)arrayByReplacingDictionariesWithClass:(Class)aClass;

@end
