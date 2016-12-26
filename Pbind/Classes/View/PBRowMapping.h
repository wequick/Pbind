//
//  PBRowMapping.h
//  Pbind
//
//  Created by Galen Lin on 25/12/2016.
//
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

@end
