//
//  PBTableView.m
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBTableView.h"
#import "UIView+Pbind.h"
#import "PBSection.h"
#import "PBTableHeaderView.h"
#import "PBTableFooterView.h"
#import "PBArray.h"
#import "PBLayoutMapper.h"
#import "PBViewResizingDelegate.h"

@interface PBTableView () <PBViewResizingDelegate>

@end

@implementation PBTableView

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

- (void)setDataSource:(id<UITableViewDataSource>)dataSource
{
    if (_pbTableViewFlags.deallocing) {
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
    if (_pbTableViewFlags.deallocing) {
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
    [super didMoveToWindow];
    if (self.window == nil) {
        return;
    }
    
    // Deselect the row at the selected index path if needed.
    if (!_pbTableViewFlags.deselectsRowOnReturn) {
        return;
    }
    
    UIViewController *vc = [self supercontroller];
    if (vc != vc.navigationController.topViewController) {
        return;
    }
    
    NSIndexPath *selectedIndexPath = [self indexPathForSelectedRow];
    if (selectedIndexPath == nil) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self deselectRowAtIndexPath:selectedIndexPath animated:YES];
    });
}

- (void)layoutSubviews {
    [super layoutSubviews]; // *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Auto Layout still required after executing -layoutSubviews. PBTableView's implementation of -layoutSubviews needs to call super.'
}

- (void)pb_resetMappers {
    _row = nil;
    _rows = nil;
    _sections = nil;
    [self setHeaders:nil];
    [self setFooters:nil];
}

- (void)reloadData {
    [self initRowMapper];
    
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
        if ([self.tableHeaderView isKindOfClass:[PBScrollView class]]) {
            PBScrollView *headerView = (id) self.tableHeaderView;
            [headerView reloadData];
        }
        
        if ([self.tableFooterView isKindOfClass:[PBScrollView class]]) {
            PBScrollView *footerView = (id) self.tableFooterView;
            [footerView reloadData];
        }
        
        if (_sections != nil) {
            for (PBSectionMapper *mapper in _sections) {
                [mapper updateWithData:self.data andView:nil];
            }
        }
        
        [super reloadData];
    }
}

- (NSDictionary *)_mergeDictionary:(NSDictionary *)oneDictionay with:(NSDictionary *)otherDictionay
{
    NSMutableDictionary *mergedDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *valuesOnlyInOther = [NSMutableDictionary dictionaryWithDictionary:otherDictionay];
    for (NSString *key in oneDictionay) {
        id oneValue = [oneDictionay objectForKey:key];
        id otherValue = [otherDictionay objectForKey:key];
        if (otherValue == nil) {
            otherValue = oneValue;
        } else {
            if ([oneValue isKindOfClass:[NSDictionary class]]) {
                otherValue = [self _mergeDictionary:oneValue with:otherValue];
            }
            [valuesOnlyInOther removeObjectForKey:key];
        }
        [mergedDictionary setObject:otherValue forKey:key];
    }
    [mergedDictionary setValuesForKeysWithDictionary:valuesOnlyInOther];
    return mergedDictionary;
}

