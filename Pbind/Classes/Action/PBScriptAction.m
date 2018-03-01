//
//  PBScriptAction.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2018/02/18.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBScriptAction.h"
#import "PBMutableExpression.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface PBMutableExpression (Private)

+ (JSContext *)sharedJSContext;

@end

@implementation PBScriptAction

@pbaction(@"evaluate")
- (void)run:(PBActionState *)state {
    if (self.script == nil) {
        return;
    }
    
    JSContext *context = [PBMutableExpression sharedJSContext];
    
    NSMutableDictionary *variables = [NSMutableDictionary dictionaryWithDictionary:self.params];
    if (self.target != nil) {
        variables[@"target"] = self.target;
    }
    
    // Initialize user context
    for (NSString *key in variables) {
        JSValue *oldValue = context[key];
        id value = variables[key];
        if ([value isKindOfClass:[PBDictionary class]]) {
            value = ((PBDictionary *)value)->_dictionary;
        }
        if (oldValue != nil && ![oldValue isUndefined]) {
            NSLog(@"Pbind: conflict variable '%@' in JSContext. (OldValue: %@, NewValue: %@)", key, context[key], value);
        }
        context[key] = value;
    }
    
    // Evaluate
    [context evaluateScript:self.script];
    
    for (NSString *key in variables) {
        // Update value
        id value = variables[key];
        if ([value isKindOfClass:[PBDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]]) {
            NSDictionary *resultDictionary = [context[key] toDictionary];
            for (NSString *resultKey in resultDictionary) {
                id resultValue = resultDictionary[resultKey];
                [value setObject:resultValue forKey:resultKey];
            }
        }
        
        // Clear user context
        context[key] = nil;
    }
    
    if ([self hasNext:@"done"]) {
        [self dispatchNext:@"done"];
    }
}

@end
