//
//  PBRowDelegate.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 22/12/2016.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBRowDataSource.h"

@protocol PBRowPaging;

@interface PBRowDelegate : PBMessageInterceptor<UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    UIRefreshControl *_refreshControl;
    UIRefreshControl *_pullupControl;
    NSTimeInterval _pullupBeginTime;
    UITableView *_pullControlWrapper;
}

@property (nonatomic, weak) id receiver;

@property (nonatomic, strong) PBRowDataSource *dataSource;

- (instancetype)initWithDataSource:(PBRowDataSource *)dataSource;

#pragma mark - Paging

@property (nonatomic, assign) BOOL refreshing;
@property (nonatomic, assign) BOOL pulling; // Pulling more data

- (void)beginRefreshingForPagingView:(UIScrollView<PBRowPaging> *)pagingView;
- (void)endPullingForPagingView:(UIScrollView<PBRowPaging> *)pagingView;

#pragma mark - FlowLayout

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) UIEdgeInsets itemInsets;
@property (nonatomic, assign) CGSize itemSpacing;

@end
