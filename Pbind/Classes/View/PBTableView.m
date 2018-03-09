//
//  PBTableView.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBTableView.h"
#import "UIView+Pbind.h"
#import "PBSection.h"
#import "PBTableHeaderView.h"
#import "PBTableFooterView.h"
#import "PBArray.h"
#import "PBLayoutMapper.h"
#import "PBViewResizingDelegate.h"
#import "PBActionStore.h"
#import "PBRowDataSource.h"
#import "PBRowDelegate.h"

@interface PBTableView () <PBViewResizingDelegate>

@end

@implementation PBTableView

@synthesize listKey, page, pagingParams, refresh, more;
@synthesize row, rows, section, sections, rowDataSource, rowDelegate, dataCount;
@synthesize selectedIndexPath, editingIndexPath;
@synthesize clients, fetching, interrupted, dataUpdated, fetcher;
@synthesize registeredCellIdentifiers, registeredSectionIdentifiers;
@synthesize resizingDelegate;

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self config];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self config];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    if (self = [super initWithFrame:frame style:style]) {
        [self config];
        
        if (style == UITableViewStyleGrouped) {
            // Zero the section header and footer, so that we can configure each section spacing by PBSectionMapper#height
            [self setSectionHeaderHeight:0];
            [self setSectionFooterHeight:0];
        }
    }
    return self;
}

- (void)config {
    // Init header view
    CGRect frame = CGRectMake(0, 0, self.frame.size.width, CGFLOAT_MIN); // use CGFLOAT_MIN rather than 0 to hide the top section gapping (36px) of the grouped table view.
    PBScrollView *headerView = [[PBTableHeaderView alloc] initWithFrame:frame];
    headerView.autoResize = YES;
    headerView.animatedOnRendering = NO;
    headerView.scrollEnabled = NO;
    headerView.backgroundColor = [UIColor clearColor];
    headerView.resizingDelegate = self;
    self.tableHeaderView = headerView;
    
    // Init footer view
    PBScrollView *footerView = [[PBTableFooterView alloc] initWithFrame:frame];
    footerView.autoResize = YES;
    footerView.animatedOnRendering = NO;
    footerView.scrollEnabled = NO;
    footerView.backgroundColor = [UIColor clearColor];
    footerView.resizingDelegate = self;
    self.tableFooterView = footerView;
    
    /* Message interceptor to intercept tableView dataSource messages */
    [self initDataSource];
    /* Message interceptor to intercept tableView delegate messages */
    [self initDelegate];
    
    _hasRegisteredCellClasses = [[NSMutableArray alloc] init];
}

