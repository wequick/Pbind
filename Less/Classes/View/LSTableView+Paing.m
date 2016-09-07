//
//  LSTableView+Paging.m
//  Less
//
//  Created by galen on 15/5/6.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSTableView.h"
#import "UIView+Less.h"
#import "LSCompat.h"
#import <objc/runtime.h>

@implementation LSTableView (Paging)

DEF_DYNAMIC_UINTEGER_LSOPERTY(numberOfRowsInPage, setNumberOfRowsInPage, 0)

#if 0
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self _scrollToFloatSection:scrollView];
    [self _scrollToRefresh:scrollView];
    [self _scrollToLoadMore:scrollView];
    
    // Forward to original delegate
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [_delegateInterceptor.receiver scrollViewDidScroll:scrollView];
    }
}

- (void)_scrollToFloatSection:(UIScrollView *)scrollView {
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(tableView:allowsFloatForSection:)]) {
        NSInteger maxSection = [self numberOfSections];
        if (maxSection > 1) {
            UITableView *tableView = (UITableView *)scrollView;
            CGPoint p = CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y);
            p.y += _initedContentInset.top;
            NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:p];
            NSInteger section = 0;
            CGFloat y = p.y - tableView.tableHeaderView.frame.size.height;
            if (indexPath) {
                section = indexPath.section;
            } else if (y > 0) {
                section = maxSection;
                for (NSInteger i=0; i<maxSection-1; i++) {
                    CGRect headerRect1 = [tableView rectForHeaderInSection:i];
                    CGRect headerRect2 = [tableView rectForHeaderInSection:i+1];
                    if (headerRect1.origin.y <= p.y &&
                        headerRect2.origin.y > p.y) {
                        section = i;
                    }
                }
            }
            
            if (![_delegateInterceptor.receiver tableView:tableView allowsFloatForSection:section]) {
                CGFloat sectionHeaderHeight = [self tableView:tableView heightForHeaderInSection:section];
                //                NSLog(@"[%i-%i], cy=%.2f, y=%.2f, h=%.2f", (int)indexPath.section, (int)indexPath.row, scrollView.contentOffset.y, y, sectionHeaderHeight);
                if (y <= 0) {
                    scrollView.contentInset = _initedContentInset;
                } else if (y < sectionHeaderHeight && y > 0) {
                    scrollView.contentInset = UIEdgeInsetsMake(_initedContentInset.top - y, 0, 0, 0);
                } else if (y >= sectionHeaderHeight) {
                    scrollView.contentInset = UIEdgeInsetsMake(_initedContentInset.top - sectionHeaderHeight, 0, 0, 0);
                }
            } else {
                scrollView.contentInset = _initedContentInset;
            }
        }
    }
}

- (void)_scrollToRefresh:(UIScrollView *)scrollView {
    if (!self.refreshingEnabled) {
        return;
    }
    
    CGFloat top = _initedContentInset.top;
    UIEdgeInsets currentInsets = scrollView.contentInset;
    CGFloat height = self.refreshingViewHeight;
    if (self.pagingState == LSTableViewPagingStateRefreshing) {
        // 加载中，回到初始位置
        if (currentInsets.top != top + height + .5f) {//lgl:fix
            CGFloat offset = MAX(scrollView.contentOffset.y * -1, 0);
            offset = MIN(offset, height + .5f);
            currentInsets.top = offset + top;
            scrollView.contentInset = currentInsets;
            //            NSLog(@"top:%.2f", currentInsets.top);
        }
    } else if (scrollView.isDragging && !_lsTableViewFlags.refreshing) {
        // 拖拽中，切换"下拉"与"释放"状态
        if (scrollView.contentOffset.y > -height - top &&
            scrollView.contentOffset.y < -top) {
            if (self.pagingState != LSTableViewPagingStatePullDownMove &&
                self.pagingState != LSTableViewPagingStatePullDownBegin) {
                // 执行一次
                [self setPagingState:LSTableViewPagingStatePullDownBegin];
            }
            [self setPagingState:LSTableViewPagingStatePullDownMove];
        } else if (scrollView.contentOffset.y < -height - top) {
            if (self.pagingState != LSTableViewPagingStatePullDownEnd)
                [self setPagingState:LSTableViewPagingStatePullDownEnd];
        }
        
        if (currentInsets.top != top) {
            currentInsets.top = top;
            scrollView.contentInset = currentInsets;
        }
    }
}

