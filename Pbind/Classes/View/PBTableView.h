//
//  PBTableView.h
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBDictionary.h"
#import "PBRowMapper.h"
#import "PBSectionMapper.h"
#import "PBMessageInterceptor.h"

//______________________________________________________________________________

@interface PBTableView : UITableView <UITableViewDelegate, UITableViewDataSource>
{
    NSMutableArray *_hasRegisteredCellClasses;
    NSArray *_sectionIndexTitles;
    CGRect _horizontalFrame;
    UIEdgeInsets _initedContentInset;
    PBMessageInterceptor *_dataSourceInterceptor;
    PBMessageInterceptor *_delegateInterceptor;
    
    UIRefreshControl *_refreshControl;
    UITableView *_pullControlWrapper;
    UIRefreshControl *_pullupControl;
    NSTimeInterval _pullupBeginTime;
    NSArray<NSIndexPath *> *_pullupIndexPaths;

    struct {
        unsigned int deallocing:1;
        unsigned int hasAppear:1;
        unsigned int refreshing:1;
        unsigned int loadingMore:1;
    } _pbTableViewFlags;
}

/* If client return an array data, use `row' to map data for each cell */
@property (nonatomic, strong) PBRowMapper *row; // body cell as repeated
@property (nonatomic, strong) NSArray *rowsData; // Default is `self.data', for mapping `row'
@property (nonatomic, strong) NSArray *headerRows; // header cells above body cell

/* If client return an dictionary data, use `rows' or `sections' to map data */
@property (nonatomic, strong) NSArray *rows; // array with PBRowMapper for body cells
@property (nonatomic, strong) NSArray *sections; // array with PBSectionMapper for body cells

@property (nonatomic, strong) NSArray *headers; // array with PBRowMapper for header views
@property (nonatomic, strong) NSArray *footers; // array with PBRowMapper for footer views

@property (nonatomic, getter=isIndexViewHidden) BOOL indexViewHidden;
@property (nonatomic, getter=isHorizontal) BOOL horizontal;

@property (nonatomic, strong) id data;

/**
 The key used to get the list from `self.data` for display.
 */
@property (nonatomic, strong) NSString *listKey;

/**
 The params used to paging, usually as {page: .page+1, pageSize: 10} or {offset: .page*10, limit: 10}.
 If was set, will automatically add a `_refreshControl` for `pull-down-to-refresh`
 and a `_pullupControl` for `pull-up-to-load-more`.
 */
@property (nonatomic, strong) PBDictionary *pagingParams;

/**
 The loading page count, default is 0.
 While `_pullupControl` released, the value will be increased by 1.
 */
@property (nonatomic, assign) NSInteger page;

/**
 Re-fetch data with the initial paging parameters and reload the table view.
 */
- (void)refresh;

- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

@end
