//
//  PBSectionMapper.h
//  Pbind
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PBRowMapper.h"

@interface PBSectionMapper : PBRowMapper

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *rows; // PBRowMapper

/**
 The data for the section.
 */
@property (nonatomic, strong) id data;

/**
 The distinct row mapper for the section.
 */
@property (nonatomic, strong) NSDictionary *row;

/**
 The empty row used to create a placeholder cell to display while the section data is nil.
 */
@property (nonatomic, strong) NSDictionary *emptyRow;

@end
