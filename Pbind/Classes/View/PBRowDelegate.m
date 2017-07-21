//
//  PBRowDelegate.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 22/12/2016.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBRowDelegate.h"
#import "UIView+Pbind.h"
#import "PBSection.h"
#import "PBActionStore.h"
#import "PBCollectionView.h"
#import "PBDataFetcher.h"
#import "PBDataFetching.h"
#import "PBHeaderFooterMapper.h"
#import "PBSectionView.h"

@implementation PBRowDelegate

@synthesize receiver;

static const CGFloat kMinRefreshControlDisplayingTime = .75f;

#pragma mark - Common

- (instancetype)initWithDataSource:(PBRowDataSource *)dataSource {
    if (self = [super init]) {
        self.dataSource = dataSource;
    }
    return self;
}

#pragma mark - Paging

- (void)beginRefreshingForPagingView:(UIScrollView<PBRowPaging> *)pagingView {
    if (_refreshControl == nil) {
        return;
    }
    
    if (_refreshControl.isRefreshing) {
        return;
    }
    
    CGPoint offset = pagingView.contentOffset;
    offset.y = -pagingView.contentInset.top - _refreshControl.bounds.size.height;
    pagingView.contentOffset = offset;
    [_refreshControl beginRefreshing];
    [_refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)scrollViewDidScroll:(UIScrollView<PBRowPaging> *)pagingView {
    if ([self.receiver respondsToSelector:_cmd]) {
        [self.receiver scrollViewDidScroll:pagingView];
    }
    
    if (pagingView.pagingParams == nil) {
        return;
    }
    
    if (_pullupControl != nil && ![_pullupControl isEnabled]) {
        return;
    }
    
    CGPoint contentOffset = pagingView.contentOffset;
    UIEdgeInsets contentInset = pagingView.contentInset;
    CGFloat height = pagingView.bounds.size.height;
    CGFloat pullupY = (contentOffset.y + contentInset.top + height) - MAX((pagingView.contentSize.height + contentInset.bottom + contentInset.top), height);
    
    if (pullupY > 0) {
        // Pull up to load more
        if (!pagingView.needsLoadMore) {
            return;
        }
        
        UITableView *wrapper = _pullControlWrapper;
        if (wrapper == nil) {
            wrapper = [[UITableView alloc] initWithFrame:pagingView.frame];
            wrapper.userInteractionEnabled = NO;
            wrapper.backgroundColor = [UIColor clearColor];
            wrapper.separatorStyle = UITableViewCellSeparatorStyleNone;
            wrapper.transform = CGAffineTransformMakeRotation(M_PI);
            _pullupControl = [[UIRefreshControl alloc] init];
            [_pullupControl addTarget:self action:@selector(pullupControlDidReleased:) forControlEvents:UIControlEventValueChanged];
            [wrapper addSubview:_pullupControl];
            _pullControlWrapper = wrapper;
            
            pagingView.needsLoadMore = YES;
            
            [pagingView.superview insertSubview:_pullControlWrapper aboveSubview:pagingView];
        }
    } else {
        // Pull down to refresh
        if (_refreshControl == nil) {
            UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
            [refreshControl addTarget:self action:@selector(refreshControlDidReleased:) forControlEvents:UIControlEventValueChanged];
            [pagingView addSubview:refreshControl];
            _refreshControl = refreshControl;
        }
    }
    
    if (_pullControlWrapper == nil) {
        return;
    }
    
    if (pullupY >= _pullupControl.bounds.size.height * 1.5) {
        if (!_pullupControl.refreshing) {
            [_pullupControl beginRefreshing];
            [_pullupControl sendActionsForControlEvents:UIControlEventValueChanged];
        }
    } else {
        CGPoint pullupOffset = _pullControlWrapper.contentOffset;
        pullupOffset.y = -pullupY;
        _pullControlWrapper.contentOffset = pullupOffset;
    }
}

- (void)refreshControlDidReleased:(UIRefreshControl *)sender {
    NSDate *start = [NSDate date];
    
    UIScrollView<PBRowPaging, PBDataFetching> *pagingView = (id)[sender nextResponder];
    if ([pagingView isFetching] || pagingView.clients == nil) {
        [self endRefreshing:sender startAt:start];
        return;
    }
    
    // Reset paging params
    pagingView.page = 0;
    [pagingView pb_mapData:pagingView.data forKey:@"pagingParams"];
    
    [pagingView.fetcher fetchDataWithTransformation:^id(id data, NSError *error) {
        [self endRefreshing:sender startAt:start];
        return data;
    }];
}

- (void)endRefreshing:(UIRefreshControl *)sender startAt:(NSDate *)start {
    NSTimeInterval spentTime = [[NSDate date] timeIntervalSinceDate:start];
    if (spentTime < kMinRefreshControlDisplayingTime) {
        NSTimeInterval fakeAwaitingTime = kMinRefreshControlDisplayingTime - spentTime;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fakeAwaitingTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sender endRefreshing];
        });
    } else {
        [sender endRefreshing];
    }
    
    if (_pullupControl != nil) {
        [_pullupControl setEnabled:YES];
    }
}

