//
//  UISwitch+PBForm.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/14.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UISwitch+PBForm.h"
#import "UIView+Pbind.h"

@implementation UISwitch (PBForm)

- (void)didMoveToSuperview {
    SEL aSel = @selector(valueChanged:);
    if (self.superview) {
        [self addTarget:self action:aSel forControlEvents:UIControlEventValueChanged];
    } else {
        [self removeTarget:self action:aSel forControlEvents:UIControlEventValueChanged];
    }
}

- (void)setValue:(id)value {
    [self willChangeValueForKey:@"value"];
    self.on = [value boolValue];
    [self didChangeValueForKey:@"value"];
}

- (id)value {
    return [NSNumber numberWithBool:[self isOn]];
}

- (void)valueChanged:(UISwitch *)sender {
    [self willChangeValueForKey:@"value"];
    [self didChangeValueForKey:@"value"];
}

- (void)reset {
    [self setValue:nil];
}

- (void)setType:(NSString *)value {
    [self setValue:value forAdditionKey:@"type"];
}

- (NSString *)type {
    return [self valueForAdditionKey:@"type"];
}

- (void)setName:(NSString *)value {
    [self setValue:value forAdditionKey:@"name"];
}

- (NSString *)name {
    return [self valueForAdditionKey:@"name"];
}

- (void)setRequiredTips:(NSString *)value {
    [self setValue:value forAdditionKey:@"requiredTips"];
}

- (NSString *)requiredTips {
    return [self valueForAdditionKey:@"requiredTips"];
}

- (void)setRequired:(BOOL)required {
    [self setValue:(required ? @(required) : nil) forAdditionKey:@"required"];
}

- (BOOL)isRequired {
    return [[self valueForAdditionKey:@"required"] boolValue];
}

@end