- (void)_scrollToLoadMore:(UIScrollView *)scrollView {
    if (!self.loadingMoreEnabled || self.noMore) {
        return;
    }
    
    CGFloat bottomOffset = [self _scrollViewOffsetFromBottom:scrollView];
    CGFloat height = self.loadingMoreViewHeight;
    if (scrollView.isDragging && !_lsTableViewFlags.loadingMore) {
        if (bottomOffset > -height && bottomOffset < 0.0f) {
            if (self.pagingState != LSTableViewPagingStatePullUpMove &&
                self.pagingState != LSTableViewPagingStatePullUpBegin) {
                // 执行一次
                [self setPagingState:LSTableViewPagingStatePullUpBegin];
            }
            [self setPagingState:LSTableViewPagingStatePullUpMove];
        } else if (bottomOffset < -height) {
            if (self.pagingState != LSTableViewPagingStatePullUpEnd) {
                [self setPagingState:LSTableViewPagingStatePullUpEnd];
            }
        }
    }
}

#define kScrollRate 50

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // Refreshing
    if (!_lsTableViewFlags.refreshing) {
        if (self.pagingState == LSTableViewPagingStatePullDownEnd) {
            [self setPagingState:LSTableViewPagingStateRefreshing];
            [self _showRefreshView:YES];
        }
    }
    
    // Forward to original delegate
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [_delegateInterceptor.receiver scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)_showRefreshView:(BOOL)show {
    [UIView animateWithDuration:.3 animations:^{
        UIEdgeInsets insets = self.contentInset;
        if (show) {
            insets.top = _initedContentInset.top + self.refreshingViewHeight;
        } else {
            insets.top = _initedContentInset.top;
        }
        self.contentInset = insets;
    }];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
//    if ([self reboundsDisabled]) {
//        _offsetUpdateDisabled = YES;
//    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // Rebounds
//    if ([self reboundsDisabled]) {
//        _offsetUpdateDisabled = NO;
//        [self setReboundsDisabled:NO];
//    }
    
    // Loading more
    if (self.loadingMoreEnabled && !_lsTableViewFlags.loadingMore && !self.noMore) {
        CGFloat offset = [self _scrollViewOffsetFromBottom:scrollView];
        if (offset == 0) {
            // Reaching bottom
            _lsTableViewFlags.loadingMore = YES;
            if (self.data == nil) {
                self.rowOffset = 0;
            } else {
                self.rowOffset = [self.data count];
            }
            
            [self pr_pullData];
        }
    }
    
    // Refreshing
    if (self.pagingState == LSTableViewPagingStateRefreshing && !_lsTableViewFlags.refreshing) {
        _lsTableViewFlags.refreshing = 1;
        _lsTableViewFlags.loadingMore = 0;
        self.data = nil;
        self.noMore = NO;
        
        [self pr_pullData];
    }
    
    // Forward to original delegate
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [_delegateInterceptor.receiver scrollViewDidEndDecelerating:scrollView];
    }
}

- (CGFloat)_scrollViewOffsetFromBottom:(UIScrollView *)scrollView
{
    CGFloat scrollAreaContenHeight = scrollView.contentSize.height;
    CGFloat visibleTableHeight = MIN(scrollView.bounds.size.height, scrollAreaContenHeight);
    CGFloat scrolledDistance = scrollView.contentOffset.y + visibleTableHeight; // If scrolled all the way down this should add upp to the content heigh.
    CGFloat normalizedOffset = scrollAreaContenHeight - scrolledDistance;
    
    return normalizedOffset;
    
}

#endif

@end