- (void)pullupControlDidReleased:(UIRefreshControl *)sender {
    UIScrollView<PBRowPaging, PBDataFetching> *pagingView = (id)[sender nextResponder];
    
    UIEdgeInsets insets = pagingView.contentInset;
    insets.bottom += _pullupControl.bounds.size.height;
    pagingView.contentInset = insets;
    
    // Increase page
    pagingView.page++;
    [pagingView pb_mapData:pagingView.data forKey:@"pagingParams"];
    
    _pullupBeginTime = [[NSDate date] timeIntervalSince1970];
    [pagingView.fetcher fetchDataWithTransformation:^id(id data, NSError *error) {
        if (pagingView.listKey != nil) {
            NSMutableArray *list = [NSMutableArray arrayWithArray:[self.dataSource list]];
            [list addObjectsFromArray:[data valueForKey:pagingView.listKey]];
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *newData = [NSMutableDictionary dictionaryWithDictionary:data];
                [newData setValue:list forKey:pagingView.listKey];
                data = newData;
            } else {
                [data setValue:list forKey:pagingView.listKey];
            }
        } else {
            NSMutableArray *list = [NSMutableArray arrayWithArray:pagingView.data];
            [list addObjectsFromArray:data];
            data = list;
        }
        
        return data;
    }];
}

- (void)endPullingForPagingView:(UIScrollView<PBRowPaging> *)pagingView {
    NSTimeInterval spentTime = [[NSDate date] timeIntervalSince1970] - _pullupBeginTime;
    if (spentTime < kMinRefreshControlDisplayingTime) {
        NSTimeInterval fakeAwaitingTime = kMinRefreshControlDisplayingTime - spentTime;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fakeAwaitingTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self endPullup:pagingView];
        });
    } else {
        [self endPullup:pagingView];
    }
}

- (void)endPullup:(UIScrollView<PBRowPaging> *)pagingView {
    [_pullupControl endRefreshing];
    [pagingView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Adjust content insets
        UIEdgeInsets insets = pagingView.contentInset;
        insets.bottom -= _pullupControl.bounds.size.height;
        pagingView.contentInset = insets;
    });
}

