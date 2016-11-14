//
//  PBCollectionView.h
//  Pbind
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBDictionary.h"
#import "PBRowMapper.h"
#import "PBMessageInterceptor.h"
#import "PBViewResizingDelegate.h"

@interface PBCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    PBRowMapper *_itemMapper;
    Class _registedCellClass;
    
    PBMessageInterceptor *_dataSourceInterceptor;
    PBMessageInterceptor *_delegateInterceptor;
    struct {
        unsigned int deallocing:1;
        unsigned int autoResize:1;
    } _pbCollectionViewFlags;
    
    UIRefreshControl *_refreshControl;
    UITableView *_pullControlWrapper;
    UIRefreshControl *_pullupControl;
    NSTimeInterval _pullupBeginTime;
    NSArray<NSIndexPath *> *_pullupIndexPaths;
}

@property (nonatomic, strong) NSDictionary *item;
@property (nonatomic, strong) NSArray *items;     // PBRowMapper
@property (nonatomic, strong) NSArray *sections; // PBSectionMapper

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) UIEdgeInsets itemInsets;
@property (nonatomic, assign) CGSize spacingSize;

@property (nonatomic, assign, getter=isAutoResize) BOOL autoResize; // auto resize the frame with it's content size, default is NO.

/**
 Scroll the view with horizontal direction.
 */
@property (nonatomic, assign, getter=isHorizontal) BOOL horizontal;

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
 The data of the selected index path.
 */
@property (nonatomic, strong) id selectedData;

/**
 The index path selected by user.
 */
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, weak) id<PBViewResizingDelegate> resizingDelegate;

@end
