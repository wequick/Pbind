//
//  LSSectionMapper.m
//  Less
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSSectionMapper.h"
#import "LSRowMapper.h"
#import "Less+API.h"

@implementation LSSectionMapper

- (void)setHeight:(CGFloat)height
{
    [self willChangeValueForKey:@"height"];
    _height = height * [Less valueScale];
    [self didChangeValueForKey:@"height"];
}

- (CGFloat)heightForView:(id)view withData:(id)data
{
    return _height;
}

@end