#pragma mark - UITableView
#pragma mark - Display customization

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Hides last separator
    if (self.dataSource.sections.count > indexPath.section) {
        PBSectionMapper *mapper = [self.dataSource.sections objectAtIndex:indexPath.section];
        if (mapper.hidesLastSeparator && indexPath.row == mapper.rowCount - 1
            && [self.dataSource dataAtIndexPath:indexPath] != nil) {
            [self _hidesBottomSeparatorForCell:cell];
        }
    }
    
    // Forward delegate
    if ([self.receiver respondsToSelector:_cmd]) {
        [self.receiver tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}
//- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section NS_AVAILABLE_IOS(6_0) {
//    
//}
//- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section NS_AVAILABLE_IOS(6_0) {
//    
//}
//- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath NS_AVAILABLE_IOS(6_0) {
//    
//}
//- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section NS_AVAILABLE_IOS(6_0) {
//    
//}
//- (void)tableView:(UITableView *)tableView didEndDisplayingFooterView:(UIView *)view forSection:(NSInteger)section NS_AVAILABLE_IOS(6_0) {
//    
//}

#pragma mark - Variable height support

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row == nil) {
        return tableView.rowHeight;
    }
    
    return [row heightForData:tableView.data withRowDataSource:self.dataSource indexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView heightForHeaderInSection:section];
    }
    
    if (self.dataSource.sections != nil) {
        PBSectionMapper *aSection = [self.dataSource.sections objectAtIndex:section];
        CGFloat height = [aSection heightForData:tableView.data];
        if (height >= 0) {
            return height;
        }
        return tableView.sectionHeaderHeight;
    } else if ([tableView.data isKindOfClass:[PBSection class]]) {
        return tableView.sectionHeaderHeight;
    } else if (self.dataSource.row != nil || self.dataSource.rows != nil) {
        return 0;
    }
    
    if ([self.receiver respondsToSelector:_cmd]) {
        return tableView.sectionHeaderHeight;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView heightForFooterInSection:section];
    }
    
    if (self.dataSource.sections.count <= section) {
        return 0;
    }
    
    PBSectionMapper *mapper = [self.dataSource.sections objectAtIndex:section];
    if (mapper.footer == nil) {
        return 0;
    }
    
    PBRowMapper *footerMapper = (id) mapper.footer;
    return [footerMapper heightForData:tableView.data];
}

// Use the estimatedHeight methods to quickly calcuate guessed values which will allow for fast load times of the table.
// If these methods are implemented, the above -tableView:heightForXXX calls will be deferred until views are ready to be displayed, so more expensive logic can be placed there.
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(7_0) {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
    }
    
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row == nil) {
        return tableView.estimatedRowHeight;
    }
    
    if (row.hidden) {
        return 0;
    }
    
    if (row.estimatedHeight == UITableViewAutomaticDimension) {
        if (tableView.estimatedRowHeight > 0) {
            return tableView.estimatedRowHeight;
        }
        return UITableViewAutomaticDimension;
    }
    
    return row.estimatedHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section NS_AVAILABLE_IOS(7_0) {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView estimatedHeightForHeaderInSection:section];
    }
    
    PBRowMapper *row = [self.dataSource.sections objectAtIndex:section];
    if (row == nil) {
        return tableView.estimatedSectionHeaderHeight;
    }
    
    if (row.hidden) {
        return 0;
    }
    
    if (row.estimatedHeight == UITableViewAutomaticDimension) {
        if (tableView.estimatedSectionHeaderHeight > 0) {
            return tableView.estimatedSectionHeaderHeight;
        }
        return UITableViewAutomaticDimension;
    }
    
    return row.estimatedHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section NS_AVAILABLE_IOS(7_0) {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView estimatedHeightForFooterInSection:section];
    }
    
    PBRowMapper *row = [self.dataSource.sections objectAtIndex:section].footer;
    if (row == nil) {
        return tableView.estimatedSectionHeaderHeight;
    }
    
    if (row.hidden) {
        return 0;
    }
    
    if (row.estimatedHeight == UITableViewAutomaticDimension) {
        if (tableView.estimatedSectionHeaderHeight > 0) {
            return tableView.estimatedSectionHeaderHeight;
        }
        return UITableViewAutomaticDimension;
    }
    
    return row.estimatedHeight;
}

// Section header & footer information. Views are preferred over title should you decide to provide both

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView viewForHeaderInSection:section];
    }
    
    PBSectionMapper *mapper = [self.dataSource.sections objectAtIndex:section];
    if (mapper == nil || mapper.viewClass == nil) {
        return nil;
    }
    
