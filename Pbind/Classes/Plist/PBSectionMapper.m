//
//  PBSectionMapper.m
//  Pbind
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBSectionMapper.h"
#import "PBRowMapper.h"
#import "Pbind+API.h"

@implementation PBSectionMapper

- (void)setHeight:(CGFloat)height
{
    [self willChangeValueForKey:@"height"];
    _height = height * [Pbind valueScale];
    [self didChangeValueForKey:@"height"];
}

- (CGFloat)heightForView:(id)view withData:(id)data
{
    return _height;
}

@end
