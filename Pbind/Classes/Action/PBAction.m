//
//  PBAction.m
//  Pbind
//
//  Created by Galen Lin on 2016/12/15.
//
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

- (BOOL)haveNext:(NSString *)key {
    if (self.nextMappers == nil) {
        return NO;
    }
    return [self.nextMappers objectForKey:key] != nil;
}

- (void)dispatchNext:(NSString *)key {
    if (self.nextMappers == nil) {
        return;
    }
    
    PBActionMapper *mapper = [self.nextMappers objectForKey:key];
    if (mapper == nil) {
        return;
    }
    
    [self.store dispatchActionWithActionMapper:mapper];
}

#pragma mark - Default delegate

- (BOOL)shouldRunAfterAction:(PBAction *)action {
    return YES;
}

- (void)run:(PBActionState *)state {
    
}

@end
