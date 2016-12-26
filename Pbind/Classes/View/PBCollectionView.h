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
#import "PBRowDelegate.h"
#import "PBRowDataSource.h"
#import "PBRowPaging.h"

@interface PBCollectionView : UICollectionView <PBRowPaging>
{
    PBMessageInterceptor *_dataSourceInterceptor;
    PBMessageInterceptor *_delegateInterceptor;
    PBRowDelegate *_rowDelegate;
    PBRowDataSource *_rowDataSource;
    
    struct {
        unsigned int deallocing:1;
        unsigned int autoResize:1;
    } _pbCollectionViewFlags;
}

@property (nonatomic, strong) NSDictionary *item;
@property (nonatomic, strong) NSArray *items;

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) UIEdgeInsets itemInsets;
@property (nonatomic, assign) CGSize spacingSize;

@property (nonatomic, assign, getter=isAutoResize) BOOL autoResize; // auto resize the frame with it's content size, default is NO.

/**
 Scroll the view with horizontal direction.
 */
@property (nonatomic, assign, getter=isHorizontal) BOOL horizontal;

/**
 The data of the current selected index path.
 */
@property (nonatomic, strong) id selectedData;

/**
 The data of the previous selected index path.
 */
@property (nonatomic, strong) id deselectedData;

/**
 The index path selected by user.
 */
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, weak) id<PBViewResizingDelegate> resizingDelegate;

@end
