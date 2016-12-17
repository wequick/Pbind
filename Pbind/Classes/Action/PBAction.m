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

+ (void)dispatchActionForView:(UIView *)view {
    PBActionMapper *mapper = [view actionMapper];
    if (mapper == nil) {
        return;
    }
    
    [self dispatchActionWithActionMapper:mapper context:view from:nil];
}

+ (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper from:(PBAction *)lastAction {
    [self dispatchActionWithActionMapper:mapper context:lastAction.context from:lastAction];
}

+ (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper
                               context:(UIView *)context
                                  from:(PBAction *)lastAction
{
    [mapper updateWithData:context.rootData andView:context];
    
    PBAction *action = [self actionForType:mapper.type];
    if (action == nil) {
        return;
    }
    
    action.type = mapper.type;
    action.disabled = mapper.disabled;
    action.target = mapper.target;
    action.name = mapper.name;
    action.params = mapper.params;
    action.nextMappers = mapper.nextMappers;
    action.context = context;
    action.lastAction = lastAction;
    [action dispatch];
}

- (instancetype)init {
    if (self = [super init]) {
        self.state = [[PBActionState alloc] init];
    }
    return self;
}

- (void)dispatch {
    if (self.disabled) {
        return;
    }
    
    if (self.lastAction != nil) {
        if (![self shouldRunAfterAction:self.lastAction]) {
            return;
        }
    }
    
    [self run];
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
    
    [[self class] dispatchActionWithActionMapper:mapper context:self.context from:self];
}

#pragma mark - Default delegate

- (BOOL)shouldRunAfterAction:(PBAction *)action {
    return YES;
}

- (void)run {
    
}

@end
