//
//  PBRowDataSource.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 22/12/2016.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

#import "PBMessageInterceptor.h"
#import "PBRowMapper.h"
#import "PBSectionMapper.h"
#import "PBRowControlMapper.h"

@protocol PBRowMapping;

/**
 An instance of PBRowDataSource provides the data for the row in the PBTableView and PBCollectionView.
 */
@interface PBRowDataSource : NSObject <UITableViewDataSource, UICollectionViewDataSource>
{
    NSArray *_sectionIndexTitles;
}

#pragma mark - Context
///=============================================================================
/// @name Context
///=============================================================================

/** The owner of the data source which should confirms to the PBRowMapping protocol */
@property (nonatomic, weak) UIView<PBRowMapping> *owner;

/** The receiver to receive the messages redirecting by the methods of the data source */
@property (nonatomic, weak) id receiver;

#pragma mark - Mapping
///=============================================================================
/// @name Mapping
///=============================================================================

/** The base row mapper used to map the data for all the rows */
@property (nonatomic, strong) PBRowMapper *row;

/** The row mappers used to map the data for the specified rows */
@property (nonatomic, strong) NSArray<PBRowMapper *> *rows;

/** The section mappers used to map the data for the specified sections */
@property (nonatomic, strong) NSArray<PBSectionMapper *> *sections;

/**
 The row mapper at the specified index path

 @param indexPath the index path for the row
 @return a row mapper
 */
- (PBRowMapper *)rowAtIndexPath:(NSIndexPath *)indexPath;

/**
 The row data at the specified index path

 @param indexPath the index path for the row
 @return the data of the row
 */
- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)list;

- (void)reset;

- (void)updateSections;

#pragma mark - for PBRowAction

- (void)addRowData:(id)data;
- (void)deleteRowDataAtIndexPath:(NSIndexPath *)indexPath;

- (void)addRowDatas:(NSArray *)datas;
- (void)appendRowDatas:(NSArray *)datas;

@end

FOUNDATION_EXTERN NSNotificationName const PBRowDataDidChangeNotification;