- (void)initRowMapper {
    PBRowMapper *row = self.row;
    if ([row isKindOfClass:[PBRowMapper class]]) {
        return;
    }
    
    NSDictionary *rowSource = (id) row;
    
    // Parsing rows: NSArray<NSDictionary> to NSArray<PBRowMapper>
    NSArray *rows = self.rows;
    if ([rows count] > 0) {
        if ([[rows firstObject] isKindOfClass:[PBRowMapper class]]) {
            return;
        }
        
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:[rows count]];
        for (NSInteger index = 0; index < [rows count]; index++) {
            NSDictionary *dict = [rows objectAtIndex:index];
            if (rowSource != nil) {
                // Take the `row' as base mapper
                dict = [self _mergeDictionary:rowSource with:dict];
                self.row = nil; // don't need any more.
            }
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            PBRowMapper *aRow = [self rowWithDictionary:dict indexPath:indexPath];
            [temp addObject:aRow];
        }
        _rows = temp;
        return;
    }
    
    // Parsing sections: NSArray<NSDcitionary> to NSArray<PBSectionMapper>
    NSArray *sections = self.sections;
    if ([sections count] > 0) {
        if ([[sections firstObject] isKindOfClass:[PBSectionMapper class]]) {
            return;
        }
        
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:[sections count]];
        for (NSInteger section = 0; section < [sections count]; section++) {
            NSDictionary *dict = [sections objectAtIndex:section];
            PBSectionMapper *aSection = [PBSectionMapper mapperWithDictionary:dict owner:self];
            NSDictionary *aRowSource = aSection.row;
            
            if ([aSection.rows count] > 0) {
                NSMutableArray *rows = [NSMutableArray arrayWithCapacity:[aSection.rows count]];
                for (NSInteger index = 0; index < [aSection.rows count]; index++) {
                    NSDictionary *dict = [aSection.rows objectAtIndex:index];
                    if (aRowSource != nil) {
                        // Take the `row' as base mapper
                        dict = [self _mergeDictionary:aRowSource with:dict];
                        aSection.row = nil; // don't need any more.
                    }
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:section];
                    PBRowMapper *aRow = [self rowWithDictionary:dict indexPath:indexPath];
                    [rows addObject:aRow];
                }
                aSection.rows = rows;
            } else if (aRowSource != nil) {
                aSection.row = [self rowWithDictionary:aRowSource indexPath:nil];
            }
            
            if (aSection.emptyRow != nil) {
                aSection.emptyRow = [self rowWithDictionary:aSection.emptyRow indexPath:nil];
            }
            
            if (aSection.footer != nil) {
                aSection.footer = [self rowWithDictionary:aSection.footer indexPath:nil];
            }
            [temp addObject:aSection];
        }
        _sections = temp;
        // Init section index titles
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[temp count]];
        BOOL hasTitle = NO;
        for (PBSectionMapper *section in temp) {
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
        return;
    }
    
    if (rowSource != nil) {
        self.row = [PBRowMapper mapperWithDictionary:rowSource owner:self];
    }
    return;
}

- (void)dealloc {
    _dataSourceInterceptor = nil;
    _delegateInterceptor = nil;
    _pbTableViewFlags.deallocing = 1;
}

- (PBRowMapper *)rowWithDictionary:(NSDictionary *)dictionary indexPath:(NSIndexPath *)indexPath
{
    return [PBRowMapper mapperWithDictionary:dictionary owner:self];
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
        if ([self.data isKindOfClass:[PBSection class]]) {
            return [[(PBSection *)self.data sectionIndexTitles] count];
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
        PBSectionMapper *aSection = [self.sections objectAtIndex:section];
        return aSection.title;
    } else if ([self.data isKindOfClass:[PBSection class]]) {
        return [(PBSection *)self.data titleOfSection:section];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
    }
    
    if (self.sections != nil) {
        for (NSInteger index = 0; index < [self.sections count]; index++) {
            PBSectionMapper *section = [self.sections objectAtIndex:index];
            if ([section.title isEqualToString:title]) {
                return index;
            }
        }
    } else if ([self.data isKindOfClass:[PBSection class]]) {
        return [(PBSection *)self.data sectionOfTitle:title];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView heightForHeaderInSection:section];
    }
    
    if (self.sections != nil) {
        PBSectionMapper *aSection = [self.sections objectAtIndex:section];
        CGFloat height = [aSection heightForData:_data];
        if (height >= 0) {
            return height;
        }
        return tableView.sectionHeaderHeight;
    } else if ([self.data isKindOfClass:[PBSection class]]) {
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
    } else if ([self.data isKindOfClass:[PBSection class]]) {
        return [(PBSection *)self.data sectionIndexTitles];
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView viewForHeaderInSection:section];
    }
    
    PBSectionMapper *mapper = [self.sections objectAtIndex:section];
    if (mapper == nil || mapper.viewClass == nil) {
        return nil;
    }
    
    CGRect frame = CGRectMake(0, 0, tableView.bounds.size.width, mapper.height);
    UIView *view = [[mapper.viewClass alloc] initWithFrame:frame];
    [mapper initDataForView:view];
    [mapper mapData:_data forView:view];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = 0;
    if ([_dataSourceInterceptor.receiver respondsToSelector:_cmd]) {
        rowCount = [_dataSourceInterceptor.receiver tableView:tableView numberOfRowsInSection:section];
        if (rowCount >= 0) {
            return rowCount;
        }
    }
    
    if (self.row != nil) {
        // response array
        if ([self.data isKindOfClass:[PBSection class]]) {
            rowCount = [[(PBSection *)self.data recordsInSection:section] count];
        } else {
            rowCount = [[self list] count];
        }
        // header
        if (self.headerRows != nil) {
            rowCount += [self.headerRows count];
        }
    } else if (self.rows != nil) {
        rowCount = [self.rows count];
    } else if (self.sections != nil) {
        PBSectionMapper *aSection = [self.sections objectAtIndex:section];
        rowCount = aSection.rowCount;
    }
    return rowCount;
}

