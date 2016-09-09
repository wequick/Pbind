//
//  PBTableView.h
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
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

- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

@end

////______________________________________________________________________________
//
//@protocol PBTableViewPagingDelegate <UITableViewDelegate>
//
//- (BOOL)tableView:(UITableView *)tableView allowsFloatForSection:(NSInteger)section;
//
//@end
//
////______________________________________________________________________________
//
//typedef NS_ENUM(NSInteger, PBTableViewPagingState)
//{
//    PBTableViewPagingStateIdle,
//    PBTableViewPagingStatePullDownBegin,
//    PBTableViewPagingStatePullDownMove,
//    PBTableViewPagingStatePullDownEnd,
//    PBTableViewPagingStateRefreshing,
//    
//    PBTableViewPagingStatePullUpBegin,
//    PBTableViewPagingStatePullUpMove,
//    PBTableViewPagingStatePullUpEnd,
//    PBTableViewPagingStateLoadingMore
//};

@interface PBTableView (Paging)

//@property (nonatomic, assign) id<PBTableViewPagingDelegate> pagingDelegate;
@property (nonatomic) NSUInteger numberOfRowsInPage;
//@property (nonatomic, assign) CGFloat refreshingViewHeight;
//@property (nonatomic, assign) CGFloat loadingMoreViewHeight;
//@property (nonatomic, getter=isRefreshingEnabled) BOOL refreshingEnabled;
//@property (nonatomic, getter=isLoadingMoreEnabled) BOOL loadingMoreEnabled;
//
//@property (nonatomic, assign) PBTableViewPagingState pagingState;
//
//@property (nonatomic, assign) NSUInteger rowOffset;
//@property (nonatomic, assign) NSUInteger pageIndex;
//@property (nonatomic, assign) BOOL noMore;

@end
