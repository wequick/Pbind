//
//  PBActionMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBMapper.h"
#import "PBDictionary.h"

/**
 This class is used to create a PBAction and map data to it.
 */
@interface PBActionMapper : PBMapper

#pragma mark - Creating
///=============================================================================
/// @name Creating
///=============================================================================

/** The type for the action */
@property (nonatomic, strong) NSString *type;

#pragma mark - Mapping
///=============================================================================
/// @name Mapping
///=============================================================================

/** The next actions dictionary to be parsed as mappers */
//mapping @property (nonatomic, strong) NSDictionary *next;

/** The expression to map as a target for the action */
//mapping @property (nonatomic, strong) NSString *target;

/** The name for the action */
//mapping @property (nonatomic, strong) NSString *name;

/** The parameters for the action */
//mapping @property (nonatomic, strong) NSDictionary *params;

/** The expression to map as disabled for the action */
//mapping @property (nonatomic, assign) BOOL disabled;


@end
