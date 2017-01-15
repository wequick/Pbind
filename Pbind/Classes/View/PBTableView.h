//
//  PBTableView.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBDictionary.h"
#import "PBRowMapper.h"
#import "PBSectionMapper.h"
#import "PBMessageInterceptor.h"
#import "PBRowDelegate.h"
#import "PBRowDataSource.h"
#import "PBRowPaging.h"
#import "PBDataFetching.h"

//______________________________________________________________________________

@interface PBTableView : UITableView <PBRowPaging, PBDataFetching>
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

    struct {
        unsigned int deallocing:1;
        unsigned int hasAppear:1;
        unsigned int refreshing:1;
        unsigned int loadingMore:1;
        unsigned int horizontal:1;
        unsigned int indexViewHidden:1;
        unsigned int deselectsRowOnReturn:1;
    } _pbTableViewFlags;
}

@property (nonatomic, strong) NSArray *headers; // array with PBRowMapper for header views
@property (nonatomic, strong) NSArray *footers; // array with PBRowMapper for footer views

@property (nonatomic, getter=isIndexViewHidden) BOOL indexViewHidden;
@property (nonatomic, getter=isHorizontal) BOOL horizontal;

/**
 If we'd push a controller by selected a row, then while it return, we maybe needs to deselects the row.
 */
@property (nonatomic, getter=isDeselectsRowOnReturn) BOOL deselectsRowOnReturn;

@property (nonatomic, strong) id data;

@end
