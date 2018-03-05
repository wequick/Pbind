//
//  PBTriggerAction.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/16.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBTriggerAction.h"

@implementation PBTriggerAction

#define PBEnumerateAtomicTypes(block) \
if (strcmp(type, @encode(BOOL)) == 0) { \
    BOOL ret = 0; block \
} else if (strcmp(type, @encode(char)) == 0) { \
    char ret = 0; block \
} else if (strcmp(type, @encode(int)) == 0) { \
    int ret = 0; block \
} else if (strcmp(type, @encode(long)) == 0) { \
    long ret = 0; block \
} else if (strcmp(type, @encode(long long)) == 0) { \
    long long ret = 0; block \
} else if (strcmp(type, @encode(unsigned int)) == 0) { \
    unsigned int ret = 0; block \
} else if (strcmp(type, @encode(unsigned long)) == 0) { \
    unsigned long ret = 0; block \
} else if (strcmp(type, @encode(unsigned long long)) == 0) { \
    unsigned long long ret = 0; block \
} else if (strcmp(type, @encode(float)) == 0) { \
    float ret = 0; block \
} else if (strcmp(type, @encode(double)) == 0) { \
    double ret = 0; block \
} else if (strcmp(type, @encode(NSInteger)) == 0) { \
    NSInteger ret = 0; block \
} else if (strcmp(type, @encode(NSUInteger)) == 0) { \
    NSUInteger ret = 0; block \
} else if (strcmp(type, @encode(CGFloat)) == 0) { \
    CGFloat ret = 0; block \
} else if (strcmp(type, @encode(CGPoint)) == 0) { \
    CGPoint ret = {0}; block \
} else if (strcmp(type, @encode(CGVector)) == 0) { \
    CGVector ret = {0}; block \
} else if (strcmp(type, @encode(CGSize)) == 0) { \
    CGSize ret = {0}; block \
} else if (strcmp(type, @encode(CGRect)) == 0) { \
    CGRect ret = {0}; block \
} else if (strcmp(type, @encode(CGAffineTransform)) == 0) { \
    CGAffineTransform ret = {0}; block \
} else if (strcmp(type, @encode(UIEdgeInsets)) == 0) { \
    UIEdgeInsets ret = {0}; block \
} else if (strcmp(type, @encode(UIOffset)) == 0) { \
    UIOffset ret = {0}; block \
} else if (strcmp(type, @encode(NSRange)) == 0) { \
    NSRange ret = {0}; block \
}

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
        NSLog(@"Pbind: Can not trigger action! Missing action '%@' for target <%@>.", self.name, [[self.target class] description]);
        return;
    }
    
    @try {
        NSMethodSignature *signature = [self.target methodSignatureForSelector:action];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = self.target;
        invocation.selector = action;
        NSUInteger argCount = [signature numberOfArguments];
        if (argCount > 2) {
            for (NSUInteger index = 2; index < argCount; index++) {
                NSString *key = [NSString stringWithFormat:@"arg%i", (int)index - 2];
                id arg = [self.params objectForKey:key];
                const char *type = [signature getArgumentTypeAtIndex:index];
                if (strcmp(type, @encode(id)) == 0) {
                    [invocation setArgument:&arg atIndex:index];
                    continue;
                }
                
                if (![arg isKindOfClass:[NSValue class]]) {
                    continue;
                }
                
                PBEnumerateAtomicTypes({
                    [arg getValue:&ret];
                    [invocation setArgument:&ret atIndex:index];
                })
            }
        }
        [invocation invoke];
        
        const char *type = [signature methodReturnType];
        if (strcmp(type, @encode(id)) == 0) {
            void *ret = nil;
            [invocation getReturnValue:&ret];
            state.data = (__bridge id)ret;
            if ([self hasNext:@"done"]) {
                [self dispatchNext:@"done"];
            }
            return;
        }
        
        PBEnumerateAtomicTypes({
            [invocation getReturnValue:&ret];
            state.data = [NSValue value:&ret withObjCType:type];
        })
        if ([self hasNext:@"done"]) {
            [self dispatchNext:@"done"];
        }
    } @catch (NSException *exception) {
        NSLog(@"Pbind: Failed to trigger action '%@' for target <%@>. (error: %@)", self.name, [[self.target class] description], exception);
    }
}

@end
