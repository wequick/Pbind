//
//  PBScrollView.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBScrollView.h"
#import "PBRowMapper.h"
#import "PBExpression.h"
#import "UIView+Pbind.h"
#import "PBTextView.h"
#import "Pbind+API.h"

@implementation PBScrollView

@synthesize clients, fetching, interrupted, dataUpdated, fetcher;
@synthesize resizingDelegate;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self config];
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self config];
}

- (void)config {
    /* Message interceptor to intercept tableView delegate messages */
    [self initDelegate];
    _pbFlags.needsReloadData = 1;
    _pbFlags.animatedOnRendering = 1;
    _pbFlags.animatedOnValueChanged = 1;
}

- (void)viewDidChangeFrame:(UIView *)view {
    if (_rowViews == nil) {
        return;
    }
    
    NSInteger index = [_rowViews indexOfObject:view];
    if (index == NSNotFound) {
        return;
    }
    
    CGFloat height = [_rowHeights[index] floatValue];
    CGFloat newHeight = view.frame.size.height;
    if (height != newHeight) {
        CGFloat diff = newHeight - height;
        if (newHeight == 0) {
            PBRowMapper *row = [self rowMapperAtIndex:index];
            diff -= row.margin.top + row.padding.top + row.margin.bottom + row.padding.bottom;
        } else if (height == 0) {
            PBRowMapper *row = [self rowMapperAtIndex:index];
            diff += row.margin.top + row.padding.top + row.margin.bottom + row.padding.bottom;
        }
        _rowHeights[index] = @(newHeight);
        
        for (NSInteger rowIndex = index + 1; rowIndex < _rowViews.count; rowIndex++) {
            UIView *rowView = _rowViews[rowIndex];
            if ([_footerViews containsObject:rowView]) {
                continue;
            }
            
            CGRect rowRect = rowView.frame;
            rowRect.origin.y += diff;
            rowView.frame = rowRect;
        }
        
        _contentHeight += diff;
        CGSize size = self.contentSize;
        size.height = _contentHeight;
        [self __adjustContentSize:size];
    }
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

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
    if (_pbFlags.deallocing) {
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

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self initRowViewsIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (_pbFlags.needsReloadData) {
        _pbFlags.needsReloadData = 0;
        [self __reloadData];
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) {
        [self initRowViewsIfNeeded];
        _statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
}

- (NSArray *)pb_mappersForBinding {
    NSMutableArray *mappers = [NSMutableArray array];
    if (_rowMapper != nil) {
        [mappers addObject:_rowMapper];
    }
    if (_rowMappers != nil) {
        [mappers addObjectsFromArray:_rowMappers];
    }
    if (_accessoryMappers != nil) {
        [mappers addObjectsFromArray:_accessoryMappers];
    }
    return mappers;
}

- (void)pb_resetMappers {
    _rowMapper = nil;
    if (_rowMappers != nil) {
        for (PBRowMapper *mapper in _rowMappers) {
            mapper.delegate = nil;
        }
        _rowMappers = nil;
    }
    if (_accessoryMappers != nil) {
        for (PBRowMapper *mapper in _accessoryMappers) {
            mapper.delegate = nil;
        }
        _accessoryMappers = nil;
    }
}

- (void)dealloc
{
    _pbFlags.deallocing = 1;
    [self pb_resetMappers];
    _rowViews = nil;
    _footerViews = nil;
    if (_accessoryViews != nil) {
        for (UIView *view in _accessoryViews) {
            [view removeFromSuperview];
        }
        _accessoryViews = nil;
    }
}

- (UIView *)viewWithRow:(PBRowMapper *)row {
    UIView *view = [row createView];
    if ([view respondsToSelector:@selector(setResizingDelegate:)]) {
        [(id)view setResizingDelegate:self];
    }
    return view;
}

- (void)setRow:(NSDictionary *)row {
    if (_row != nil && _rowViews != nil) {
        [self removeAllViews];
    }
    _row = row;
}

- (void)setRows:(NSArray *)rows {
    if (_rows != nil && _rowViews != nil) {
        [self removeAllViews];
    }
    _rows = rows;
}

- (void)removeAllViews {
    for (UIView *view in _rowViews) {
        [view removeFromSuperview];
    }
    _rowViews = nil;
    _footerViews = nil;
    
    for (UIView *view in _accessoryViews) {
        [view removeFromSuperview];
    }
    _accessoryViews = nil;
    
    [self render:nil];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
}

- (void)initRowViewsIfNeeded
{
    if ([_rowViews count] > 0) {
        [self __adjustFloatingViews];
        return;
    }
    [self initRowViews];
}

- (void)didInitRowViews {
    NSMutableArray *rowHeights = [NSMutableArray arrayWithCapacity:_rowViews.count];
    for (UIView *view in _rowViews) {
        CGFloat h = self.horizontal ? view.frame.size.width : view.frame.size.height;
        [rowHeights addObject:@(h)];
    }
    _rowHeights = rowHeights;
}

- (void)initRowViews
{
    [self initAccessoryViews];
    
    if (_row != nil) {
        _rowMapper = [PBRowMapper mapperWithDictionary:_row owner:self];
        
        if ([self.data isKindOfClass:[NSArray class]]) {
            _footerViews = nil;
            _rowViews = [NSMutableArray arrayWithCapacity:[self.data count]];
            for (id data in self.data) {
                UIView *view = [self viewWithRow:_rowMapper];
                [view setData:data];
                [self addSubview:view];
                [_rowMapper initPropertiesForTarget:view];
                [_rowViews addObject:view];
            }
            
            [self didInitRowViews];
        }
    } else if (_rows != nil) {
        NSMutableArray *mappers = [NSMutableArray arrayWithCapacity:[_rows count]];
        for (NSDictionary *dict in _rows) {
            PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:dict owner:self];
            mapper.delegate = self;
            [mappers addObject:mapper];
        }
        _rowMappers = mappers;
        
        _footerViews = nil;
        _rowViews = [NSMutableArray arrayWithCapacity:[_rowMappers count]];
        for (PBRowMapper *row in _rowMappers) {
            UIView *view = [self viewWithRow:row];
            [self addSubview:view];
            [row initPropertiesForTarget:view];
            [_rowViews addObject:view];
        }
        [self didInitRowViews];
    }
}

- (void)initAccessoryViews {
    if (_accessories != nil && _accessoryMappers == nil) {
        UIView *parentView = self.superview;
        if (parentView == nil) {
            parentView = self.supercontroller.view;
            if (parentView == nil) {
                return;
            }
        }
        
        NSMutableArray *mappers = [NSMutableArray arrayWithCapacity:[_accessories count]];
        for (NSDictionary *dict in _accessories) {
            PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:dict owner:self];
            mapper.delegate = self;
            [mappers addObject:mapper];
        }
        _accessoryMappers = mappers;
        
        NSMutableArray *accessoryViews = [NSMutableArray arrayWithCapacity:[mappers count]];
        for (PBRowMapper *row in mappers) {
            UIView *view = [self viewWithRow:row];
            [parentView addSubview:view];
            [row initPropertiesForTarget:view];
            [accessoryViews addObject:view];
        }
        _accessoryViews = accessoryViews;
    }
}

