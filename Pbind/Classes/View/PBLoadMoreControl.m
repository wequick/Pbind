//
//  PBLoadMoreControl.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2017/8/20.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBLoadMoreControl.h"

@implementation PBLoadMoreControl

static const CGFloat kUnsetBeginDistance = -0xFFFF;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _beginDistance = kUnsetBeginDistance;
    }
    return self;
}

#pragma mark - API

- (void)beginLoading {
    self.selected = YES;
}

- (void)endLoading {
    self.selected = NO;
}

#pragma mark - Properties

- (BOOL)isEnding {
    return !self.enabled;
}

- (BOOL)setEnding:(BOOL)ending {
    self.enabled = !ending;
}

- (BOOL)isLoading {
    return self.selected;
}

- (void)setLoading:(BOOL)loading {
    self.selected = loading;
}

- (CGFloat)beginDistance {
    if (_beginDistance == kUnsetBeginDistance) {
        return self.frame.size.height;
    }
    return _beginDistance;
}

@end
