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
#import "PBLoadMoreControl.h"

@protocol PBRefreshing;
@protocol PBRowPaging;

/**
 An instance of PBRowDelegate provides the sizing, triggering for the cell of PBTableView and PBCollectionView.
 */
@interface PBRowDelegate : PBMessageInterceptor<UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    UIControl<PBRefreshing> *_refreshControl;
    PBLoadMoreControl *_loadMoreControl;
    NSTimeInterval _loadMoreBeginTime;
    struct {
        unsigned int loadingMore : 1;
        unsigned int usesCustomRefreshControl : 1;
    } _flags;
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

/** The mapper to map the data for pulled-down-to-refresh control */
@property (nonatomic, strong) PBRowControlMapper *refreshMapper;

/** The mapper to map the data for pulled-up-to-load-more control */
@property (nonatomic, strong) PBRowControlMapper *moreMapper;

- (void)beginRefreshingForPagingView:(UIScrollView<PBRowPaging> *)pagingView;

- (BOOL)pagingViewCanReloadData:(UIScrollView<PBRowPaging> *)pagingView;

#pragma mark - Purging

/** Reset the mappers */
- (void)reset;

#pragma mark - FlowLayout
///=============================================================================
/// @name FlowLayout
///=============================================================================

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) UIEdgeInsets itemInsets;
@property (nonatomic, assign) CGSize itemSpacing;

@end
