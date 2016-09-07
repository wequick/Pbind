//
//  LSClient+Paging.m
//  Less
//
//  Created by galen on 15/5/6.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSClient.h"

@implementation LSClient (Paging)

- (NSDictionary *)pagingParamsWithOffset:(NSUInteger)offset limit:(NSUInteger)limit page:(NSUInteger)page
{
    return @{@"offset":@(offset), @"limit":@(limit)};
}

@end
