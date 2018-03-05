//
//  PBCollectionView.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBCollectionView.h"
#import "PBArray.h"
#import "PBExpression.h"
#import "PBSection.h"
#import "PBSectionMapper.h"
#import "UIView+Pbind.h"
#import "PBCollectionViewFlowLayout.h"

@interface PBCollectionView () <PBCollectionViewFlowLayoutDelegate>

@end

@implementation PBCollectionView
{
    PBCollectionViewFlowLayout *_flowLayout;
    UIControl *_valueControl;
}

@synthesize listKey, page, pagingParams, refresh, more;
@synthesize row, rows, section, sections, rowDataSource, rowDelegate;
@synthesize selectedIndexPath, editingIndexPath;
@synthesize clients, fetching, interrupted, dataUpdated, fetcher;
@synthesize registeredCellIdentifiers, registeredSectionIdentifiers;
@synthesize resizingDelegate;

- (instancetype)initWithFrame:(CGRect)frame {
    _flowLayout = [[PBCollectionViewFlowLayout alloc] init];
    _flowLayout.itemSize = CGSizeMake(44, 44);
    _flowLayout.minimumInteritemSpacing = 0;
    _flowLayout.minimumLineSpacing = 0;
    if (self = [super initWithFrame:frame collectionViewLayout:_flowLayout]) {
        [self config];
        _flowLayout.layoutDelegate = self;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
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

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (void)config {
    /* Message interceptor to intercept tableView dataSource messages */
    [self initDataSource];
    /* Message interceptor to intercept tableView delegate messages */
    [self initDelegate];
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    // Default settings
    _spacingSize = CGSizeMake(2, 2);
    _valueControl = [[UIControl alloc] init];
}

- (void)initDataSource {
    if (_dataSourceInterceptor) {
        return;
    }
    rowDataSource = [[PBRowDataSource alloc] init];
    rowDataSource.owner = self;
    _dataSourceInterceptor = [[PBMessageInterceptor alloc] init];
    _dataSourceInterceptor.middleMan = rowDataSource;
    _dataSourceInterceptor.receiver = rowDataSource.receiver = self.dataSource;
    super.dataSource = (id)_dataSourceInterceptor;
}

- (void)initDelegate {
    if (_delegateInterceptor) {
        return;
    }
    rowDelegate = [[PBRowDelegate alloc] initWithDataSource:rowDataSource];
    _delegateInterceptor = [[PBMessageInterceptor alloc] init];
    _delegateInterceptor.middleMan = rowDelegate;
    _delegateInterceptor.receiver = rowDelegate.receiver = self.delegate;
    super.delegate = (id)_delegateInterceptor;
}

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource
{
    if (_pbCollectionViewFlags.deallocing) {
        super.dataSource = nil;
        return;
    }
    
    [self initDataSource];
    
    _dataSourceInterceptor.receiver = rowDataSource.receiver = dataSource;
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    if (_pbCollectionViewFlags.deallocing) {
        super.delegate = nil;
        return;
    }
    
    [self initDelegate];
    
    _delegateInterceptor.receiver = rowDelegate.receiver = delegate;
}

- (void)dealloc {
    rowDelegate = nil;
    rowDataSource = nil;
    _dataSourceInterceptor = nil;
    _delegateInterceptor = nil;
    _pbCollectionViewFlags.deallocing = 1;
}

- (void)reloadData {
    if (![rowDelegate pagingViewCanReloadData:self]) {
        return;
    }
    
    [rowDataSource updateSections];

    if (!self.dataUpdated) {
        return;
    }
    
    [super reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataUpdated = NO;
        [self autoresizeWithAnimated:NO];
    });
}

- (void)pb_didUnbind {
    [super pb_didUnbind];
    
    [rowDataSource reset];
    [rowDelegate reset];
    _selectedData = nil;
    selectedIndexPath = nil;
}

#pragma mark - Properties

- (void)setHorizontal:(BOOL)horizontal {
    UICollectionViewFlowLayout *layout = (id) self.collectionViewLayout;
    layout.scrollDirection = horizontal ? UICollectionViewScrollDirectionHorizontal : UICollectionViewScrollDirectionVertical;
    _horizontal = horizontal;
}

//- (void)setSelectedIndexPath:(NSIndexPath *)theSelectedIndexPath {
//    [self setSelectedIndexPath:theSelectedIndexPath animated:NO];
//}
//
//- (void)setSelectedIndexPath:(NSIndexPath *)theSelectedIndexPath animated:(BOOL)animated {
//    if ([self.rowDataSource dataAtIndexPath:theSelectedIndexPath] == nil) {
//        selectedIndexPath = theSelectedIndexPath;
//        return;
//    }
//    
//    NSArray *selectedIndexPaths = [self indexPathsForSelectedItems];
//    if (selectedIndexPaths.count > 0) {
//        NSIndexPath *indexPath = [selectedIndexPaths firstObject];
//        if (indexPath.section == theSelectedIndexPath.section && indexPath.item == theSelectedIndexPath.item) {
//            // Has selected, this may be triggered by the `didSelectItemAtIndexPath:' method.
//            selectedIndexPath = theSelectedIndexPath;
//            return;
//        }
//    }
//    
//    [self selectItemAtIndexPath:theSelectedIndexPath animated:animated scrollPosition:0];
//}

#pragma mark - Paging

- (void)refreshData {
    [rowDelegate beginRefreshingForPagingView:self];
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

#pragma mark - PBRowDataSource

- (void)setItem:(NSDictionary *)item {
    row = item;
}

- (NSDictionary *)item {
    return row;
}

- (void)setItems:(NSArray *)items {
    rows = items;
}

- (NSArray *)items {
    return rows;
}

- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL))completion {
    [super performBatchUpdates:updates completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
        
        [self autoresizeWithAnimated:YES];
    }];
}

