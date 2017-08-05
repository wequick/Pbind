//
//  PBActionMapper.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBActionMapper.h"

@implementation PBActionMapper

- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary {
    self.type = dictionary[@"type"];
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    NSMutableDictionary *next = [[NSMutableDictionary alloc] init];
    for (NSString *key in dictionary) {
        NSRange range = [key rangeOfString:@"next."];
        if (range.location == NSNotFound) {
            continue;
        }
        
        NSString *actionKey = [key substringFromIndex:range.location + range.length];
        next[actionKey] = dictionary[key];
        [properties removeObjectForKey:key];
    }
    
    _viewProperties = [PBMapperProperties propertiesWithDictionary:properties mapper:self];
    
    NSUInteger nextCount = next.count;
    if (nextCount > 0) {
        NSMutableDictionary *nextMappers = [NSMutableDictionary dictionaryWithCapacity:nextCount];
        for (NSString *key in next) {
            PBActionMapper *mapper = [PBActionMapper mapperWithDictionary:next[key] owner:nil];
            [nextMappers setObject:mapper forKey:key];
        }
        self.nextMappers = nextMappers;
    }
}

@end
