//
//  PBRowDelegate.h
//  Pbind
//
//  Created by Galen Lin on 22/12/2016.
//
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
