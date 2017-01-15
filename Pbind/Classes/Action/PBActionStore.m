//
//  PBActionStore.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/20.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBActionStore.h"
#import "UIView+Pbind.h"
#import "PBVariableMapper.h"

@implementation PBActionStore

+ (instancetype)defaultStore {
    static PBActionStore *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PBActionStore alloc] init];
    });
    return instance;
}

- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper {
    [self dispatchActionWithActionMapper:mapper context:nil];
}

- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper context:(UIView *)context {
    [mapper updateWithData:context.rootData andView:context];
    PBAction *action = [PBAction actionForType:mapper.type];
    if (action == nil) {
        return;
    }
    
    if (self.state == nil) {
        self.state = [[PBActionState alloc] init];
    }
    if (context != nil) {
        self.state.context = context;
    }
    
    action.type = mapper.type;
    action.disabled = mapper.disabled;
    action.target = mapper.target;
    action.name = mapper.name;
    action.params = mapper.params;
    action.nextMappers = mapper.nextMappers;
    action.store = self;
    
    [self dispatchAction:action];
}

- (void)dispatchAction:(PBAction *)action {
    if (action.disabled) {
        return;
    }
    
    [action run:self.state];
}

@end
