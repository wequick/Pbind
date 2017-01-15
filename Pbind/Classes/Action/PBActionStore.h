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

@interface PBActionStore : NSObject

+ (instancetype)defaultStore;

@property (nonatomic, strong) PBActionState *state;

- (void)dispatchAction:(PBAction *)action;

- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper;
- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper context:(UIView *)context;

@end
