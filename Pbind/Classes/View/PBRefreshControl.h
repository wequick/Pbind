//
//  PBRefreshControl.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2017/8/21.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBButton.h"

@protocol PBRowPaging;

@protocol PBRefreshing <NSObject>

@required

@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;

- (void)beginRefreshing;

- (void)endRefreshing;

@end

@interface PBRefreshControl : PBButton <PBRefreshing>

@property (nonatomic, assign) CGFloat beginDistance;


/** Reached the limit to begin refreshing */
@property (nonatomic, assign) BOOL reached;

- (void)pagingView:(UIScrollView<PBRowPaging> *)pagingView didPullDownWithDistance:(CGFloat)distance;

@end
