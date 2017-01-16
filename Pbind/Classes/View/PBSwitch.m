//
//  PBSwitch.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 17/1/16.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBSwitch.h"

@implementation PBSwitch

@synthesize type, name, value, required, requiredTips;

- (void)reset {
    [super setOn:NO];
    self.value = nil;
}

- (void)setOn:(BOOL)on {
    [super setOn:on];
    [self willChangeValueForKey:@"value"];
    self.value = on ? @(on) : nil;
    [self didChangeValueForKey:@"value"];
}

@end
