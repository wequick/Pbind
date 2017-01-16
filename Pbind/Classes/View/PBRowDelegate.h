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

/**
 An instance of PBRowDelegate provides the sizing, triggering for the cell of PBTableView and PBCollectionView.
 */
@interface PBRowDelegate : PBMessageInterceptor<UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    UIRefreshControl *_refreshControl;
    UIRefreshControl *_pullupControl;
    NSTimeInterval _pullupBeginTime;
    UITableView *_pullControlWrapper;
}

#pragma mark - Context
///=============================================================================
/// @name Context
///=============================================================================

/** The receiver to receive the messages redirecting by the methods of the delegate */
@property (nonatomic, weak) id receiver;

/** The data source of the owner (PBTableView or PBCollectionView) */
@property (nonatomic, strong) PBRowDataSource *dataSource;

- (instancetype)initWithDataSource:(PBRowDataSource *)dataSource;

#pragma mark - Paging
///=============================================================================
/// @name Paging
///=============================================================================

/** Whether the owner is refreshing data */
@property (nonatomic, assign) BOOL refreshing;

/** Whether the owner is pulling more data */
@property (nonatomic, assign) BOOL pulling;

- (void)beginRefreshingForPagingView:(UIScrollView<PBRowPaging> *)pagingView;
- (void)endPullingForPagingView:(UIScrollView<PBRowPaging> *)pagingView;

#pragma mark - FlowLayout
///=============================================================================
/// @name FlowLayout
///=============================================================================

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) UIEdgeInsets itemInsets;
@property (nonatomic, assign) CGSize itemSpacing;

@end
