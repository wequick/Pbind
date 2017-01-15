//
//  PBCollectionView.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBDictionary.h"
#import "PBRowMapper.h"
#import "PBMessageInterceptor.h"
#import "PBViewResizingDelegate.h"
#import "PBRowDelegate.h"
#import "PBRowDataSource.h"
#import "PBRowPaging.h"
#import "PBDataFetching.h"

@interface PBCollectionView : UICollectionView <PBRowPaging, PBDataFetching>
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

@property (nonatomic, weak) id<PBViewResizingDelegate> resizingDelegate;

@end
