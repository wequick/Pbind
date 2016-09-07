//
//  LSScrollView.m
//  Less
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSScrollView.h"
#import "NSArray+LSUtils.h"
#import "LSRowMapper.h"
#import "LSExpression.h"
#import "UIView+Less.h"
#import "UIView+LSLayout.h"
#import "LSTextView.h"

@implementation LSScrollView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self config];
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

- (void)awakeFromNib {
    [self config];
}

- (void)config {
    /* Message interceptor to intercept tableView delegate messages */
    [self initDelegate];
    _lsFlags.needsReloadData = 1;
    _lsFlags.animatedOnRendering = 1;
    _lsFlags.animatedOnValueChanged = 1;
    
    // Observe view size changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidChangeSize:) name:LSViewDidChangeSizeNotification object:nil];
}

- (void)viewDidChangeSize:(NSNotification *)note {
    if (_rowViews == nil) {
        return;
    }
    
    UIView *view = note.object;
    NSInteger index = [_rowViews indexOfObject:view];
    if (index == NSNotFound) {
        return;
    }
    
    NSLayoutConstraint *constraint = _heightConstraints[index];
    if (constraint.constant != view.frame.size.height) {
        CGFloat diff = view.frame.size.height - constraint.constant;
        constraint.constant = view.frame.size.height;
        [view setNeedsUpdateConstraints];
        [view setNeedsLayout];
        
        CGSize size = self.contentSize;
        size.height += diff;
        self.contentSize = size;
    }
}

- (void)initDelegate {
    if (_delegateInterceptor) {
        return;
    }
    _delegateInterceptor = [[LSMessageInterceptor alloc] init];
    _delegateInterceptor.middleMan = self;
    if (self.delegate != self) {
        _delegateInterceptor.receiver = self.delegate;
    }
    super.delegate = (id)_delegateInterceptor;
}

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
    if (_lsFlags.deallocing) {
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
    if (_lsFlags.needsReloadData) {
        _lsFlags.needsReloadData = 0;
        [self __reloadData];
    }
}

//- (void)willMoveToWindow:(UIWindow *)newWindow {
//    [super willMoveToWindow:newWindow];
//    if (newWindow != nil) {
//        [self initRowViews];
//    }
//}

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
    _lsFlags.deallocing = 1;
    _rowMapper = nil;
    if (_rowMappers != nil) {
        for (LSRowMapper *mapper in _rowMappers) {
            mapper.delegate = nil;
        }
        _rowMappers = nil;
    }
    _rowViews = nil;
}

- (UIView *)viewWithRow:(LSRowMapper *)row {
    UIView *view;
    NSBundle *bundle = [NSBundle bundleForClass:row.viewClass];
    NSString *nibPath = [bundle pathForResource:row.nib ofType:@"nib"];
    if (nibPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:nibPath]) {
        // Load controller from nib
        view = [[bundle loadNibNamed:row.nib owner:self options:nil] firstObject];
    } else {
//        if ([row.nib rangeOfString:@"UI"].location != 0) {
//            NSLog(@"Missing nib %@ in bundle with identifier %@ (path=%@)", row.nib, [bundle bundleIdentifier], nibPath);
//        }
        view = [[row.viewClass alloc] init];
    }
    [row initDataForView:view];
    return view;
}

//- (void)setData:(id)data {
//    _data = data;
//    [self reloadData];
//}

#if 1

- (void)initRowViewsIfNeeded
{
    if ([_rowViews count] > 0) {
        [self __adjustFloatingViews];
        return;
    }
    [self initRowViews];
}

- (void)initRowViews
{
    if (_row != nil) {
        _rowMapper = [LSRowMapper mapperWithDictionary:_row];
        
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
            LSRowMapper *mapper = [LSRowMapper mapperWithDictionary:dict];
            mapper.delegate = self;
            [mappers addObject:mapper];
        }
        _rowMappers = mappers;
        
        _rowViews = [NSMutableArray arrayWithCapacity:[_rowMappers count]];
        for (LSRowMapper *row in _rowMappers) {
            UIView *view = [self viewWithRow:row];
            [self addSubview:view];
            [_rowViews addObject:view];
        }
        [self didInitRowViews];
    }
}

- (void)didInitRowViews {
    
}

- (void)render:(NSIndexSet *)indexes {
    if (_rowViews == nil) return;
    
    id data = self.rootData;
    
    if (self.horizontal) {
        CGFloat x = 0;
        CGFloat y = 0;
        CGFloat h = 0;
        for (NSInteger index = 0; index < [_rowViews count]; index++)  {
            UIView *view = [_rowViews objectAtIndex:index];
            LSRowMapper *row = [self rowMapperAtIndex:index];
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
            LSRowMapper *row = [self rowMapperAtIndex:index];
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
            if (h != 0 && row.floating == LSRowFloatingBottom) {
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
            y += h + row.margin.bottom + row.padding.bottom;
        }
        
        w = self.contentSize.width;
        if (w == 0) {
            w = self.frame.size.width;
        }
        [self setContentSize:CGSizeMake(w, y)];
        if (self.autoResize) {
            CGRect frame = self.frame;
            [self setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, y)];
        }
    }
}