- (void)viewDidChangeFrame:(UIView *)view {
    if ([view isEqual:self.tableHeaderView]) {
        // Reset the header view to make tableView adjust it's height
        self.tableHeaderView = view;
    } else if ([view isEqual:self.tableFooterView]) {
        // Reset the footer view to make tableView adjust it's height
        self.tableFooterView = view;
    } else if ([view isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self indexPathForCell:(id)view];
        if (indexPath != nil) {
            [self reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
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
    rowDelegate = [[PBRowDelegate alloc] init];
    _delegateInterceptor = [[PBMessageInterceptor alloc] init];
    _delegateInterceptor.middleMan = rowDelegate;
    _delegateInterceptor.receiver = rowDelegate.receiver = self.delegate;
    super.delegate = (id)_delegateInterceptor;
}

- (void)setDataSource:(id<UITableViewDataSource>)dataSource
{
    if (_pbTableViewFlags.deallocing) {
        super.dataSource = nil;
        return;
    }
    
    [self initDataSource];
    
    _dataSourceInterceptor.receiver = rowDataSource.receiver = dataSource;
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    if (_pbTableViewFlags.deallocing) {
        super.delegate = nil;
        return;
    }
    
    [self initDelegate];
    
    _delegateInterceptor.receiver = rowDelegate.receiver = delegate;
}

- (void)setIndexViewHidden:(BOOL)indexViewHidden {
    _pbTableViewFlags.indexViewHidden = indexViewHidden;
    if ([self numberOfSections] != 0) {
        [self reloadSectionIndexTitles];
    }
}

- (BOOL)isIndexViewHidden {
    return _pbTableViewFlags.indexViewHidden;
}

- (void)setHorizontal:(BOOL)horizontal {
    _pbTableViewFlags.horizontal = horizontal;
    if (horizontal) {
        _horizontalFrame = [self frame];
        CGRect bounds = [self bounds];
        CGPoint center = [self center];
        
        [self setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
        
        [super setFrame:CGRectZero];
        [super setCenter:center];
        [super setBounds:bounds];
    } else {
        [self setTransform:CGAffineTransformIdentity];
    }
}

- (BOOL)isHorizontal {
    return _pbTableViewFlags.horizontal;
}

- (void)setDeselectsRowOnReturn:(BOOL)deselectsRowOnReturn {
    _pbTableViewFlags.deselectsRowOnReturn = deselectsRowOnReturn;
}

- (BOOL)isDeselectsRowOnReturn {
    return _pbTableViewFlags.deselectsRowOnReturn;
}

- (void)setHeaders:(NSArray *)headers {
    if ([self.tableHeaderView isKindOfClass:[PBScrollView class]]) {
        [(PBScrollView *)self.tableHeaderView setRows:headers];
    }
}

- (void)setFooters:(NSArray *)footers {
    if ([self.tableFooterView isKindOfClass:[PBScrollView class]]) {
        [(PBScrollView *)self.tableFooterView setRows:footers];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    if (newWindow != nil) {
        if (!_pbTableViewFlags.hasAppear) {
            _pbTableViewFlags.hasAppear = 1;
            UIEdgeInsets i = self.contentInset;
            _initedContentInset = UIEdgeInsetsMake(i.top, i.left, i.bottom, i.right);
        }
    }
}

- (void)didMoveToWindow {
    if (self.window == nil) {
        [super didMoveToWindow];
        return;
    }
    
    [rowDelegate setDataSource:rowDataSource];
    
    [super didMoveToWindow];
    
    // Deselect the row at the selected index path if needed.
    if (!_pbTableViewFlags.deselectsRowOnReturn) {
        return;
    }
    
    UIViewController *vc = [self supercontroller];
    if (vc != vc.navigationController.topViewController) {
        return;
    }
    
    NSIndexPath *theSelectedIndexPath = [self indexPathForSelectedRow];
    if (theSelectedIndexPath == nil) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self deselectRowAtIndexPath:theSelectedIndexPath animated:YES];
    });
}

//- (void)layoutSubviews {
//    [super layoutSubviews]; // *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Auto Layout still required after executing -layoutSubviews. PBTableView's implementation of -layoutSubviews needs to call super.'
//}

- (void)pb_resetMappers {
    [rowDataSource reset];
    [rowDelegate reset];
    [self setHeaders:nil];
    [self setFooters:nil];
}

- (void)reloadData {
    if (![rowDelegate pagingViewCanReloadData:self]) {
        return;
    }
    
    [rowDataSource updateSections];

    if (!self.dataUpdated) {
        return;
    }
    
    if ([self.tableHeaderView isKindOfClass:[PBScrollView class]]) {
        PBScrollView *headerView = (id) self.tableHeaderView;
        [headerView reloadData];
    }
    
    if ([self.tableFooterView isKindOfClass:[PBScrollView class]]) {
        PBScrollView *footerView = (id) self.tableFooterView;
        [footerView reloadData];
    }
    
    [super reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataUpdated = NO;
        if (self.autoResize) {
            [self invalidateIntrinsicContentSize];
            [self setNeedsLayout];
        }
    });
}

- (void)dealloc {
    rowDelegate = nil;
    rowDataSource = nil;
    _dataSourceInterceptor = nil;
    _delegateInterceptor = nil;
    _pbTableViewFlags.deallocing = 1;
}

#pragma mark - Auto Resizing

- (void)setAutoResize:(BOOL)autoResize {
    _pbTableViewFlags.autoResize = autoResize ? 1 : 0;
    self.scrollEnabled = !autoResize;
}

- (BOOL)isAutoResize {
    return (_pbTableViewFlags.autoResize == 1);
}

- (CGSize)intrinsicContentSize {
    if (self.autoResize) {
        [self layoutIfNeeded];
        return CGSizeMake(UIViewNoIntrinsicMetric, self.contentSize.height);
    }
    return [super intrinsicContentSize];
}

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

#pragma mark - RowMapping

- (void)setData:(id)data {
    [super setData:data];
    if ([data isKindOfClass:[NSArray class]]) {
        self.dataCount = [data count];
    }
}

- (void)rowDataSourceDidChange {
    if ([self.data isKindOfClass:[NSArray class]]) {
        self.dataCount = [self.data count];
    }
}

@end
