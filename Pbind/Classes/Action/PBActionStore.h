//
//  PBActionStore.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/20.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBActionMapper.h"
#import "PBAction.h"

/**
 This class is the root action dispatcher.
 */
@interface PBActionStore : NSObject

#pragma mark - Singleton
///=============================================================================
/// @name Singleton
///=============================================================================

/**
 The default store for dispatching actions configured by Plist

 @return an action store singleton
 */
+ (instancetype)defaultStore;

#pragma mark - Recording
///=============================================================================
/// @name Recording
///=============================================================================

/** The state for the actions running in current action store */
@property (nonatomic, strong) PBActionState *state;

/**
 Dispatch an action.

 @param action the action to be dispatched
 */
- (void)dispatchAction:(PBAction *)action;

/**
 Dispatch an action with initial `context' and `data'.
 
 @param action the action to be dispatched
 @param sender the sender dispatching this `action'
 @param context the context to be stored in current state, all the actions will based on this
 @param data the data to be stored in current state
 */
- (void)dispatchAction:(PBAction *)action sender:(UIView *)sender withContext:(UIView *)context data:(id)data;

/**
 Dispatch an action from action mapper.
 
 @discussion we will create an action from the mapper and dispatch it

 @param mapper the mapper for the action to be created and dispatched
 */
- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper;

/**
 Dispatch an action from action mapper and initialize the context for current state.

 @param mapper the mapper for the action to be created and dispatched
 @param context the context to be stored in current state, all the actions will based on this
 */
- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper context:(UIView *)context;

/**
 Dispatch an action from action mapper and initialize the context for current state.
 
 @param mapper the mapper for the action to be created and dispatched
 @param context the context to be stored in current state, all the actions will based on this
 @param data the data to be stored in current state
 */
- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper context:(UIView *)context data:(id)data;

/**
 Dispatch an action from action mapper and initialize the context for current state.
 
 @param mapper the mapper for the action to be created and dispatched
 @param sender the sender dispatching this action
 @param context the context to be stored in current state, all the actions will based on this
 @param data the data to be stored in current state
 */
- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper sender:(UIView *)sender context:(UIView *)context data:(id)data;

@end

FOUNDATION_EXPORT NSNotificationName const PBActionStoreWillDispatchActionNotification;
FOUNDATION_EXPORT NSNotificationName const PBActionStoreDidDispatchActionNotification;
