//
//  PBAction.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBAction.h"
#import "PBActionMapper.h"
#import "UIView+Pbind.h"
#import "PBActionStore.h"

@implementation PBAction

static NSMutableDictionary *kActionClasses;

+ (void)registerType:(NSString *)type {
    [self registerType:type forAction:[[self class] description]];
}

+ (void)registerTypes:(NSArray *)types {
    for (NSString *type in types) {
        [self registerType:type];
    }
}

+ (void)registerType:(NSString *)type forAction:(NSString *)action {
    if (kActionClasses == nil) {
        kActionClasses = [[NSMutableDictionary alloc] init];
    }
    [kActionClasses setObject:action forKey:type];
}

+ (PBAction *)actionForType:(NSString *)type {
    if (kActionClasses == nil) {
        return nil;
    }
    
    NSString *action = [kActionClasses objectForKey:type];
    if (action == nil) {
        return nil;
    }
    
    Class actionClass = NSClassFromString(action);
    if (actionClass == nil) {
        return nil;
    }
    
    return [[actionClass alloc] init];
}

+ (PBAction *)actionWithMapper:(PBActionMapper *)mapper {
    PBAction *action = [self actionForType:mapper.type];
    if (action == nil) {
        return nil;
    }
    action.mapper = mapper;
    [mapper setPropertiesToObject:action transform:nil];
    return action;
}

- (BOOL)hasNext:(NSString *)key {
    if (self.nextActions == nil) {
        return NO;
    }
    return [self.nextActions objectForKey:key] != nil;
}

- (void)dispatchNext:(NSString *)key {
    if (self.nextActions == nil) {
        return;
    }
    
    PBAction *nextAction = [self.nextActions objectForKey:key];
    if (nextAction == nil) {
        return;
    }
    
    [nextAction _internalRun:self.store.state];
}

#pragma mark - Mapping

- (void)setNext:(NSDictionary *)next {
    NSUInteger count = next.count;
    if (count == 0) {
        self.nextActions = nil;
        return;
    }
    
    NSMutableDictionary *nextActions = nil;
    for (NSString *key in next) {
        NSDictionary *subInfo = next[key];
        PBActionMapper *subMapper = [PBActionMapper mapperWithDictionary:subInfo];
        PBAction *subAction = [[self class] actionWithMapper:subMapper];
        if (subAction != nil) {
            if (nextActions == nil) {
                nextActions = [NSMutableDictionary dictionaryWithCapacity:count];
            }
            nextActions[key] = subAction;
        }
    }
    self.nextActions = nextActions;
}

#pragma mark - Default delegate

- (void)_internalRun:(PBActionState *)state {
    if (self.mapper) {
        [self.mapper mapPropertiesToObject:self withData:state.data context:state.context];
    }
    
    if (self.disabled) {
        return;
    }
    [self run:state];
}

- (void)run:(PBActionState *)state {
    
}

@end