#else


- (void)initRowViews
{
    if ([_rowViews count] > 0) {
        return;
    }
    
    _wrapperContentView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:_wrapperContentView];
    [_wrapperContentView setUserInteractionEnabled:YES];
    [_wrapperContentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSDictionary *views = @{@"wrapper":_wrapperContentView, @"super":self};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[wrapper(==super)]-0-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[wrapper]-0-|" options:0 metrics:nil views:views]];
    
    // Initialize mapper
    if (self.row != nil) {
        _rowMapper = [LSRowMapper mapperWithDictionary:self.row];
    } else if (self.rows != nil) {
        NSMutableArray *mappers = [NSMutableArray arrayWithCapacity:[self.rows count]];
        for (NSDictionary *dict in self.rows) {
            LSRowMapper *mapper = [LSRowMapper mapperWithDictionary:dict];
            [mappers addObject:mapper];
            [mapper addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
            [mapper addObserver:self forKeyPath:@"height" options:NSKeyValueObservingOptionNew context:nil];
        }
        _rowMappers = mappers;
    }
    
    // Initialize view
    if (_rowMapper != nil && [self.data isKindOfClass:[NSArray class]]) {
        _rowViews = [NSMutableArray arrayWithCapacity:[self.data count]];
        _heightConstraints = [NSMutableArray arrayWithCapacity:[self.data count]];
        for (NSInteger index = 0; index < [self.data count]; index++) {
            id data = [self.data objectAtIndex:index];
            LSRowMapper *row = _rowMapper;
            UIView *view = [self viewWithRow:_rowMapper];
            [view setData:data];
            UIView *superview = _wrapperContentView;
            [superview addSubview:view];
            [_rowViews addObject:view];
            
            /* Auto layout */
            /*-------------*/
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            // width
            NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:0];
            [view addConstraint:heightConstraint];
            [_heightConstraints addObject:heightConstraint];
            // margin-top
            [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1 constant:row.margin.top]];
            // margin-bottom
            [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1 constant:-row.margin.bottom]];
            // margin-left
            if (index == 0) { // relate to superview
                [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1 constant:row.margin.top]];
            } else { // relate to upperview
                UIView *upperView = [_rowViews objectAtIndex:index - 1];
                LSRowMapper *upperRow = row;
                CGFloat marginLeft = MAX(row.margin.top, upperRow.margin.bottom);
                [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:upperView attribute:NSLayoutAttributeRight multiplier:1 constant:marginLeft]];
            }
            // margin-right
            BOOL needsMarginRight = (index == [self.data count] - 1);
            if (needsMarginRight) {
                [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeRight multiplier:1 constant:-row.margin.bottom]];
            }
        }
    } else {
        _rowViews = [NSMutableArray arrayWithCapacity:[_rowMappers count]];
        _heightConstraints = [NSMutableArray arrayWithCapacity:[_rowMappers count]];
        NSInteger indexOfNonfloatView = [_rowMappers count] - 1;
        for (; indexOfNonfloatView >= 0; indexOfNonfloatView--) {
            LSRowMapper *row = [_rowMappers objectAtIndex:indexOfNonfloatView];
            if (row.floating == LSRowFloatingNone) {
                break;
            }
        }
        _footerView = nil;
        for (NSInteger index = 0; index < [_rowMappers count]; index++) {
            LSRowMapper *row = [_rowMappers objectAtIndex:index];
            UIView *view = [self viewWithRow:row];
            UIView *superview = _wrapperContentView;
            [superview addSubview:view];
            [_rowViews addObject:view];
            
            /* Auto layout */
            /*-------------*/
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            BOOL needsMarginBottom = NO;
            // height
            CGFloat h = [row heightForView:view withData:self.data];
            NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:h];
            [view addConstraint:heightConstraint];
            [_heightConstraints addObject:heightConstraint];
            // margin-left
            [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1 constant:row.margin.left]];
            // margin-right
            [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeRight multiplier:1 constant:-row.margin.right]];
            // margin-top
            if (row.floating != LSRowFloatingBottom) {
                if (index == 0) { // relate to superview
                    [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1 constant:row.margin.top]];
                } else { // relate to upperview
                    UIView *upperView = [_rowViews objectAtIndex:index - 1];
                    LSRowMapper *upperRow = [_rowMappers objectAtIndex:index - 1];
                    CGFloat marginTop = MAX(row.margin.top, upperRow.margin.bottom);
                    [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:upperView attribute:NSLayoutAttributeBottom multiplier:1 constant:marginTop]];
                }
                needsMarginBottom = (index == indexOfNonfloatView);
            } else {
                _footerView = view;
                needsMarginBottom = YES;
            }
            // margin-bottom
            if (needsMarginBottom) {
                [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1 constant:-row.margin.bottom]];
            }
        }
        // Floating view
        if (_footerView != nil) {
            [[_footerView superview] bringSubviewToFront:_footerView];
        }
    }
}

