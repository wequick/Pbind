//
//  PBRefreshControl.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2017/8/21.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBRefreshControl.h"

@implementation PBRefreshControl

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)pagingView:(UIScrollView<PBRowPaging> *)pagingView didPullDownWithDistance:(CGFloat)distance {
    // Stub
}

#pragma mark - API

- (void)beginRefreshing {
    self.selected = YES;
}

- (void)endRefreshing {
    self.selected = NO;
}

#pragma mark - Properties

- (BOOL)isRefreshing {
    return self.selected;
}

- (BOOL)isReached {
    return self.highlighted;
}

- (void)setReached:(BOOL)reached {
    self.highlighted = reached;
}

@end
