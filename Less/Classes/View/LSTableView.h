//
//  LSTableView.h
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSRowMapper.h"
#import "LSSectionMapper.h"
#import "LSMessageInterceptor.h"

//______________________________________________________________________________

@interface LSTableView : UITableView <UITableViewDelegate, UITableViewDataSource>
{
    NSMutableArray *_hasRegisteredCellClasses;
    NSArray *_sectionIndexTitles;
    CGRect _horizontalFrame;
    UIEdgeInsets _initedContentInset;
    LSMessageInterceptor *_dataSourceInterceptor;
    LSMessageInterceptor *_delegateInterceptor;

    struct {
        unsigned int deallocing:1;
        unsigned int hasAppear:1;
        unsigned int refreshing:1;
        unsigned int loadingMore:1;
    } _lsTableViewFlags;
}

/* If client return an array data, use `row' to map data for each cell */
@property (nonatomic, strong) LSRowMapper *row; // body cell as repeated
@property (nonatomic, strong) NSArray *rowsData; // Default is `self.data', for mapping `row'
@property (nonatomic, strong) NSArray *headerRows; // header cells above body cell

/* If client return an dictionary data, use `rows' or `sections' to map data */
@property (nonatomic, strong) NSArray *rows; // array with LSRowMapper for body cells
@property (nonatomic, strong) NSArray *sections; // array with LSSectionMapper for body cells

@property (nonatomic, strong) NSArray *headers; // array with LSRowMapper for header views
@property (nonatomic, strong) NSArray *footers; // array with LSRowMapper for footer views

@property (nonatomic, getter=isIndexViewHidden) BOOL indexViewHidden;
@property (nonatomic, getter=isHorizontal) BOOL horizontal;

@property (nonatomic, strong) id data;

- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

@end

////______________________________________________________________________________
//
//@protocol LSTableViewPagingDelegate <UITableViewDelegate>
//
//- (BOOL)tableView:(UITableView *)tableView allowsFloatForSection:(NSInteger)section;
//
//@end
//
////______________________________________________________________________________
//
//typedef NS_ENUM(NSInteger, LSTableViewPagingState)
//{
//    LSTableViewPagingStateIdle,
//    LSTableViewPagingStatePullDownBegin,
//    LSTableViewPagingStatePullDownMove,
//    LSTableViewPagingStatePullDownEnd,
//    LSTableViewPagingStateRefreshing,
//    
//    LSTableViewPagingStatePullUpBegin,
//    LSTableViewPagingStatePullUpMove,
//    LSTableViewPagingStatePullUpEnd,
//    LSTableViewPagingStateLoadingMore
//};

@interface LSTableView (Paging)

//@property (nonatomic, assign) id<LSTableViewPagingDelegate> pagingDelegate;
@property (nonatomic) NSUInteger numberOfRowsInPage;
//@property (nonatomic, assign) CGFloat refreshingViewHeight;
//@property (nonatomic, assign) CGFloat loadingMoreViewHeight;
//@property (nonatomic, getter=isRefreshingEnabled) BOOL refreshingEnabled;
//@property (nonatomic, getter=isLoadingMoreEnabled) BOOL loadingMoreEnabled;
//
//@property (nonatomic, assign) LSTableViewPagingState pagingState;
//
//@property (nonatomic, assign) NSUInteger rowOffset;
//@property (nonatomic, assign) NSUInteger pageIndex;
//@property (nonatomic, assign) BOOL noMore;

@end