- (void)render:(NSIndexSet *)indexes {
    id data = self.rootData;
    
    if (self.horizontal) {
        CGFloat x = 0;
        CGFloat y = 0;
        CGFloat h = 0;
        for (NSInteger index = 0; index < [_rowViews count]; index++)  {
            UIView *view = [_rowViews objectAtIndex:index];
            PBRowMapper *row = [self rowMapperAtIndex:index];
            if (indexes == nil || [indexes containsIndex:index]) {
                [row mapPropertiesToTarget:view withData:data owner:view context:self];
            }
            
            BOOL hidden = [row hiddenForView:view withData:data];
            [view setHidden:hidden];
            CGFloat w = 0;
            if (!hidden) {
                w = [row heightForView:view withData:data];
            }
            
            x += row.margin.left + row.padding.left;
            y = row.margin.top + row.padding.top;
            if (w > 0) {
                w -= row.padding.right + row.padding.right;
                w = MAX(w, 0);
            }
            h = self.bounds.size.height - row.margin.top - row.padding.top - row.margin.bottom - row.padding.bottom;
            
            _rowHeights[index] = @(w);
            [view setFrame:CGRectMake(x, y, w, h)];
            x += w + row.margin.right + row.padding.right;
        }
        [self setContentSize:CGSizeMake(x, self.contentSize.height)];
    } else {
        CGFloat x = 0;
        CGFloat y = 0;
        CGFloat w = 0;
        CGFloat hiddenMargin = 0;
        BOOL footerChanged = NO;
        for (NSInteger index = 0; index < [_rowViews count]; index++)  {
            UIView *view = [_rowViews objectAtIndex:index];
            PBRowMapper *row = [self rowMapperAtIndex:index];
            
            BOOL hidden = [row hiddenForView:view withData:data];
            [view setHidden:hidden];
            CGFloat h = 0;
            if (!hidden) {
                h = [row heightForView:view withData:data];
            }
            
            x = row.margin.left + row.padding.left;
            y += row.margin.top + row.padding.top;
            w = self.bounds.size.width - row.margin.left - row.padding.left - row.margin.right - row.padding.right;
            if (h > 0) {
                h -= row.padding.top + row.padding.bottom;
                h = MAX(h, 0);
            }
            BOOL visible = h > 0;
            if (h != 0 && row.floating == PBRowFloatingBottom) {
                if (_footerViews == nil) {
                    _footerViews = [[NSMutableSet alloc] init];
                }
                [_footerViews addObject:view];
                
                footerChanged = YES;
                [view setFrame:CGRectMake(x, 0, w, h)];
                h = 0;
            } else {
                if (hidden) {
                    [view setFrame:CGRectMake(x, y - hiddenMargin, w, view.frame.size.height)];
                } else {
                    [view setFrame:CGRectMake(x, y - hiddenMargin, w, h)];
                }
            }
            _rowHeights[index] = @(view.frame.size.height);
            y += h + row.margin.bottom + row.padding.bottom;
            
            if (!visible) {
                hiddenMargin += row.margin.top + row.padding.top + row.margin.bottom + row.padding.bottom;
                if (view.data == nil && [view respondsToSelector:@selector(reloadData)]) {
                    // Map data
                    [view pb_mapData:data forKey:@"data"];
                    if (view.data != nil) {
                        [(id)view reloadData];
                    }
                }
            } else if (indexes == nil || [indexes containsIndex:index]) {
                // Map data
                [row mapPropertiesToTarget:view withData:data owner:view context:self];
            }
        }
        
        if (footerChanged) {
            [self __adjustFloatingViews];
        }
        
        w = self.contentSize.width;
        if (w == 0) {
            w = self.frame.size.width;
        }
        _contentHeight = y;
        [self __adjustContentSize:CGSizeMake(w, y)];
    }
    
    [self adjustAccessoryViewsOffset];
    [self __adjustContentInset];
}

