//
//  NSValue+PBKVO.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/9/5.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "NSValue+PBKVO.h"
#import <UIKit/UIKit.h>

@implementation NSValue (PBKVO)

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath isEqualToString:@"size"]) {
        return [NSValue valueWithCGSize:[self CGRectValue].size];
    } else if ([keyPath isEqualToString:@"height"]) {
        return [NSNumber numberWithFloat:[self CGSizeValue].height];
    } else if ([keyPath isEqualToString:@"width"]) {
        return [NSNumber numberWithFloat:[self CGSizeValue].width];
    } else if ([keyPath isEqualToString:@"x"]) {
        return [NSNumber numberWithFloat:[self CGPointValue].x];
    } else if ([keyPath isEqualToString:@"y"]) {
        return [NSNumber numberWithFloat:[self CGPointValue].y];
    } else if ([keyPath isEqualToString:@"scale"]) {
        CGAffineTransform transform = [self CGAffineTransformValue];
        return [NSNumber numberWithDouble:(transform.a + transform.d) / 2];
    } else if ([keyPath isEqualToString:@"translation"]) {
        CGAffineTransform transform = [self CGAffineTransformValue];
        return [NSValue valueWithCGPoint:CGPointMake(transform.tx, transform.ty)];
    }
    return [super valueForKeyPath:keyPath];
}

@end
