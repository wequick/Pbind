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
@synthesize valueDelegate;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addTarget:self action:@selector(onValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)reset {
    [super setOn:NO];
    value = @(NO);
}

- (void)setOn:(BOOL)on {
    [super setOn:on];
    [self willChangeValueForKey:@"value"];
    value = @(on);
    [self didChangeValueForKey:@"value"];
}

- (void)setValue:(id)aValue {
    value = aValue;
    [super setOn:[aValue boolValue]];
}

- (void)onValueChanged:(PBSwitch *)sender {
    NSNumber *newValue = @(sender.on);
    if ([valueDelegate respondsToSelector:@selector(input:canChangeValue:)]) {
        if (![valueDelegate input:self canChangeValue:newValue]) {
            [super setOn:!sender.on];
            return;
        }
    }
    
    [self willChangeValueForKey:@"value"];
    value = newValue;
    [self didChangeValueForKey:@"value"];
}

@end
