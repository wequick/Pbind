//
//  PBCollectionView.m
//  Pbind
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBCollectionView.h"
#import "PBSection.h"
#import "PBSectionMapper.h"
#import "UIView+Pbind.h"
#import "UIView+PBLayout.h"

@implementation PBCollectionView

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
    _itemMapper = [PBRowMapper mapperWithDictionary:item];
}

- (void)reloadData {
    [super reloadData];
    if (self.data != nil && self.autoResize) {
        CGSize size = self.collectionViewLayout.collectionViewContentSize;
        self.contentSize = size;
        CGRect frame = self.frame;
        frame.size = size;
        self.frame = frame;
        [[NSNotificationCenter defaultCenter] postNotificationName:PBViewDidChangeSizeNotification object:self];
    }
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.data count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
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
        if (item.layout) {
            UIView *view = [UIView viewWithLayout:item.layout bundle:[NSBundle bundleForClass:item.viewClass]];
            [cell.contentView addSubview:view];
        }
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
    PBRowMapper *item = [self itemAtIndexPath:indexPath];
    id data = [self dataAtIndexPath:indexPath];
    [item mapData:data forView:cell];
    
    // Forward delegate
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
        [_delegateInterceptor.receiver collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    PBViewClickHref(cell, cell.href);
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
        [_delegateInterceptor.receiver collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
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
    id _data = self.data;
    if (_data == nil) {
        return nil;
    }
    if ([_data isKindOfClass:[NSArray class]]) {
        return [_data objectAtIndex:indexPath.row];
    } else if ([_data isKindOfClass:[PBSection class]]) {
        return [(PBSection *)_data recordAtIndexPath:indexPath];
    }
    
    return _data;
}

@end