- (void)adjustAccessoryViewsOffset {
    
}

- (CGFloat)footerHeight {
    CGFloat footerHeight = 0;
    for (UIView *footerView in _footerViews) {
        footerHeight += footerView.frame.size.height;
    }
    for (UIView *footerView in _accessoryViews) {
        footerHeight += footerView.frame.size.height;
    }
    return footerHeight;
}

- (void)__adjustContentInset {
    CGFloat footerHeight = [self footerHeight];
    UIEdgeInsets insets = self.contentInset;
    insets.bottom = footerHeight;
    self.contentInset = insets;
    insets = self.scrollIndicatorInsets;
    insets.bottom = footerHeight;
    self.scrollIndicatorInsets = insets;
}

- (void)__adjustContentSize:(CGSize)contentSize {
    if (_footerViews != nil) {
        contentSize.height = MAX(contentSize.height, self.frame.size.height);
    }
    [self setContentSize:contentSize];
}

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    
    if (self.autoResize) {
        CGRect frame = self.frame;
        if (!CGSizeEqualToSize(frame.size, contentSize)) {
            frame.size = contentSize;
            self.frame = frame;
            if (self.resizingDelegate != nil) {
                [self.resizingDelegate viewDidChangeFrame:self];
            }
        }
    }
}

- (void)reloadData
{
    _pbFlags.needsReloadData = 1;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        dispatch_sync(dispatch_get_main_queue(), ^{
            [self initRowViewsIfNeeded];
            [self setNeedsLayout];
//        });
//    });
}

- (void)__reloadData
{
    BOOL animated = NO;
    if ([_rowViews count] > 0 && self.animatedOnRendering) {
        UIView *aView = [_rowViews firstObject];
        if (aView.frame.size.width > 0) {
            animated = YES;
        }
    }
    dispatch_block_t block = ^(void) {
        [self render:nil];
    };
    if (animated) {
        [UIView animateWithDuration:.25 animations:block];
    } else {
        block();
    }
}

- (PBRowMapper *)rowMapperAtIndex:(NSInteger)index {
    if (_rowMapper != nil) {
        return (id)_rowMapper;
    }
    if (index < 0 || index >= [_rowMappers count]) {
        return nil;
    }
    return [_rowMappers objectAtIndex:index];
}

- (UIView *)viewForRowAtIndex:(NSInteger)index
{
    if (index < 0 || index >= [_rowViews count]) {
        return nil;
    }
    return [_rowViews objectAtIndex:index];
}

- (CGFloat)heightForRowAtIndex:(NSInteger)index
{
    PBRowMapper *row = [_rowMappers objectAtIndex:index];
    UIView *view = [_rowViews objectAtIndex:index];
    return [row heightForView:view withData:self.data];
}

- (NSInteger)indexForRowAtPoint:(CGPoint)point
{
    NSInteger index = NSNotFound;
    NSInteger temp = 0;
    for (; temp < [_rowViews count]; temp++) {
        PBRowMapper *mapper = [self rowMapperAtIndex:temp];
        if (mapper.hidden) {
            continue;
        }
        UIView *view = [_rowViews objectAtIndex:temp];
        CGRect rect = [view convertRect:view.bounds toView:self];
//        NSLog(@"%@ - %@", NSStringFromCGRect(rect), NSStringFromCGPoint(point));
        if (CGRectContainsPoint(rect, point)) {
            index = temp;
            break;
        }
    }
//    NSLog(@"-- %i", (int)index);
    return index;
}

- (NSInteger)indexForView:(UIView *)view
{
    return [_rowViews indexOfObject:view];
}

- (void)reloadRowAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated
{
    [self reloadRowAtIndexes:indexes animated:animated completion:nil];
}

- (void)reloadRowAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    if (animated) {
        [UIView animateWithDuration:.3 animations:^{
            [self _reloadRowAtIndexes:indexes];
        } completion:completion];
    } else {
        [self _reloadRowAtIndexes:indexes];
        if (completion) {
            completion(YES);
        }
    }
}

- (void)_reloadRowAtIndexes:(NSIndexSet *)indexes
{
    [self render:indexes];
}

#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self __adjustFloatingViews];
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [_delegateInterceptor.receiver scrollViewDidScroll:scrollView];
    }
}

