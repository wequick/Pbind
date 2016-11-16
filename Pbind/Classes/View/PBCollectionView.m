//
//  PBCollectionView.m
//  Pbind
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBCollectionView.h"
#import "PBArray.h"
#import "PBExpression.h"
#import "PBSection.h"
#import "PBSectionMapper.h"
#import "UIView+Pbind.h"

@interface PBCollectionView () <UIScrollViewDelegate>

@end

@implementation PBCollectionView

static const CGFloat kMinRefreshControlDisplayingTime = .75f;

- (instancetype)initWithFrame:(CGRect)frame {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(44, 44);
    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
        [self config];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self config];
}

- (void)config {
    /* Message interceptor to intercept tableView dataSource messages */
    [self initDataSource];
    /* Message interceptor to intercept tableView delegate messages */
    [self initDelegate];
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    // Default settings
    _spacingSize = CGSizeMake(2, 2);
}

- (void)initDataSource {
    if (_dataSourceInterceptor) {
        return;
    }
    _dataSourceInterceptor = [[PBMessageInterceptor alloc] init];
    _dataSourceInterceptor.middleMan = self;
    if (self.dataSource != self) {
        _dataSourceInterceptor.receiver = self.dataSource;
    }
    super.dataSource = (id)_dataSourceInterceptor;
}

- (void)initDelegate {
    if (_delegateInterceptor) {
        return;
    }
    _delegateInterceptor = [[PBMessageInterceptor alloc] init];
    _delegateInterceptor.middleMan = self;
    if (self.delegate != self) {
        _delegateInterceptor.receiver = self.delegate;
    }
    super.delegate = (id)_delegateInterceptor;
}

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource
{
    if (_pbCollectionViewFlags.deallocing) {
        super.dataSource = nil;
        return;
    }
    
    [self initDataSource];
    if (dataSource != self) {
        super.dataSource = nil;
        _dataSourceInterceptor.receiver = dataSource;
        super.dataSource = (id)_dataSourceInterceptor;
    }
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    if (_pbCollectionViewFlags.deallocing) {
        super.delegate = nil;
        return;
    }
    
    [self initDelegate];
    if (delegate != self) {
        super.delegate = nil;
        _delegateInterceptor.receiver = delegate;
        super.delegate = (id)_delegateInterceptor;
    }
}

- (void)dealloc {
    _dataSourceInterceptor = nil;
    _delegateInterceptor = nil;
    _pbCollectionViewFlags.deallocing = 1;
}

- (void)setItem:(NSDictionary *)item {
    _itemMapper = [PBRowMapper mapperWithDictionary:item owner:self];
}

