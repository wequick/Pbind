//
//  LSTableView.m
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSTableView.h"
#import "UIView+Less.h"
#import "UIView+LSLayout.h"
#import "LSSection.h"
#import "LSScrollView.h"
#import "LSArray.h"

@implementation LSTableView

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
            // Zero the section header and footer, so that we can configure each section spacing by LSSectionMapper#height
            [self setSectionHeaderHeight:0];
            [self setSectionFooterHeight:0];
        }
    }
    return self;
}

- (void)config {
    // Init header view
    CGRect frame = CGRectMake(0, 0, self.frame.size.width, CGFLOAT_MIN); // use CGFLOAT_MIN rather than 0 to hide the top section gapping (36px) of the grouped table view.
    LSScrollView *headerView = [[LSScrollView alloc] initWithFrame:frame];
    headerView.autoResize = YES;
    headerView.animatedOnRendering = NO;
    headerView.scrollEnabled = NO;
    headerView.backgroundColor = [UIColor clearColor];
    self.tableHeaderView = headerView;
    // Observe the header view size changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidChangeSize:) name:LSViewDidChangeSizeNotification object:nil];
    
    // Init footer view
    frame.size.height = 0;
    LSScrollView *footerView = [[LSScrollView alloc] initWithFrame:frame];
    footerView.autoResize = YES;
    footerView.animatedOnRendering = NO;
    footerView.scrollEnabled = NO;
    footerView.backgroundColor = [UIColor clearColor];
    self.tableFooterView = footerView;
    
    /* Message interceptor to intercept tableView dataSource messages */
    [self initDataSource];
    /* Message interceptor to intercept tableView delegate messages */
    [self initDelegate];
    
    _hasRegisteredCellClasses = [[NSMutableArray alloc] init];
}

- (void)viewDidChangeSize:(NSNotification *)note {
    UIView *view = note.object;
    if ([view isEqual:self.tableHeaderView]) {
        // Reset the header view to make tableView adjust it's height
        self.tableHeaderView = view;
        return;
    }
    
    if ([view isKindOfClass:[UITableViewCell class]]) {
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
    _dataSourceInterceptor = [[LSMessageInterceptor alloc] init];
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
    _delegateInterceptor = [[LSMessageInterceptor alloc] init];
    _delegateInterceptor.middleMan = self;
    if (self.delegate != self) {
        _delegateInterceptor.receiver = self.delegate;
    }
    super.delegate = (id)_delegateInterceptor;
}

- (void)setDataSource:(id<UITableViewDataSource>)dataSource
{
    if (_lsTableViewFlags.deallocing) {
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

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    if (_lsTableViewFlags.deallocing) {
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

- (void)setIndexViewHidden:(BOOL)indexViewHidden {
    _indexViewHidden = indexViewHidden;
    if ([self numberOfSections] != 0) {
        [self reloadSectionIndexTitles];
    }
}

- (void)setHorizontal:(BOOL)horizontal {
    _horizontal = horizontal;
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

- (void)setHeaders:(NSArray *)headers {
    if ([self.tableHeaderView isKindOfClass:[LSScrollView class]]) {
        [(LSScrollView *)self.tableHeaderView setRows:headers];
    }
}

- (void)setFooters:(NSArray *)footers {
    if ([self.tableFooterView isKindOfClass:[LSScrollView class]]) {
        [(LSScrollView *)self.tableFooterView setRows:footers];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    if (newWindow != nil) {
        if (!_lsTableViewFlags.hasAppear) {
            _lsTableViewFlags.hasAppear = 1;
            UIEdgeInsets i = self.contentInset;
            _initedContentInset = UIEdgeInsetsMake(i.top, i.left, i.bottom, i.right);
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews]; // *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Auto Layout still required after executing -layoutSubviews. LSTableView's implementation of -layoutSubviews needs to call super.'
}

- (void)reloadData {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([self.tableHeaderView isKindOfClass:[LSScrollView class]]) {
                LSScrollView *headerView = (id) self.tableHeaderView;
//                [headerView setData:self.data];
                [headerView setNeedsLoad:YES];
            } else {
                CGRect frame = self.tableHeaderView.frame;
                frame.size.height = 100;
                self.tableHeaderView.frame = frame;
            }
            
            if ([self.tableFooterView isKindOfClass:[LSScrollView class]]) {
                LSScrollView *footerView = (id) self.tableFooterView;
//                [footerView setData:self.data];
                [footerView setNeedsLoad:YES];
            }
            
            [super reloadData];

        });
    });
}

- (void)dealloc {
    _dataSourceInterceptor = nil;
    _delegateInterceptor = nil;
    _lsTableViewFlags.deallocing = 1;
}

- (LSRowMapper *)rowWithDictionary:(NSDictionary *)dictionary indexPath:(NSIndexPath *)indexPath
{
    return [LSRowMapper mapperWithDictionary:dictionary];
}

- (void)setRow:(LSRowMapper *)row
{
    if ([row isKindOfClass:[NSDictionary class]]) {
        row = [LSRowMapper mapperWithDictionary:(id)row];
    }
    _row = row;
}

- (void)setRows:(NSArray *)rows
{
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:[rows count]];
    for (NSInteger row = 0; row < [rows count]; row++) {
        NSDictionary *dict = [rows objectAtIndex:row];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        LSRowMapper *aRow = [self rowWithDictionary:dict indexPath:indexPath];
        [temp addObject:aRow];
    }
    _rows = temp;
}

- (void)setSections:(NSArray *)sections
{
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:[sections count]];
    for (NSInteger section = 0; section < [sections count]; section++) {
        NSDictionary *dict = [sections objectAtIndex:section];
        LSSectionMapper *aSection = [LSSectionMapper mapperWithDictionary:dict];
        NSMutableArray *rows = [NSMutableArray arrayWithCapacity:[aSection.rows count]];
        for (NSInteger row = 0; row < [aSection.rows count]; row++) {
            NSDictionary *rowDict = [aSection.rows objectAtIndex:row];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            LSRowMapper *aRow = [self rowWithDictionary:rowDict indexPath:indexPath];
            [rows addObject:aRow];
        }
        aSection.rows = rows;
        [temp addObject:aSection];
    }
    _sections = temp;
    // Init section index titles
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[temp count]];
    BOOL hasTitle = NO;
    for (LSSectionMapper *section in temp) {
        NSString *title;
        if (section.title == nil) {
            title = @"";
        } else {
            title = [section.title substringToIndex:1];
            hasTitle = YES;
        }
        [titles addObject:title];
    }
    if (hasTitle) {
        _sectionIndexTitles = titles;
    }
}