#pragma mark - PBRowMapperDelegate

- (void)rowMapper:(PBRowMapper *)mapper didChangeValue:(id)value forKey:(NSString *)key {
    NSInteger index = [_rowMappers indexOfObject:mapper];
    if (index == NSNotFound) {
        index = [_accessoryMappers indexOfObject:mapper];
        if (index == NSNotFound) {
            return;
        }
        [self adjustAccessoryViewsOffset];
        return;
    }
    
    UIView *view = [self viewForRowAtIndex:index];
    if ([key isEqualToString:@"hidden"]) {
        BOOL hidden = mapper.hidden;
        if (hidden != view.hidden) {
            if (hidden) {
                [view endEditing:YES];
            } else {
                // set the height to zero for showing animation
                CGRect frame = view.frame;
                frame.size.height = 0;
                view.frame = frame;
            }
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:index];
            [self reloadRowAtIndexes:indexes animated:self.animatedOnValueChanged completion:^(BOOL finished) {
                if (!hidden) {
                    [self __adjustContentOffsetForReshowView:view];
                }
            }];
        }
    } else if ([key isEqualToString:@"height"]) {
        CGFloat height = [mapper heightForView:view withData:self.data];
        CGFloat viewHeight = view.bounds.size.height;
        if (height != viewHeight) {
            if (height == 0) {
                [view endEditing:YES];
            }
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:index];
            [self reloadRowAtIndexes:indexes animated:self.animatedOnValueChanged completion:^(BOOL finished) {
                if (viewHeight == 0) {
                    [self __adjustContentOffsetForReshowView:view];
                }
            }];
        }
    }
}

