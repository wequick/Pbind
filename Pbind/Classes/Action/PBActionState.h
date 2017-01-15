//
//  PBActionState.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBResponse.h"

/**
 This class is used to record the state for the actions running in the action store.
 */
@interface PBActionState : NSObject

#pragma mark - Context
///=============================================================================
/// @name Context
///=============================================================================

/** The view context for the action */
@property (nonatomic, weak) UIView *context;

#pragma mark - Resulting
///=============================================================================
/// @name Resulting
///=============================================================================

/** Whether the action is successfully finished */
@property (nonatomic, assign) BOOL passed;

/** The parameters recorded by the action */
@property (nonatomic, strong) NSDictionary *params;

/** The executing status recorded by the action */
@property (nonatomic, assign) PBResponseStatus status;

/** The executing data recorded by the action */
@property (nonatomic, strong) id data;

/** The executing error recorded by the action */
@property (nonatomic, strong) NSError *error;

#pragma mark - Helper
///=============================================================================
/// @name Helper
///=============================================================================

/**
 Merge parameters with the other dictionay

 @param params the parameters to be merged
 @return a merged parameters
 */
- (NSDictionary *)mergedParams:(NSDictionary *)params;

@end