//___________________________________________________________________________________________________
// Delegate

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver numberOfSectionsInTableView:tableView];
    }
    
    if (self.sections != nil) {
        return [self.sections count];
    } else if (self.row != nil || self.rows != nil) {
        if ([self.data isKindOfClass:[LSSection class]]) {
            return [[(LSSection *)self.data sectionIndexTitles] count];
        }
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView titleForHeaderInSection:section];
    }
    
    if (self.sections != nil) {
        LSSectionMapper *aSection = [self.sections objectAtIndex:section];
        return aSection.title;
    } else if ([self.data isKindOfClass:[LSSection class]]) {
        return [(LSSection *)self.data titleOfSection:section];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
    }
    
    if (self.sections != nil) {
        for (NSInteger index = 0; index < [self.sections count]; index++) {
            LSSectionMapper *section = [self.sections objectAtIndex:index];
            if ([section.title isEqualToString:title]) {
                return index;
            }
        }
    } else if ([self.data isKindOfClass:[LSSection class]]) {
        return [(LSSection *)self.data sectionOfTitle:title];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView heightForHeaderInSection:section];
    }
    
    if (self.sections != nil) {
        LSSectionMapper *aSection = [self.sections objectAtIndex:section];
//        if (aSection.height != nil) {
            // FIXME: map for height
//            return [aSection.height floatValue];
//        }
        if (aSection.height != 0) {
            return aSection.height;
        }
        return tableView.sectionHeaderHeight;
    } else if ([self.data isKindOfClass:[LSSection class]]) {
        return tableView.sectionHeaderHeight;
    } else if (self.row != nil || self.rows != nil) {
        return 0;
    }
    
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        return tableView.sectionHeaderHeight;
    }
    return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver sectionIndexTitlesForTableView:tableView];
    }
    
    if (self.indexViewHidden) {
        return nil;
    }
    if (self.sections) {
        return _sectionIndexTitles;
    } else if ([self.data isKindOfClass:[LSSection class]]) {
        return [(LSSection *)self.data sectionIndexTitles];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView numberOfRowsInSection:section];
    }
    
    NSInteger rowCount = 0;
    if (self.row != nil) {
        // response array
        if ([self.data isKindOfClass:[LSSection class]]) {
            rowCount = [[(LSSection *)self.data recordsInSection:section] count];
        } else if ([self.data isKindOfClass:[LSArray class]]) {
            rowCount = [[self.data list] count];
        } else {
            rowCount = [self.data count];
        }
        // header
        if (self.headerRows != nil) {
            rowCount += [self.headerRows count];
        }
    } else if (self.rows != nil) {
        rowCount = [self.rows count];
    } else if (self.sections != nil) {
        LSSectionMapper *aSection = [self.sections objectAtIndex:section];
        rowCount = [aSection.rows count];
    }
    return rowCount;
}

//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
//        return [_delegateInterceptor.receiver tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
//    }
//    
//    LSRowMapper *row = [self rowAtIndexPath:indexPath];
//    if (row == nil) {
//        return tableView.rowHeight;
//    }
//    
//    id data = [self dataAtIndexPath:indexPath];
//    NSDictionary *fakeView = nil;
//    if (data != nil) {
//        fakeView = @{@"data":data}; // for `$$' to map to view.data
//    }
//    BOOL hidden = [row hiddenForView:fakeView withData:self.data];
//    if (hidden) {
//        return 0;
//    }
//    
//    if (row.height != 0) {
//        return row.height;
//    }
//    return tableView.rowHeight;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    
    LSRowMapper *row = [self rowAtIndexPath:indexPath];
    if (row == nil) {
        return tableView.rowHeight;
    }
    
    id data = [self dataAtIndexPath:indexPath];
    NSDictionary *fakeView = nil;
    if (data != nil) {
        fakeView = @{@"data":data}; // for `$$' to map to view.data
    }
    BOOL hidden = [row hiddenForView:fakeView withData:self.data];
    if (hidden) {
        return 0;
    }
    
    if (row.height != 0) {
        return row.height;
//        return [row heightForView:fakeView withData:self.data];
    }
    return tableView.rowHeight;
}