#pragma mark - Auto Resizing

- (void)setAutoResize:(BOOL)autoResize {
    _pbCollectionViewFlags.autoResize = autoResize ? 1 : 0;
}

- (BOOL)isAutoResize {
    return (_pbCollectionViewFlags.autoResize == 1);
}

- (CGSize)intrinsicContentSize {
    if (self.autoResize) {
        [self layoutIfNeeded];
        
        if (self.horizontal) {
            if (self.rowDataSource.sections.count > 0) {
                PBSectionMapper *section = self.rowDataSource.sections.firstObject;
                CGSize itemSize = [self.rowDelegate collectionView:self layout:self.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                return CGSizeMake(UIViewNoIntrinsicMetric, itemSize.height + section.inset.top + section.inset.bottom);
            }
        }
        return CGSizeMake(UIViewNoIntrinsicMetric, self.contentSize.height);
    }
    return [super intrinsicContentSize];
}

- (void)autoresizeWithAnimated:(BOOL)animated {
    if (!self.autoResize) {
        return;
    }
    
    CGSize size = self.collectionViewLayout.collectionViewContentSize;
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return;
    }
    
    self.contentSize = size;
    CGRect frame = self.frame;
    if (frame.size.height != size.height) {
        frame.size.height = size.height;
        dispatch_block_t resizeBlock = ^{
            self.frame = frame;
            if (self.resizingDelegate != nil) {
                [self.resizingDelegate viewDidChangeFrame:self];
            }
        };
        
        if (animated) {
            [UIView animateWithDuration:.25f animations:resizeBlock completion:nil];
        } else {
            resizeBlock();
        }
    }
}

- (void)setAutoItemSizing:(BOOL)autoItemSizing {
    _autoItemSizing = autoItemSizing;
    if (autoItemSizing) {
        _flowLayout.estimatedItemSize = CGSizeMake(1.f, 1.f);
    } else {
        _flowLayout.estimatedItemSize = CGSizeZero;
    }
}

- (void)setEditing:(BOOL)editing {
    if (_editing == editing) {
        return;
    }
    
    _editing = editing;
    
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSUInteger index = 0; index < [self numberOfSections]; index++) {
        [indexes addIndex:index];
    }
    [UIView animateWithDuration:0 animations:^{
        [self performBatchUpdates:^{
            [super reloadSections:indexes];
        } completion:nil];
    }];
}

#pragma mark - PBRowDelegate

- (void)setItemSize:(CGSize)itemSize {
    _flowLayout.itemSize = itemSize;
//    [rowDelegate setItemSize:itemSize];
}

- (void)setItemInsets:(UIEdgeInsets)itemInsets {
    _flowLayout.sectionInset = itemInsets;
//    [rowDelegate setItemInsets:itemInsets];
}

- (void)setSpacingSize:(CGSize)spacingSize {
    _flowLayout.minimumLineSpacing = spacingSize.height;
    _flowLayout.minimumInteritemSpacing = spacingSize.width;
//    [rowDelegate setSpacingSize:spacingSize];
}

#pragma mark - PBCollectionViewFlowLayoutDelegate

- (NSTextAlignment)collectionViewFlowLayout:(PBCollectionViewFlowLayout *)layout alignmentForSectionAtIndex:(NSUInteger)sectionIndex {
    if (rowDataSource == nil) {
        return NSTextAlignmentCenter;
    }
    
    PBSectionMapper *section = rowDataSource.sections[sectionIndex];
    return section.alignment;
}

#pragma mark - Value changed event

- (UIControl *)pb_valueControl {
    return _valueControl;
}

@end
