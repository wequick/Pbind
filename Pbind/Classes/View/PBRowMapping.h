//
//  PBRowMapping.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 25/12/2016.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBRowDataSource.h"
#import "PBRowDelegate.h"

@protocol PBRowMapping <NSObject>

@required

@property (nonatomic, strong) PBRowDataSource *rowDataSource;
@property (nonatomic, strong) PBRowDelegate *rowDelegate;

@property (nonatomic, strong) NSString *listKey;

@property (nonatomic, strong) NSDictionary *row; // body cell as repeated
@property (nonatomic, strong) NSArray *rows; // array with PBRowMapper for body cells
@property (nonatomic, strong) NSArray *sections; // array with PBSectionMapper for body cells

/**
 The index path selected by user.
 */
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) NSIndexPath *editingIndexPath;

/**
 The registered cell identifier collection.
 
 @discussion This is used for lazy-register reusable cell class by:
 
 - registerNib:forCellWithReuseIdentifier:
 - registerClass:forCellWithReuseIdentifier:
 */
@property (nonatomic, strong) NSMutableArray *registeredCellIdentifiers;

/**
 The registered section(header|footer) identifier collection.
 
 @discussion This is used for lazy-register resuable header|footer view class by:
 
 - registerNib:forSupplementaryViewOfKind:withReuseIdentifier:
 - registerClass:forSupplementaryViewOfKind:withReuseIdentifier:
 */
@property (nonatomic, strong) NSMutableArray *registeredSectionIdentifiers;

@end
