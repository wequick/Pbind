//
//  PBButton.m
//  Pods
//
//  Created by Galen Lin on 2016/12/21.
//
//

#import "PBButton.h"
#import "UIView+Pbind.h"
#import "PBActionStore.h"

@implementation PBButton
{
    UIColor *_backgroundColor;
}

#pragma mark - PBInput

@synthesize type, name, value, required, requiredTips;

- (void)reset {
    
}

#pragma mark -

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    [super setBackgroundColor:backgroundColor];
}

- (void)setAction:(NSDictionary *)action {
    [super setAction:action];
    [self addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)handleAction:(id)sender {
    [[PBActionStore defaultStore] dispatchActionForView:self];
}

#pragma mark - State changing

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        [super setBackgroundColor:[_backgroundColor colorWithAlphaComponent:.8]];
    } else {
        [super setBackgroundColor:_backgroundColor];
    }
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    if (enabled) {
        [super setBackgroundColor:_backgroundColor];
    } else {
        [super setBackgroundColor:[_backgroundColor colorWithAlphaComponent:.2]];
    }
}

@end
