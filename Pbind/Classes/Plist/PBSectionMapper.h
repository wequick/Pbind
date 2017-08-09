//
//  PBSectionMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PBRowMapper.h"

/**
 An instance of PBSectionMapper stores the configuration of UI section.
 
 @discussion The section here is for PBTableView and PBCollectionView.
 */
@interface PBSectionMapper : PBRowMapper

/** The title for the section header */
@property (nonatomic, strong) NSString *title;

/**
 Hide the last cell's separator view.
 
 @discussion this is only used for a grouped PBTableView. We've done something tricky here:
 In the selector `cellForRowAtIndexPath', we check if the index path is the last row of the section.
 If it is, then find the subview who's frame is bottom to the cell, and set it's alpha to 0.
 */
@property (nonatomic, assign) BOOL hidesLastSeparator;

/**
 The mappers for each row(UITableViewCell) of the section.
 
 @discussion each element will be parsed from NSDictionay to PBRowMapper.
 */
@property (nonatomic, strong) NSArray *rows;

/**
 The data for the section.
 */
@property (nonatomic, strong) id data;

/**
 The distinct row(UITableViewCell) mapper for the section.
 
 @discussion the dictionary here will be parsed to a PBRowMapper.
 */
@property (nonatomic, strong) id row;

/**
 The empty row used to create a placeholder cell to display while the section data is nil.
 
 @discussion the dictionary here will be parsed to a PBRowMapper.
 */
@property (nonatomic, strong) id emptyRow;

/**
 The header view of the section.
 
 @discussion the dictionary here will be parsed to a PBHeaderFooterMapper.
 */
@property (nonatomic, strong) id header;

/**
 The footer view of the section.
 
 @discussion the dictionary here will be parsed to a PBHeaderFooterMapper.
 */
@property (nonatomic, strong) id footer;

/**
 The row count for the section.
 
 @discussion the row count is calculated by following cases:
 
 - If rows was specified, return the rows count
 - If row was specified, return the data count
 - If emptyRow was specified and the data is empty, return 1
 */
@property (nonatomic, assign, readonly) NSInteger rowCount;

#pragma mark - UICollectionView

/**
 The distinct item(UICollectionViewCell) mapper for the section.
 
 @discussion the dictionary here will be parsed to a PBRowMapper.
 */
@property (nonatomic, strong) id item;

/**
 The mappers for each item(UICollectionViewCell) of the section.
 
 @discussion each element will be parsed from NSDictionay to PBRowMapper.
 */
@property (nonatomic, strong) NSArray *items;

/**
 The section inset.
 
 @discussion this is set to following method in the UICollectionViewDelegateLayout delegate:
 
 - collectionView:layout:insetForSectionAtIndex:
 
 */
@property (nonatomic, assign) UIEdgeInsets inset;

/**
 The minimum inter item spacing size.
 
 @discussion this is set to following method in the UICollectionViewDelegateLayout delegate:
 
 - width -> collectionView:layout:minimumInteritemSpacingForSectionAtIndex:
 - height -> collectionView:layout:collectionViewLayoutminimumLineSpacingForSectionAtIndex:
 
 */
@property (nonatomic, assign) CGSize inner;

/**
 The columns count.
 
 @discussion Default is 0. If defined, the item width will be automatically calculated.
 */
@property (nonatomic, assign) NSUInteger numberOfColumns;

@end
