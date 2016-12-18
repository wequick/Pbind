//
//  PBScrollView.m
//  Pbind
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBScrollView.h"
#import "NSArray+PBUtils.h"
#import "PBRowMapper.h"
#import "PBExpression.h"
#import "UIView+Pbind.h"
#import "PBTextView.h"
#import "Pbind+API.h"

@implementation PBScrollView

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
    if (height != view.frame.size.height) {
        CGFloat diff = view.frame.size.height - height;
        _rowHeights[index] = @(view.frame.size.height);
        
        CGSize size = self.contentSize;
        size.height += diff;
        self.contentSize = size;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChange:) name:UITextViewTextDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    }
}

- (void)dealloc
{
    _pbFlags.deallocing = 1;
    _rowMapper = nil;
    if (_rowMappers != nil) {
        for (PBRowMapper *mapper in _rowMappers) {
            mapper.delegate = nil;
        }
        _rowMappers = nil;
    }
    _rowViews = nil;
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
    [self render:nil];
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
    if (_row != nil) {
        _rowMapper = [PBRowMapper mapperWithDictionary:_row owner:self];
        
        if ([self.data isKindOfClass:[NSArray class]]) {
            _rowViews = [NSMutableArray arrayWithCapacity:[self.data count]];
            for (id data in self.data) {
                UIView *view = [self viewWithRow:_rowMapper];
                [view setData:data];
                [self addSubview:view];
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
        
        _rowViews = [NSMutableArray arrayWithCapacity:[_rowMappers count]];
        for (PBRowMapper *row in _rowMappers) {
            UIView *view = [self viewWithRow:row];
            [self addSubview:view];
            [_rowViews addObject:view];
        }
        [self didInitRowViews];
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
                [row mapData:data forView:view];
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
        for (NSInteger index = 0; index < [_rowViews count]; index++)  {
            UIView *view = [_rowViews objectAtIndex:index];
            PBRowMapper *row = [self rowMapperAtIndex:index];
            if (indexes == nil || [indexes containsIndex:index]) {
                [row mapData:data forView:view];
            }
            
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
            if (h != 0 && row.floating == PBRowFloatingBottom) {
                _footerView = view;
                [view setFrame:CGRectMake(x, self.bounds.size.height - h - row.margin.bottom - row.padding.bottom + self.contentOffset.y, w, h)];
                UIEdgeInsets insets = self.contentInset;
                insets.bottom = h;
                self.contentInset = insets;
                insets = self.scrollIndicatorInsets;
                insets.bottom = h;
                self.scrollIndicatorInsets = insets;
                h = 0;
            } else {
                if (hidden) {
                    [view setFrame:CGRectMake(x, y, w, view.frame.size.height)];
                } else {
                    [view setFrame:CGRectMake(x, y, w, h)];
                }
            }
            _rowHeights[index] = @(view.frame.size.height);
            y += h + row.margin.bottom + row.padding.bottom;
        }
        
        w = self.contentSize.width;
        if (w == 0) {
            w = self.frame.size.width;
        }
        [self setContentSize:CGSizeMake(w, y)];
    }
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
    UIView *view = [self viewForRowAtIndex:index];
    if ([key isEqualToString:@"hidden"]) {
        BOOL hidden = mapper.hidden;
        if (hidden != view.hidden) {
            if (hidden) {
                [view endEditing:YES];
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

#pragma mark - Notification

- (void)textViewDidChange:(NSNotification *)note {
    PBTextView *textView = note.object;
    if (![textView isKindOfClass:[PBTextView class]]) {
        return;
    }
    
//    if (textView.markedTextRange != nil) {
//        return;
//    }
    
    if (![textView isDescendantOfView:self]) {
        return;
    }
    
    CGPoint point = [textView convertPoint:textView.frame.origin toView:self];
    NSInteger row = [self indexForRowAtPoint:point];
    if (row == NSNotFound) {
        return;
    }
    
    PBRowMapper *mapper = [self rowMapperAtIndex:row];
    if (mapper.height != -1) { // TODO: define magic number
        return;
    }
    
    UIView *view = [self viewForRowAtIndex:row];
    CGFloat height = view.frame.size.height;
    CGFloat newHeight = [mapper heightForView:view withData:self.data];
    if (height != newHeight) {
        [textView setMappable:NO forKeyPath:@"text"];
        [self reloadRowAtIndexes:[NSIndexSet indexSetWithIndex:row] animated:NO];
        [textView scrollRangeToVisible:NSMakeRange(0, 1)];
        [textView setMappable:YES forKeyPath:@"text"];
    }
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

- (void)__adjustFloatingViews {
    if (_footerView != nil) {
        CGRect frame = [_footerView frame];
        frame.origin.y = self.contentOffset.y + self.bounds.size.height - frame.size.height;
        if ([[UIApplication sharedApplication] isStatusBarHidden]) {
            frame.origin.y -= _statusBarHeight;
        }
        [_footerView setFrame:frame];
    }
}

- (void)__adjustContentOffsetForReshowView:(UIView *)reshowView {
    UIEdgeInsets insets = [self contentInset];
    CGFloat minOffsetY = -insets.top;
    CGFloat maxOffsetY = MAX(minOffsetY, [self contentSize].height + insets.top + insets.bottom - [self bounds].size.height);
    CGPoint offset = [self contentOffset];
    offset.y = MIN(maxOffsetY, reshowView.frame.origin.y);
    [self setContentOffset:offset animated:YES];
}

@end
