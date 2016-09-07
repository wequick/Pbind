//
//  LSRecord.m
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSRecord.h"

@implementation LSRecord

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    return self;
}

@end