#pragma mark - Auto Resizing

- (CGSize)intrinsicContentSize {
    if (self.autoResize) {
        [self layoutIfNeeded];
        return CGSizeMake(UIViewNoIntrinsicMetric, self.contentSize.height);
    }
    return [super intrinsicContentSize];
}

#pragma mark - Properties

- (void)setHorizontal:(BOOL)horizontal {
    _pbFlags.horizontal = horizontal ? 1 : 0;
}

- (BOOL)isHorizontal {
    return (_pbFlags.horizontal == 1);
}

- (void)setAutoResize:(BOOL)autoResize {
    _pbFlags.autoResize = autoResize ? 1 : 0;
}

- (BOOL)isAutoResize {
    return (_pbFlags.autoResize == 1);
}

- (void)setAnimatedOnRendering:(BOOL)animatedOnRendering {
    _pbFlags.animatedOnRendering = animatedOnRendering ? 1 : 0;
}

- (BOOL)isAnimatedOnRendering {
    return (_pbFlags.animatedOnRendering == 1);
}

- (void)setAnimatedOnValueChanged:(BOOL)animatedOnValueChanged {
    _pbFlags.animatedOnValueChanged = animatedOnValueChanged ? 1 : 0;
}

- (BOOL)isAnimatedOnValueChanged {
    return (_pbFlags.animatedOnValueChanged == 1);
}

#pragma mark - Private

- (CGRect)frameForFloatingView:(UIView *)view withBottom:(CGFloat)bottom {
    CGRect frame = [view frame];
    frame.origin.y = bottom - frame.size.height;
    return frame;
}

- (void)__adjustFloatingViews {
    if (_footerViews != nil) {
        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
        NSInteger temp = _rowViews.count;
        for (UIView *footerView in _footerViews) {
            NSInteger index = [_rowViews indexOfObject:footerView];
            if (index == NSNotFound) {
                return;
            }
            
            [indexes addIndex:temp - index];
        }
        __block CGFloat bottom = self.contentOffset.y + self.bounds.size.height;
        if ([[UIApplication sharedApplication] isStatusBarHidden]) {
            bottom -= _statusBarHeight;
        }
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger viewIndex = temp - idx;
            UIView *footerView = [self->_rowViews objectAtIndex:viewIndex];
            CGRect frame = [self frameForFloatingView:footerView withBottom:bottom];
            [footerView setFrame:frame];
            
            bottom -= frame.size.height;
        }];
    }
}

- (void)__adjustContentOffsetForReshowView:(UIView *)reshowView {
    CGRect rect = [reshowView.superview convertRect:reshowView.frame toView:self];
    if (CGRectIntersectsRect(self.bounds, rect)) {
        return;
    }
    
    UIEdgeInsets insets = [self contentInset];
    CGFloat minOffsetY = -insets.top;
    CGFloat maxOffsetY = MAX(minOffsetY, [self contentSize].height + insets.top + insets.bottom - [self bounds].size.height);
    CGPoint offset = [self contentOffset];
    offset.y = MIN(maxOffsetY, reshowView.frame.origin.y);
    [self setContentOffset:offset animated:YES];
}

@end
