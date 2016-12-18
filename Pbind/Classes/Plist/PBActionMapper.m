//
//  PBActionMapper.m
//  Pbind
//
//  Created by Galen Lin on 2016/12/15.
//
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
            PBActionMapper *mapper = [PBActionMapper mapperWithDictionary:self.next[key] owner:nil];
            [nextMappers setObject:mapper forKey:key];
        }
        self.nextMappers = nextMappers;
    }
}

@end
