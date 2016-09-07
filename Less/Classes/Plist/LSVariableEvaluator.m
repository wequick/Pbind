//
//  LSVariableEvaluator.m
//  Less
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSVariableEvaluator.h"
#import <JavascriptCore/JavascriptCore.h>

typedef id (*JSValueConvertorFunc)(id, SEL);

static NSMutableDictionary *kFormatters;

@implementation LSVariableEvaluator

+ (JSContext *)sharedJSContext {
    static JSContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[JSContext alloc] init];
    });
    return context;
}

+ (void)load {
    [super load];
    [self registerTag:@"JS" withEvaluator:^id(NSString *tag, NSString *format, NSArray *args) {
        JSContext *context = [self sharedJSContext];
        int argCount = (int) args.count;
        
        // Map each argument to $1 ~ $N
        for (int argIndex = 0; argIndex < argCount; argIndex++) {
            id arg = [args objectAtIndex:argIndex];
            NSString *key = [NSString stringWithFormat:@"$%i", (argIndex + 1)];
            context[key] = arg;
        }
        
        // Evaluate by Javascript
        JSValue *result = [context evaluateScript:format];
        
        // Resolve return value
        if (tag == nil) {
            return [result toString];
        }
        
        // string -> toString, bool -> toBool and etc
        NSString *selName = [NSString stringWithFormat:@"to%c%@", toupper([tag characterAtIndex:0]), [tag substringFromIndex:1]];
        SEL convertor = NSSelectorFromString(selName);
        if (![result respondsToSelector:convertor]) {
            return [result toString];
        }
        
        IMP imp = [result methodForSelector:convertor];
        JSValueConvertorFunc func = (JSValueConvertorFunc) imp;
        return func(result, convertor);
    }];
}

+ (void)registerTag:(NSString *)tag withEvaluator:(id (^)(NSString *tag, NSString *format, NSArray *args))formatter
{
    if (kFormatters == nil) {
        kFormatters = [[NSMutableDictionary alloc] init];
    }
    [kFormatters setObject:formatter forKey:tag];
}

+ (NSArray *)allTags
{
    return [kFormatters allKeys];
}

+ (id (^)(NSString *tag, NSString *format, NSArray *args))evaluatorForTag:(NSString *)tag
{
    return [kFormatters objectForKey:tag];
}

@end
