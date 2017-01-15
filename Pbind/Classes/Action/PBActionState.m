//
//  PBActionState.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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
