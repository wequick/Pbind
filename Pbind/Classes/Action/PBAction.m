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

@interface PBAction (PBMapping)

@property (nonatomic, strong) NSMutableDictionary *next;

@end

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
    
    [mapper initPropertiesForTarget:action transform:nil];
    
    // Link
    if (mapper.nextMappers != nil) {
        NSMutableDictionary *nextActions = [NSMutableDictionary dictionaryWithCapacity:mapper.nextMappers.count];
        for (NSString *nextKey in mapper.nextMappers) {
            PBActionMapper *subMapper = mapper.nextMappers[nextKey];
            PBAction *subAction = [PBAction actionWithMapper:subMapper];
            nextActions[nextKey] = subAction;
        }
        action.nextActions = nextActions;
    }
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

#pragma mark - Default delegate

- (void)_internalRun:(PBActionState *)state {
    if (self.mapper) {
        [self.mapper mapPropertiesToTarget:self withData:state.data owner:state.sender context:state.context];
    }
    
    if (self.disabled) {
        return;
    }
    [self run:state];
}

- (void)run:(PBActionState *)state {
    
}

@end
