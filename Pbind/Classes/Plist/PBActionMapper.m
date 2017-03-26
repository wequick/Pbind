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
    self.next = [[NSMutableDictionary alloc] init];
    
    [super setPropertiesWithDictionary:dictionary];
    
    NSUInteger nextCount = self.next.count;
    if (nextCount > 0) {
        NSMutableDictionary *nextMappers = [NSMutableDictionary dictionaryWithCapacity:nextCount];
        for (NSString *key in self.next) {
            PBActionMapper *mapper = [PBActionMapper mapperWithDictionary:self.next[key]];
            [nextMappers setObject:mapper forKey:key];
        }
        self.nextMappers = nextMappers;
    }
}

@end
