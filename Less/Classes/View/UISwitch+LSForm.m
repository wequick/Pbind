//
//  UISwitch+LSForm.m
//  Less
//
//  Created by galen on 15/4/14.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "UISwitch+LSForm.h"
#import "LSCompat.h"

@implementation UISwitch (LSForm)

DEF_UNDEFINED_LSOPERTY2(NSString *, type, setType)
DEF_UNDEFINED_LSOPERTY2(NSString *, name, setName)
DEF_UNDEFINED_LSOPERTY2(NSString *, requiredTips, setRequiredTips)
DEF_UNDEFINED_BOOL_LSOPERTY(isRequired, setRequired, NO)

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

@end
