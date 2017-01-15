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

- (BOOL)shouldRunAfterAction:(PBAction *)action;
- (void)run:(PBActionState *)state;

@end

@interface PBAction : NSObject<PBAction>

+ (void)registerType:(NSString *)type;
+ (void)registerTypes:(NSArray *)types;
+ (PBAction *)actionForType:(NSString *)type;

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) id target;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *params;

@property (nonatomic, assign) BOOL disabled;

@property (nonatomic, strong) NSDictionary *nextMappers;

@property (nonatomic, weak) PBActionStore *store;

- (BOOL)haveNext:(NSString *)key;
- (void)dispatchNext:(NSString *)key;

@end

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
