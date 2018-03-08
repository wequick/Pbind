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

NSNotificationName const PBActionStoreWillDispatchActionNotification = @"PBActionStoreWillDispatchAction";
NSNotificationName const PBActionStoreDidDispatchActionNotification = @"PBActionStoreDidDispatchAction";

@interface PBAction (Private)

- (BOOL)_internalRun:(PBActionState *)state;

@end

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
    [self dispatchActionWithActionMapper:mapper context:context data:nil];
}

- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper context:(UIView *)context data:(id)data {
    [self dispatchActionWithActionMapper:mapper sender:context context:context data:data];
}

- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper sender:(UIView *)sender context:(UIView *)context data:(id)data {
    PBAction *action = [PBAction actionWithMapper:mapper];
    if (action == nil) {
        return;
    }
    
    [self dispatchAction:action sender:sender withContext:context data:data];
}

- (void)dispatchAction:(PBAction *)action {
    [self dispatchAction:action sender:nil withContext:nil data:nil];
}

- (void)dispatchAction:(PBAction *)action sender:(UIView *)sender withContext:(UIView *)context data:(id)data {
    self.state = [[PBActionState alloc] init];
    self.state.sender = sender;
    self.state.context = context;
    self.state.data = data;
    action.store = self;
    
    if (![action _internalRun:self.state]) {
        return;
    }
}

@end