- (void)reloadData {
    if (_pullupControl.refreshing) {
        NSTimeInterval spentTime = [[NSDate date] timeIntervalSince1970] - _pullupBeginTime;
        if (spentTime < kMinRefreshControlDisplayingTime) {
            NSTimeInterval fakeAwaitingTime = kMinRefreshControlDisplayingTime - spentTime;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fakeAwaitingTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self _endPullup];
            });
        } else {
            [self _endPullup];
        }
    } else {
        [super reloadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.autoResize) {
                CGSize size = self.collectionViewLayout.collectionViewContentSize;
                self.contentSize = size;
                CGRect frame = self.frame;
                frame.size = size;
                self.frame = frame;
                if (self.resizingDelegate != nil) {
                    [self.resizingDelegate viewDidChangeFrame:self];
                }
            }
            
            // Select the item with index path.
            
            BOOL needsSelectedItem = (_selectedIndexPath != nil && [self dataAtIndexPath:_selectedIndexPath] != nil);
            if (!needsSelectedItem) {
                return;
            }
            
            NSArray *selectedIndexPaths = [self indexPathsForSelectedItems];
            BOOL hasSelectedItem = (selectedIndexPaths != nil && [selectedIndexPaths containsObject:_selectedIndexPath]);
            if (hasSelectedItem) {
                return;
            }
            
            [self selectItemAtIndexPath:_selectedIndexPath animated:NO scrollPosition:0];
            [self collectionView:self didSelectItemAtIndexPath:_selectedIndexPath];
        });
    }
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        NSInteger num = [_dataSourceInterceptor.receiver numberOfSectionsInCollectionView:collectionView];
        if (num >= 0) {
            return num;
        }
    }
    
    if ([self.list count] == 0) {
        return 0;
    }
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
        NSInteger num = [_dataSourceInterceptor.receiver collectionView:collectionView numberOfItemsInSection:section];
        if (num > 0) {
            return num;
        }
    }
    
    return [self.list count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(collectionView:cellForItemAtIndexPath:)]) {
        id cell = [_dataSourceInterceptor.receiver cellForItemAtIndexPath:indexPath];
        if (cell != nil) {
            return cell;
        }
    }
    
    PBRowMapper *item = [self itemAtIndexPath:indexPath];
    if (![_registedCellClass isEqual:item.viewClass]) {
        UINib *nib = [UINib nibWithNibName:item.nib bundle:[NSBundle bundleForClass:item.viewClass]];
        if (nib != nil) {
            [collectionView registerNib:nib forCellWithReuseIdentifier:item.id];
        }
        _registedCellClass = item.viewClass;
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:item.id forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[item.viewClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:item.id];
    }
    
    // Init data for cell
    [cell setData:[self dataAtIndexPath:indexPath]];
    [item initDataForView:cell];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Compatible for iOS8-
            [self collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
        });
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {  // Called on iOS8+
    // Forward delegate
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
        [_delegateInterceptor.receiver collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
    
    PBRowMapper *item = [self itemAtIndexPath:indexPath];
    [item mapData:[self data] forView:cell];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    PBViewClickHref(cell, cell.href);
    
    self.selectedData = [self dataAtIndexPath:indexPath];
    
    [self willChangeValueForKey:@"selectedIndexPath"];
    _selectedIndexPath = indexPath;
    [self didChangeValueForKey:@"selectedIndexPath"];
    
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
        [_delegateInterceptor.receiver collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    self.deselectedData = [self dataAtIndexPath:indexPath];
    
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        [_delegateInterceptor.receiver collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
    }
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath {
    [self setSelectedIndexPath:selectedIndexPath animated:NO];
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath animated:(BOOL)animated {
    if ([self dataAtIndexPath:selectedIndexPath] == nil) {
        _selectedIndexPath = selectedIndexPath;
        return;
    }
    
    [self selectItemAtIndexPath:selectedIndexPath animated:animated scrollPosition:0];
}

#pragma mark - UICollectionViewDelegateLayout

- (CGSize)itemSize {
//    if (_numberOfColumns != 0) {
//        
//    } else {
        return _itemSize;
//    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        return [_delegateInterceptor.receiver collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    }
    return [self itemSize];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        return [_delegateInterceptor.receiver collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:section];
    }
    return [self itemInsets];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        return [_delegateInterceptor.receiver collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
    }
    return _spacingSize.width;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        return [_delegateInterceptor.receiver collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
    }
    return _spacingSize.height;
}

#pragma mark - Properties

- (void)setAutoResize:(BOOL)autoResize {
    _pbCollectionViewFlags.autoResize = autoResize ? 1 : 0;
}

- (BOOL)isAutoResize {
    return (_pbCollectionViewFlags.autoResize == 1);
}

- (void)setPagingParams:(PBDictionary *)pagingParams {
    if (_refreshControl == nil) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshControlDidReleased:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:refreshControl];
        _refreshControl = refreshControl;
    }
    _pagingParams = pagingParams;
}

- (void)setHorizontal:(BOOL)horizontal {
    UICollectionViewFlowLayout *layout = (id) self.collectionViewLayout;
    layout.scrollDirection = horizontal ? UICollectionViewScrollDirectionHorizontal : UICollectionViewScrollDirectionVertical;
    _horizontal = horizontal;
}

- (NSArray *)list {
    id data = self.data;
    if ([data isKindOfClass:[PBArray class]]) {
        data = [data list];
    }
    
    if (self.listKey != nil) {
        return [data valueForKey:self.listKey];
    }
    
    return data;
}

#pragma mark - Refresh control

- (void)refreshControlDidReleased:(UIRefreshControl *)sender {
    NSDate *start = [NSDate date];
    
    // Reset paging params
    self.page = 0;
    [self pb_mapData:self.data forKey:@"pagingParams"];
    
    [self pb_pullDataWithPreparation:nil transformation:^id(id data, NSError *error) {
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
        
        return data;
    }];
}

- (void)pullupControlDidReleased:(UIRefreshControl *)sender {
    UIEdgeInsets insets = self.contentInset;
    insets.bottom += _pullupControl.bounds.size.height;
    self.contentInset = insets;
    
    // Increase page
    self.page++;
    [self pb_mapData:self.data forKey:@"pagingParams"];
    
    _pullupBeginTime = [[NSDate date] timeIntervalSince1970];
    [self pb_pullDataWithPreparation:nil transformation:^id(id data, NSError *error) {
        NSInteger prevNumberOfItems = [[self list] count];
        NSInteger currNumberOfItems;
        
        if (self.listKey != nil) {
            NSMutableArray *list = [NSMutableArray arrayWithArray:self.list];
            [list addObjectsFromArray:[data valueForKey:self.listKey]];
            currNumberOfItems = list.count;
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *newData = [NSMutableDictionary dictionaryWithDictionary:data];
                [newData setValue:list forKey:self.listKey];
                data = newData;
            } else {
                [data setValue:list forKey:self.listKey];
            }
        } else {
            NSMutableArray *list = [NSMutableArray arrayWithArray:self.data];
            [list addObjectsFromArray:data];
            currNumberOfItems = list.count;
            data = list;
        }
        
        if (currNumberOfItems > prevNumberOfItems) {
            NSMutableArray *pullupIndexPaths = [NSMutableArray array];
            for (NSInteger item = prevNumberOfItems; item < currNumberOfItems; item++) {
                [pullupIndexPaths addObject:[NSIndexPath indexPathForItem:item inSection:0]];
            }
            _pullupIndexPaths = pullupIndexPaths;
        } else {
            _pullupIndexPaths = nil;
        }
        
        return data;
    }];
}