//    CGRect frame = CGRectMake(0, 0, tableView.bounds.size.width, mapper.height);
    UIView *view = [[mapper.viewClass alloc] init];
    [mapper initDataForView:view];
    [mapper mapData:tableView.data forView:view];
    
    return view;
}// custom view for header. will be adjusted to default or specified header height

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView viewForFooterInSection:section];
    }
    
    if (self.dataSource.sections.count <= section) {
        return nil;
    }
    
    PBSectionMapper *mapper = [self.dataSource.sections objectAtIndex:section];
    if (mapper.footer == nil) {
        return nil;
    }
    
    PBSectionView *footerView = [[PBSectionView alloc] init];
    
    // Create content view
    UIView *contentView = nil;
    PBHeaderFooterMapper *footerMapper = (id) mapper.footer;
    NSString *title = footerMapper.title;
    if (title != nil) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = title;
        titleLabel.numberOfLines = 0;
        if (footerMapper.titleFont != nil) {
            titleLabel.font = footerMapper.titleFont;
        }
        if (footerMapper.titleColor != nil) {
            titleLabel.textColor = footerMapper.titleColor;
        }
        contentView = titleLabel;
    } else {
        // Custom footer view
        contentView = [[footerMapper.viewClass alloc] init];
        if (footerMapper.layoutMapper != nil) {
            [footerMapper.layoutMapper renderToView:contentView];
        }
        
        [footerMapper initDataForView:contentView];
        [footerMapper mapData:tableView.data forView:contentView];
    }
    
    // Set content view margin
    [footerView addSubview:contentView];
    UIEdgeInsets margin = footerMapper.margin;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeTop multiplier:1 constant:margin.top]];
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeLeft multiplier:1 constant:margin.left]];
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeBottom multiplier:1 constant:margin.bottom]];
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:footerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeRight multiplier:1 constant:margin.right]];
    
    footerView.section = section;
    return footerView;
}// custom view for footer. will be adjusted to default or specified footer height

//#pragma mark - Accessories (disclosures).

//- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath NS_DEPRECATED_IOS(2_0, 3_0) __TVOS_PROHIBITED;
//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Selection

// -tableView:shouldHighlightRowAtIndexPath: is called when a touch comes down on a row.
// Returning NO to that message halts the selection process and does not cause the currently selected row to lose its selected look while the touch is down.
//- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(6_0);
//- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(6_0);
//- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(6_0);

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *newIndexPath = indexPath;
    
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.willSelectActionMapper != nil) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self dispatchAction:row.willSelectActionMapper forCell:cell atIndexPath:indexPath];
    }
    
    if ([self.receiver respondsToSelector:_cmd]) {
        newIndexPath = [self.receiver tableView:tableView willSelectRowAtIndexPath:indexPath];
    }
    
    return newIndexPath;
}

- (nullable NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *newIndexPath = indexPath;
    
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.willDeselectActionMapper != nil) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self dispatchAction:row.willDeselectActionMapper forCell:cell atIndexPath:indexPath];
    }
    
    if ([self.receiver respondsToSelector:_cmd]) {
        newIndexPath = [self.receiver tableView:tableView willDeselectRowAtIndexPath:indexPath];
    }
    
    return newIndexPath;
}

// Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.selectActionMapper != nil) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self dispatchAction:row.selectActionMapper forCell:cell atIndexPath:indexPath];
    }
    
    if ([self.receiver respondsToSelector:_cmd]) {
        [self.receiver tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.deselectActionMapper != nil) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self dispatchAction:row.deselectActionMapper forCell:cell atIndexPath:indexPath];
    }
    
    if ([self.receiver respondsToSelector:_cmd]) {
        [self.receiver tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

#pragma mark - Editing

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView<PBRowMapping> *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.editActionMappers == nil) {
        return nil;
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSMutableArray *editActions = [[NSMutableArray alloc] initWithCapacity:row.editActionMappers.count];
    for (PBRowActionMapper *actionMapper in row.editActionMappers) {
        [actionMapper updateWithData:tableView.rootData andView:cell];
        UITableViewRowAction *rowAction = [UITableViewRowAction rowActionWithStyle:actionMapper.style title:actionMapper.title handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            tableView.editingIndexPath = indexPath;
            [self dispatchAction:actionMapper forCell:cell atIndexPath:indexPath];
        }];
        if (actionMapper.backgroundColor != nil) {
            rowAction.backgroundColor = actionMapper.backgroundColor;
        }
        [editActions addObject:rowAction];
    }
    
    return editActions;
}// supercedes -tableView:titleForDeleteConfirmationButtonForRowAtIndexPath: if return value is non-nil

// Controls whether the background is indented while editing.  If not implemented, the default is YES.  This is unrelated to the indentation level below.  This method only applies to grouped style table views.
//- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath;

// The willBegin/didEnd methods are called whenever the 'editing' property is automatically changed by the table (allowing insert/delete/move). This is done by a swipe activating a single row
//- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath __TVOS_PROHIBITED;
//- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(nullable NSIndexPath *)indexPath __TVOS_PROHIBITED;

//#pragma mark - Moving/reordering

// Allows customization of the target row for a particular row as it is being moved/reordered
//- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

//#pragma mark - Indentation

//- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath; // return 'depth' of row for hierarchies

//#pragma mark - Copy/Paste.  All three methods must be implemented by the delegate.

//- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(5_0);
//- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender NS_AVAILABLE_IOS(5_0);
//- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender NS_AVAILABLE_IOS(5_0);

//#pragma mark - Focus

//- (BOOL)tableView:(UITableView *)tableView canFocusRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(9_0);
//- (BOOL)tableView:(UITableView *)tableView shouldUpdateFocusInContext:(UITableViewFocusUpdateContext *)context NS_AVAILABLE_IOS(9_0);
//- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator NS_AVAILABLE_IOS(9_0);
//- (nullable NSIndexPath *)indexPathForPreferredFocusedViewInTableView:(UITableView *)tableView NS_AVAILABLE_IOS(9_0);


#pragma mark - UICollectionView


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {  // Called on iOS8+
    // Forward delegate
    if ([self.receiver respondsToSelector:_cmd]) {
        [self.receiver collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
    
    PBRowMapper *item = [self.dataSource rowAtIndexPath:indexPath];
    [item mapData:[collectionView data] forView:cell];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL shouldSelect = YES;
    
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.willSelectActionMapper != nil) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        [self dispatchAction:row.willSelectActionMapper forCell:cell atIndexPath:indexPath];
    }
    
    if ([self.receiver respondsToSelector:_cmd]) {
        shouldSelect = [self.receiver collectionView:collectionView shouldSelectItemAtIndexPath:indexPath];
    }
    
    return shouldSelect;
}

- (void)collectionView:(PBCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.selectActionMapper != nil) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        [self dispatchAction:row.selectActionMapper forCell:cell atIndexPath:indexPath];
    }
    
    collectionView.selectedData = [self.dataSource dataAtIndexPath:indexPath];
    collectionView.selectedIndexPath = indexPath;
    
    if ([self.receiver respondsToSelector:_cmd]) {
        [self.receiver collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL shouldDeselect = YES;
    
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.willDeselectActionMapper != nil) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        [self dispatchAction:row.willDeselectActionMapper forCell:cell atIndexPath:indexPath];
    }
    
    if ([self.receiver respondsToSelector:_cmd]) {
        shouldDeselect = [self.receiver collectionView:collectionView shouldDeselectItemAtIndexPath:indexPath];
    }
    
    return shouldDeselect;
}

