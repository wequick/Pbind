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
#import "PBViewResizing.h"
#import "PBRowDelegate.h"
#import "PBRowDataSource.h"
#import "PBRowPaging.h"
#import "PBDataFetching.h"

/**
 An instance of PBCollectionView displays the collectio data source which can be configured by Plist.
 */
@interface PBCollectionView : UICollectionView <PBRowPaging, PBDataFetching, PBViewResizing>
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

#pragma mark - Datasource
///=============================================================================
/// @name Datasource
///=============================================================================

/** The reusable item for all the sections */
@property (nonatomic, strong) NSDictionary *item;

/** The items for the first section */
@property (nonatomic, strong) NSArray *items;

#pragma mark - Styling
///=============================================================================
/// @name Styling
///=============================================================================

/** The size for all the items in sections */
@property (nonatomic, assign) CGSize itemSize;

/** The insets for all the sections */
@property (nonatomic, assign) UIEdgeInsets itemInsets;

@property (nonatomic, assign) NSInteger numberOfColumns;

/** 
 The spacing size for the items 
 
 @discussion The size is composed of:
 
 - width, the minimum inner item spacing
 - height, the minimum line spacing
 */
@property (nonatomic, assign) CGSize spacingSize;

/**
 Whether scrolls the view in horizontal direction. Default is NO.
 */
@property (nonatomic, assign, getter=isHorizontal) BOOL horizontal;

/**
 The data of the selected item.
 */
@property (nonatomic, strong) id selectedData;

/**
 The data of the previous selected item.
 */
@property (nonatomic, strong) id deselectedData;

@end
