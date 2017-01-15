//
//  PBClient+Paging.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/5/6.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBClient.h"

@implementation PBClient (Paging)

- (NSDictionary *)pagingParamsWithOffset:(NSUInteger)offset limit:(NSUInteger)limit page:(NSUInteger)page
{
    return @{@"offset":@(offset), @"limit":@(limit)};
}

@end
