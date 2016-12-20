//
//  PBActionState.m
//  Pods
//
//  Created by Galen Lin on 2016/12/15.
//
//

#import "PBActionState.h"

@implementation PBActionState

- (NSDictionary *)mergedParams:(NSDictionary *)params {
    if (self.params == nil) {
        return params;
    }
    
    if (params == nil) {
        return self.params;
    }
    
    NSMutableDictionary *mergedParams = [NSMutableDictionary dictionaryWithDictionary:self.params];
    [mergedParams addEntriesFromDictionary:params];
    return mergedParams;
}

@end
