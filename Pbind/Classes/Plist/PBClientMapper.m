//
//  PBClientMapper.m
//  Pbind
//
//  Created by Galen Lin on 16/9/2.
//  Copyright © 2016年 galen. All rights reserved.
//

#import "PBClientMapper.h"

@implementation PBClientMapper

+ (instancetype)constMapperWithDictionary:(NSDictionary *)dictionary {
    PBClientMapper *mapper = [[PBClientMapper alloc] init];
    [mapper setValuesForKeysWithDictionary:dictionary];
    return mapper;
}

@end
