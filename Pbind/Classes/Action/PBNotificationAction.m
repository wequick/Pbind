//
//  PBNotificationAction.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 31/12/2016.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBNotificationAction.h"

@implementation PBNotificationAction

@pbactions(@"notify", @"watch")
- (void)run:(PBActionState *)state {
    if (self.name == nil) {
        return;
    }
    
    if ([self.type isEqualToString:@"notify"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:self.name object:self.target userInfo:self.params];
    } else if ([self.type isEqualToString:@"watch"]) {
        if (![self hasNext:@"done"]) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivedNotification:) name:self.name object:self.target];
    }
}

- (void)didReceivedNotification:(NSNotification *)notification {
    [self dispatchNext:@"done"];
}

@end