- (UINib *)nibForRow:(LSRowMapper *)row {
    // TODO: Add a patch bundle
    NSArray *bundles = @[[NSBundle bundleForClass:row.viewClass],
                         [NSBundle bundleForClass:self.supercontroller.class],
                         /* patch bundle */];
    for (NSBundle *bundle in bundles) {
        if ([bundle pathForResource:row.nib ofType:@"nib"] != nil) {
            return [UINib nibWithNibName:row.nib bundle:bundle];
        }
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
        return [_delegateInterceptor.receiver tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    LSRowMapper *row = [self rowAtIndexPath:indexPath];
    NSString *cellClazz = NSStringFromClass(row.viewClass);
    if (row.viewClass != [UITableViewCell class] && ![_hasRegisteredCellClasses containsObject:cellClazz]) {
        // Lazy register reusable cell
        UINib *nib = [self nibForRow:row];
        if (nib != nil) {
            [tableView registerNib:nib forCellReuseIdentifier:row.id];
        } else {
            [tableView registerClass:row.viewClass forCellReuseIdentifier:row.id];
        }
        [_hasRegisteredCellClasses addObject:cellClazz];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:row.id];
    if (cell == nil) {
        cell = [[row.viewClass alloc] initWithStyle:row.style reuseIdentifier:row.id];
        if (row.layout) {
            UIView *view = [UIView viewWithLayout:row.layout bundle:[NSBundle bundleForClass:row.viewClass]];
            [cell.contentView addSubview:view];
        }
        
        // Default to non-selection
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    if ([self isHorizontal]) {
        [cell.contentView setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    }
    
    // Init data for cell
    if (cell.client == nil) {
        [cell setData:[self dataAtIndexPath:indexPath]];
    }
    [row initDataForView:cell];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL blur = [[tableView valueForAdditionKey:@"__blur"] boolValue];
    if (blur) {
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    LSRowMapper *row = [self rowAtIndexPath:indexPath];
//    id data = [self dataAtIndexPath:indexPath];
    [row mapData:_data forView:cell];
    
    // Forward delegate
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
        [_delegateInterceptor.receiver tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (self.sections != nil) {
        LSSectionMapper *aSection = [self.sections objectAtIndex:section];
        [aSection initDataForView:view];
        [aSection mapData:self.data forView:view];
    }
    
    // Forward delegate
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        [_delegateInterceptor.receiver tableView:tableView willDisplayHeaderView:view forSection:section];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    LSViewClickHref(cell, cell.href);
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [_delegateInterceptor.receiver tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (LSRowMapper *)rowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.row != nil) {
        // Distinct row configured by `headerRows'
        if (self.headerRows != nil && indexPath.row < self.headerRows.count) {
            return [self.headerRows objectAtIndex:indexPath.row];
        }
        // Repeated row
        return self.row;
    } else if (self.rows != nil) {
        // Distinct row configured by `rows'
        return [self.rows objectAtIndex:indexPath.row];
    } else if (self.sections != nil) {
        // Distinct row configured by `sections'
        LSSectionMapper *section = [self.sections objectAtIndex:indexPath.section];
        if (section != nil) {
            return [section.rows objectAtIndex:indexPath.row];
        }
    }
    return nil;
}

- (id)dataAtIndexPath:(NSIndexPath *)indexPath
{
    if (_data == nil) {
        return nil;
    }
    
    if (self.row != nil) {
        // Distinct row configured by `headerRows'
        if (self.headerRows != nil && indexPath.row < self.headerRows.count) {
            return _data;
        }
        // Repeated row
        id data = self.rowsData ?: _data;
        if ([data isKindOfClass:[NSArray class]]) {
            return [data objectAtIndex:indexPath.row];
        } else if ([data isKindOfClass:[LSArray class]]) {
            return [data list][indexPath.row];
        } else if ([data isKindOfClass:[LSSection class]]) {
            return [(LSSection *)data recordAtIndexPath:indexPath];
        }
    } else if (self.rows != nil) {
        // Distinct row configured by `rows'
        if ([_data isKindOfClass:[LSArray class]]) {
            return [_data list];
        }
        return _data;
    } else if (self.sections != nil) {
        // Distinct row configured by `sections'
        if ([_data isKindOfClass:[LSArray class]]) {
            return [_data list];
        }
        return _data;
    }
    
    return nil;
}

#pragma mark - Track

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [_delegateInterceptor.receiver scrollViewDidScrollToTop:scrollView];
    }
    // for subclass to implement
}

@end