- (void)render:(NSIndexSet *)indexes {
    id data = self.rootData;
    if (self.horizontal) {
        for (NSInteger index = 0; index < [_rowViews count]; index++)  {
            if (indexes != nil && ![indexes containsIndex:index]) {
                continue;
            }
            
            UIView *view = [_rowViews objectAtIndex:index];
            LSRowMapper *row = [self rowMapperAtIndex:index];
            BOOL hidden = [row hiddenForView:view withData:self.data];
            [view setHidden:hidden];
            CGFloat w = 0;
            if (!hidden) {
                [row mapData:data forView:view];
                w = [row heightForView:view withData:self.data];
            }
            
            NSLayoutConstraint *heightConstraint = [_heightConstraints objectAtIndex:index];
            heightConstraint.constant = w;
            [view setNeedsUpdateConstraints];
            [view setNeedsLayout];
        }
    } else {
        for (NSInteger index = 0; index < [_rowViews count]; index++)  {
            if (indexes != nil && ![indexes containsIndex:index]) {
                continue;
            }

            UIView *view = [_rowViews objectAtIndex:index];
            LSRowMapper *row = [self rowMapperAtIndex:index];
            BOOL hidden = [row hiddenForView:view withData:data];
            [view setHidden:hidden];
            CGFloat h = 0;
            if (!hidden) {
                [row mapData:data forView:view];
                h = [row heightForView:view withData:data];
            }

            if (h != 0 && row.floating == LSRowFloatingBottom) {
                _footerView = view;
                UIEdgeInsets insets = self.contentInset;
                insets.bottom = h;
                self.contentInset = insets;
                insets = self.scrollIndicatorInsets;
                insets.bottom = h;
                self.scrollIndicatorInsets = insets;
                //                [self scrollViewDidScroll:self];
            }
            
            NSLayoutConstraint *heightConstraint = [_heightConstraints objectAtIndex:index];
            heightConstraint.constant = h;
            [view setNeedsUpdateConstraints];
            [view setNeedsLayout];
        }
    }
    
    [self setContentSize:_wrapperContentView.bounds.size];
}

#endif

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    
    if (self.autoResize) {
        CGRect frame = self.frame;
        frame.size = contentSize;
        self.frame = frame;
        [[NSNotificationCenter defaultCenter] postNotificationName:LSViewDidChangeSizeNotification object:self];
    }
    
}

- (void)reloadData
{
    _lsFlags.needsReloadData = 1;
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

- (LSRowMapper *)rowMapperAtIndex:(NSInteger)index {
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
    LSRowMapper *row = [_rowMappers objectAtIndex:index];
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

#pragma mark - LSRowMapperDelegate

- (void)rowMapper:(LSRowMapper *)mapper didChangeValue:(id)value forKey:(NSString *)key {
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
    LSTextView *textView = note.object;
    if (![textView isKindOfClass:[LSTextView class]]) {
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
    
    LSRowMapper *mapper = [self rowMapperAtIndex:row];
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
    _lsFlags.horizontal = horizontal ? 1 : 0;
}

- (BOOL)isHorizontal {
    return (_lsFlags.horizontal == 1);
}

- (void)setAutoResize:(BOOL)autoResize {
    _lsFlags.autoResize = autoResize ? 1 : 0;
}

- (BOOL)isAutoResize {
    return (_lsFlags.autoResize == 1);
}

- (void)setAnimatedOnRendering:(BOOL)animatedOnRendering {
    _lsFlags.animatedOnRendering = animatedOnRendering ? 1 : 0;
}

- (BOOL)isAnimatedOnRendering {
    return (_lsFlags.animatedOnRendering == 1);
}

- (void)setAnimatedOnValueChanged:(BOOL)animatedOnValueChanged {
    _lsFlags.animatedOnValueChanged = animatedOnValueChanged ? 1 : 0;
}

- (BOOL)isAnimatedOnValueChanged {
    return (_lsFlags.animatedOnValueChanged == 1);
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
    CGFloat maxOffsetY = [self contentSize].height + insets.top + insets.bottom - [self bounds].size.height;
    CGPoint offset = [self contentOffset];
    offset.y = MIN(maxOffsetY, reshowView.frame.origin.y);
    [self setContentOffset:offset animated:YES];
}

@end