- (void)collectionView:(PBCollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PBRowMapper *row = [self.dataSource rowAtIndexPath:indexPath];
    if (row.deselectActionMapper != nil) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        [self dispatchAction:row.deselectActionMapper forCell:cell atIndexPath:indexPath];
    }
    
    collectionView.deselectedData = [self.dataSource dataAtIndexPath:indexPath];
    collectionView.selectedIndexPath = nil;
    
    if ([self.receiver respondsToSelector:_cmd]) {
        [self.receiver collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    PBRowMapper *element = [self.dataSource.sections objectAtIndex:section];
    return [self referenceSizeForCollectionView:collectionView withElementMapper:element];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)theSection {
    PBSectionMapper *section = [self.dataSource.sections objectAtIndex:theSection];
    return [self referenceSizeForCollectionView:collectionView withElementMapper:section.footer];
}

- (CGSize)referenceSizeForCollectionView:(UICollectionView *)collectionView withElementMapper:(PBRowMapper *)element {
    if (element == nil || (element.layout == nil && element.viewClass == [UICollectionReusableView class])) {
        return CGSizeZero;
    }
    return CGSizeMake(collectionView.bounds.size.width, element.height);
}

#pragma mark - UICollectionViewDelegateLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    }
    
    PBSectionMapper *section = [self.dataSource.sections objectAtIndex:indexPath.section];
    PBRowMapper *item = [self.dataSource rowAtIndexPath:indexPath];
    CGFloat itemWidth = item.size.width;
    CGFloat itemHeight = item.size.height;
    if (itemWidth == -1) {
        itemWidth = collectionView.bounds.size.width - section.inset.left - section.inset.right;
    }
    if (itemWidth != 0) {
        return CGSizeMake(itemWidth, itemHeight);
    }
    
    if (section.numberOfColumns != 0) {
        NSInteger numberOfGaps = section.numberOfColumns - 1;
        CGFloat width = (collectionView.bounds.size.width - numberOfGaps * section.inner.width - section.inset.left - section.inset.right) / section.numberOfColumns;
        CGFloat ratio = item.ratio == 0 ? 1 : item.ratio;
        CGFloat height = width / ratio + item.additionalHeight;
        return CGSizeMake(width, height);
    }
    
    return collectionViewLayout.itemSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:section];
    }
    
    if (self.dataSource.sections != nil) {
        PBSectionMapper *mapper = [self.dataSource.sections objectAtIndex:section];
        UIEdgeInsets inset = mapper.inset;
        if (!UIEdgeInsetsEqualToEdgeInsets(inset, UIEdgeInsetsZero)) {
            return inset;
        }
    }
    
    return collectionViewLayout.sectionInset;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
    }
    
    if (self.dataSource.sections != nil) {
        PBSectionMapper *mapper = [self.dataSource.sections objectAtIndex:section];
        CGSize size = mapper.inner;
        if (size.width >= 0) {
            return size.width;
        }
        
        if (mapper.numberOfColumns != 0) {
            PBRowMapper *item = [self.dataSource rowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            if (item.size.width != 0) {
                CGFloat spacing = (collectionView.bounds.size.width - item.size.width * mapper.numberOfColumns - mapper.inset.left - mapper.inset.right) / (mapper.numberOfColumns - 1);
                return spacing;
            }
        }
    }
    
    return collectionViewLayout.minimumInteritemSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
    }
    
    if (self.dataSource.sections != nil) {
        PBSectionMapper *mapper = [self.dataSource.sections objectAtIndex:section];
        CGSize size = mapper.inner;
        if (size.height >= 0) {
            return size.height;
        }
    }
    
    return collectionViewLayout.minimumLineSpacing;
}

#pragma mark - Helper

- (void)_hidesBottomSeparatorForCell:(UITableViewCell *)cell {
    for (UIView *subview in cell.subviews) {
        if (subview == cell.contentView) {
            continue;
        }
        
        subview.alpha = 0;
    }
}

- (void)dispatchAction:(PBActionMapper *)action forCell:(UIView *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = indexPath == nil ? nil : @{@"indexPath": indexPath};
    [[PBActionStore defaultStore] dispatchActionWithActionMapper:action context:cell data:data];
}

@end
