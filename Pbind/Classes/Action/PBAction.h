//
//  PBAction.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBDictionary.h"
#import "PBActionState.h"
#import "PBActionMapper.h"

@class PBAction;
@class PBActionStore;

@protocol PBAction <NSObject>

- (void)run:(PBActionState *)state;

@end

/**
 This class define the standard of interactions.
 */
@interface PBAction : NSObject<PBAction>

#pragma mark - Register
///=============================================================================
/// @name Register
///=============================================================================

+ (void)registerType:(NSString *)type;
+ (void)registerTypes:(NSArray *)types;
+ (PBAction *)actionForType:(NSString *)type;
+ (PBAction *)actionWithMapper:(PBActionMapper *)mapper;

#pragma mark - Caching
///=============================================================================
/// @name Caching
///=============================================================================

/** The type for the action to be triggered */
@property (nonatomic, strong) NSString *type;

/** The mapper to update properties at runtime */
@property (nonatomic, strong) PBActionMapper *mapper;

#pragma mark - Triggering
///=============================================================================
/// @name Triggering
///=============================================================================

/** The target of the action */
@property (nonatomic, strong) id target;

/** The name of the action */
@property (nonatomic, strong) NSString *name;

/** The parameters of the action */
@property (nonatomic, strong) NSDictionary *params;

/** Trigger the action after a delay time */
@property (nonatomic, assign) CGFloat delay;

/** Whether doesn't allow the action to be triggered, default is NO */
@property (nonatomic, assign) BOOL disabled;

/** The mappers to create the next actions */
@property (nonatomic, strong) NSDictionary<NSString *, PBAction *> *nextActions;

/** The userInfo directly passed */
@property (nonatomic, strong) NSDictionary *userInfo;

/** The store of current action */
@property (nonatomic, weak) PBActionStore *store;

/**
 Check if has next action with the specified key.

 @param key the key for the next actions
 @return YES if got one
 */
- (BOOL)hasNext:(NSString *)key;

/**
 Dispatch next action if there is.

 @param key the key for the next action
 */
- (void)dispatchNext:(NSString *)key;

@end

#pragma mark - Annotation
///=============================================================================
/// @name Annotation
///=============================================================================

#define pbaction(__type__) \
synthesize type=_type; \
+ (void)load { \
    [self registerType:__type__]; \
}

#define pbactions(...) \
synthesize type=_type; \
+ (void)load { \
    [self registerTypes:@[__VA_ARGS__]]; \
}