- (BOOL)view:(UIView *)view shouldLoadRequest:(PBRequest *)request {
    if (self.pagingParams != nil) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:request.params];
        for (NSString *key in self.pagingParams) {
            [params setObject:self.pagingParams[key] forKey:key];
        }
        request.params = params;
    }
    return YES;
}

- (void)_endPullup {
    if (_pullupIndexPaths != nil) {
        [self performBatchUpdates:^{
            [self insertItemsAtIndexPaths:_pullupIndexPaths];
        } completion:^(BOOL finished) {
            _pullupIndexPaths = nil;
            [_pullupControl endRefreshing];
            UIEdgeInsets insets = self.contentInset;
            insets.bottom -= _pullupControl.bounds.size.height;
            self.contentInset = insets;
        }];
    } else {
        [_pullupControl endRefreshing];
        [_pullupControl setEnabled:NO];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [_delegateInterceptor.receiver scrollViewDidScroll:scrollView];
    }
    
    if (self.pagingParams == nil) {
        return;
    }
    
    if (_pullupControl != nil && ![_pullupControl isEnabled]) {
        return;
    }
    
    CGPoint contentOffset = scrollView.contentOffset;
    UIEdgeInsets contentInset = scrollView.contentInset;
    CGFloat height = scrollView.bounds.size.height;
    CGFloat pullupY = (contentOffset.y + contentInset.top + height) - MAX((self.contentSize.height + contentInset.bottom + contentInset.top), height);
    
    if (pullupY > 0) {
        UITableView *wrapper = _pullControlWrapper;
        if (wrapper == nil) {
            wrapper = [[UITableView alloc] initWithFrame:self.frame];
            wrapper.userInteractionEnabled = NO;
            wrapper.backgroundColor = [UIColor clearColor];
            wrapper.separatorStyle = UITableViewCellSeparatorStyleNone;
            wrapper.transform = CGAffineTransformMakeRotation(M_PI);
            _pullupControl = [[UIRefreshControl alloc] init];
            [_pullupControl addTarget:self action:@selector(pullupControlDidReleased:) forControlEvents:UIControlEventValueChanged];
            [wrapper addSubview:_pullupControl];
            _pullControlWrapper = wrapper;
            
            [self.superview insertSubview:_pullControlWrapper aboveSubview:self];
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

#pragma mark - Helper

- (PBRowMapper *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    PBRowMapper *item = _itemMapper;
    if (item == nil) {
        if (self.sections != nil) {
            PBSectionMapper *section = [self.sections objectAtIndex:indexPath.item];
            if (section != nil) {
                item = [section.rows objectAtIndex:indexPath.row];
            }
        } else if (self.items != nil) {
            item = [self.items objectAtIndex:indexPath.row];
        }
        if (item == nil) {
            [NSException raise:@"PBTableViewError" format:@"Missing row spec!"];
        }
    }
    return item;
}

- (id)dataAtIndexPath:(NSIndexPath *)indexPath
{
    id _data = self.list;
    if (_data == nil) {
        return nil;
    }
    if ([_data isKindOfClass:[NSArray class]]) {
        if ([_data count] <= indexPath.row) {
            return nil;
        }
        return [_data objectAtIndex:indexPath.row];
    } else if ([_data isKindOfClass:[PBSection class]]) {
        return [(PBSection *)_data recordAtIndexPath:indexPath];
    }
    
    return _data;
}

@end
