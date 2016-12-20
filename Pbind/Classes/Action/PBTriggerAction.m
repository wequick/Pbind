//
//  PBTriggerAction.m
//  Pods
//
//  Created by Galen Lin on 2016/12/16.
//
//

#import "PBTriggerAction.h"

//typedef void (*PBTriggerVoidFunc)(id target, SEL sel, ...);
//typedef BOOL (*PBTriggerNonvoidFunc)(id target, SEL sel, ...);

#define PBTARG(__i__) self.params[@"arg" # __i__]

#define PBTriggerNonVoid(_TARGET_, _ACTION_, _ARG_COUNT_, _RETTYPE_, _RET_, _STATE_RET_) \
_RETTYPE_ _RET_; \
_RETTYPE_ (*func)(id target, SEL sel, ...) = (_RETTYPE_ (*)(id, SEL, ...)) imp; \
switch (_ARG_COUNT_) { \
    default: \
    case 0: ret = func(_TARGET_, _ACTION_); break; \
    case 1: ret = func(_TARGET_, _ACTION_, PBTARG(0)); break; \
    case 2: ret = func(_TARGET_, _ACTION_, PBTARG(0), PBTARG(1)); break; \
    case 3: ret = func(_TARGET_, _ACTION_, PBTARG(0), PBTARG(1), PBTARG(2)); break; \
    case 4: ret = func(_TARGET_, _ACTION_, PBTARG(0), PBTARG(1), PBTARG(2), PBTARG(3)); break; \
    case 5: ret = func(_TARGET_, _ACTION_, PBTARG(0), PBTARG(1), PBTARG(2), PBTARG(3), PBTARG(4)); break; \
} \
state.data = _STATE_RET_

#define PBTriggerVoid(_TARGET_, _ACTION_, _ARG_COUNT_) \
void (*func)(id target, SEL sel, ...) = (void (*)(id, SEL, ...)) imp; \
switch (_ARG_COUNT_) { \
default: \
case 0: func(_TARGET_, _ACTION_); break; \
case 1: func(_TARGET_, _ACTION_, PBTARG(0)); break; \
case 2: func(_TARGET_, _ACTION_, PBTARG(0), PBTARG(1)); break; \
case 3: func(_TARGET_, _ACTION_, PBTARG(0), PBTARG(1), PBTARG(2)); break; \
case 4: func(_TARGET_, _ACTION_, PBTARG(0), PBTARG(1), PBTARG(2), PBTARG(3)); break; \
case 5: func(_TARGET_, _ACTION_, PBTARG(0), PBTARG(1), PBTARG(2), PBTARG(3), PBTARG(4)); break; \
}

@implementation PBTriggerAction

@pbaction(@"trigger")
- (void)run:(PBActionState *)state {
    if (self.target == nil || self.name == nil) {
        return;
    }
    
    SEL action = NSSelectorFromString(self.name);
    if (action == nil) {
        return;
    }
    
    if (![self.target respondsToSelector:action]) {
        NSLog(@"Pbind: Can not trigger action! Missing action(%@) for target(%@).", self.name, [[self.target class] description]);
        return;
    }
    
    int argCount = 0;
    const char *name = [self.name UTF8String];
    char *p = (char *)name;
    while (*p != '\0') {
        if (*p == ':') {
            argCount++;
        }
        p++;
    }
    if (argCount > 5) {
        NSLog(@"Pbind: Too many arguments to triggera action! Accepts 5 as max.");
        return;
    }
    
    IMP imp = [self.target methodForSelector:action];
    NSString *returnType = self.params[@"ret"];
    if (returnType == nil) {
        PBTriggerVoid(self.target, action, argCount);
    } else if ([returnType isEqualToString:@"BOOL"]) {
        PBTriggerNonVoid(self.target, action, argCount, BOOL, ret, [NSNumber numberWithBool:ret]);
    } else if ([returnType isEqualToString:@"int"] ||
               [returnType isEqualToString:@"char"] ||
               [returnType isEqualToString:@"unsigned int"] ||
               [returnType isEqualToString:@"NSInteger"]) {
        PBTriggerNonVoid(self.target, action, argCount, NSInteger, ret, [NSNumber numberWithInteger:ret]);
    } else if ([returnType isEqualToString:@"long"] ||
               [returnType isEqualToString:@"unsigned long"]) {
        PBTriggerNonVoid(self.target, action, argCount, long, ret, [NSNumber numberWithLong:ret]);
    } else if ([returnType isEqualToString:@"long long"] ||
               [returnType isEqualToString:@"unsigned long long"]) {
        PBTriggerNonVoid(self.target, action, argCount, long, ret, [NSNumber numberWithLongLong:ret]);
    } else {
        PBTriggerNonVoid(self.target, action, argCount, id, ret, ret);
    }
}

@end