- (NSArray *)list {
    id list = self.data;
    if ([list isKindOfClass:[NSArray class]]) {
        return list;
    }
    
    if ([list isKindOfClass:[PBArray class]]) {
        list = [list list];
    }
    
    if ([list isKindOfClass:[NSArray class]]) {
        return list;
    }
    
    if (self.listKey == nil || ![list isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    list = [list objectForKey:self.listKey];
    return list;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
    }
    
    // Ensure the row mapper has been initialized, cause somethime(calling 'setLayoutMargins' or etc.) we did not called reloadData but trigger 'estimatedHeightForRowAtIndexPath' first.
    [self initRowMapper];
    
    PBRowMapper *row = [self rowAtIndexPath:indexPath];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    
    PBRowMapper *row = [self rowAtIndexPath:indexPath];
    if (row == nil) {
        return tableView.rowHeight;
    }
    
    return [row heightForData:_data rowDataSource:self atIndexPath:indexPath];
}

- (UINib *)nibForRow:(PBRowMapper *)row {
    if (row == nil) {
        return nil;
    }
    
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
    UITableViewCell *cell = nil;
    if ([_dataSourceInterceptor.receiver respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
        cell = [_dataSourceInterceptor.receiver tableView:tableView cellForRowAtIndexPath:indexPath];
        if (cell != nil) {
            return cell;
        }
    }
    
    PBRowMapper *row = [self rowAtIndexPath:indexPath];
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
    
    cell = [tableView dequeueReusableCellWithIdentifier:row.id];
    if (cell == nil) {
        cell = [[row.viewClass alloc] initWithStyle:row.style reuseIdentifier:row.id];
    }
    
    if (row.layout != nil) {
        NSDictionary *dict = PBPlist(row.layout);
        PBLayoutMapper *layout = [PBLayoutMapper mapperWithDictionary:dict owner:nil];
        [layout addtoParent:cell.contentView];
    }
    
    // Default to non-selection
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if ([self isHorizontal]) {
        [cell.contentView setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    }
    
    // Init data for cell
    if (cell.client == nil) {
        [cell setData:[self dataAtIndexPath:indexPath]];
    }
    [row initDataForView:cell];
    [row mapData:_data forView:cell];
    
    return cell;
}

- (void)_hidesBottomSeparatorForCell:(UITableViewCell *)cell {
    for (UIView *subview in cell.subviews) {
        if (subview == cell.contentView) {
            continue;
        }
        
        subview.alpha = 0;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Hides last separator
    if (self.sections.count > indexPath.section) {
        PBSectionMapper *mapper = [self.sections objectAtIndex:indexPath.section];
        if (mapper.hidesLastSeparator && indexPath.row == mapper.rowCount - 1
            && [self dataAtIndexPath:indexPath] != nil) {
            [self _hidesBottomSeparatorForCell:cell];
        }
    }
    
    // Forward delegate
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
        [_delegateInterceptor.receiver tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (self.sections != nil) {
        PBSectionMapper *aSection = [self.sections objectAtIndex:section];
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
    PBViewClickHref(cell, cell.href);
    if ([_delegateInterceptor.receiver respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [_delegateInterceptor.receiver tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView heightForFooterInSection:section];
    }
    
    if (self.sections.count <= section) {
        return 0;
    }
    
    PBSectionMapper *mapper = [self.sections objectAtIndex:section];
    if (mapper.footer == nil) {
        return 0;
    }
    
    PBRowMapper *footerMapper = (id) mapper.footer;
    CGFloat height = [footerMapper heightForData:_data];
    if (height >= 0) {
        return height;
    }
    return tableView.sectionFooterHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
        return [_delegateInterceptor.receiver tableView:tableView viewForFooterInSection:section];
    }
    
    if (self.sections.count <= section) {
        return nil;
    }
    
    PBSectionMapper *mapper = [self.sections objectAtIndex:section];
    if (mapper.footer == nil) {
        return 0;
    }
    
    PBRowMapper *footerMapper = (id) mapper.footer;
    CGRect frame = CGRectMake(0, 0, tableView.bounds.size.width, footerMapper.height);
    UIView *view = [[footerMapper.viewClass alloc] initWithFrame:frame];
    [footerMapper initDataForView:view];
    [footerMapper mapData:_data forView:view];
    return view;
}

- (PBRowMapper *)rowAtIndexPath:(NSIndexPath *)indexPath
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
        PBSectionMapper *section = [self.sections objectAtIndex:indexPath.section];
        if (section != nil) {
            if (section.row != nil) {
                if (section.emptyRow != nil && [self dataAtIndexPath:indexPath] == nil) {
                    return section.emptyRow;
                }
                return section.row;
            }
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
        } else if ([data isKindOfClass:[PBSection class]]) {
            return [(PBSection *)data recordAtIndexPath:indexPath];
        } else {
            return [self list][indexPath.row];
        }
    } else if (self.rows != nil) {
        // Distinct row configured by `rows'
        if ([_data isKindOfClass:[PBArray class]]) {
            return [_data list];
        }
        return _data;
    } else if (self.sections != nil) {
        // Distinct row configured by `sections'
        id data = _data;
        PBSectionMapper *mapper = [self.sections objectAtIndex:indexPath.section];
        if (mapper != nil && mapper.data != nil) {
            data = mapper.data;
        }
        
        if ([data isKindOfClass:[PBArray class]]) {
            data = [data list];
        }
        
        if ([data isKindOfClass:[NSArray class]]) {
            if ([data count] <= indexPath.row) {
                return nil;
            }
            data = [data objectAtIndex:indexPath.row];
        }
        
        return data;
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

#pragma mark - Paging

static const CGFloat kMinRefreshControlDisplayingTime = .75f;

- (void)refresh {
    if (_refreshControl == nil) {
        return;
    }
    
    if (_refreshControl.isRefreshing) {
        return;
    }
    
    CGPoint offset = self.contentOffset;
    offset.y = -self.contentInset.top - _refreshControl.bounds.size.height;
    self.contentOffset = offset;
    [_refreshControl beginRefreshing];
    [_refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([_delegateInterceptor.receiver respondsToSelector:_cmd]) {
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
        if (!self.needsLoadMore) {
            return;
        }
        
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
            
            _needsLoadMore = YES;
            
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

- (void)refreshControlDidReleased:(UIRefreshControl *)sender {
    NSDate *start = [NSDate date];
    
    // Reset paging params
    self.page = 0;
    [self pb_mapData:_data forKey:@"pagingParams"];
    
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
    [self pb_mapData:_data forKey:@"pagingParams"];
    
    _pullupBeginTime = [[NSDate date] timeIntervalSince1970];
    [self pb_pullDataWithPreparation:nil transformation:^id(id data, NSError *error) {
        if (self.listKey != nil) {
            NSMutableArray *list = [NSMutableArray arrayWithArray:self.list];
            [list addObjectsFromArray:[data valueForKey:self.listKey]];
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
            data = list;
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
    [_pullupControl endRefreshing];
    [self reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Adjust content insets
        UIEdgeInsets insets = self.contentInset;
        insets.bottom -= _pullupControl.bounds.size.height;
        self.contentInset = insets;
    });
}
@end
