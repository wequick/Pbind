//
//  PBSpellChecker.m
//  Pods
//
//  Created by Galen Lin on 2016/10/28.
//
//

#import "PBSpellChecker.h"
#import <objc/runtime.h>

@implementation PBSpellChecker

+ (instancetype)defaultSpellChecker {
    static PBSpellChecker *o;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        o = [[self alloc] init];
    });
    return o;
}

- (BOOL)isSimilarString:(const char *)str1 toString:(const char *)str2 {
    int len1 = strlen(str1);
    int len2 = strlen(str2);
    int len = MIN(len1, len2);
    int i = 0;
    char *p1 = (char *)str1;
    char *p2 = (char *)str2;
    while (i++ < len) {
        if (*p1++ != *p2++) {
            break;
        }
    }
    return ((i << 1) >= MAX(len1, len2));
}

- (void)checkKeysLikeKey:(NSString *)key withValue:(id)value ofObject:(id)object {
    NSMutableString *tips = [[NSMutableString alloc] init];
    [tips appendFormat:@"The key '%@' is not defined in class '%@'!", key, [[object class] description]];
    
    NSMutableArray *similarKeys = [NSMutableArray array];
    [self collectSimilarKeys:similarKeys likeKey:[key UTF8String] valueType:[value class] objectType:[object class]];
    
    if (similarKeys.count > 0) {
        [tips appendString:@" Do you mean:\n"];
        for (NSString *aKey in similarKeys) {
            [tips appendFormat:@"  - %@\n", aKey];
        }
    }
    NSLog(@"Pbind: %@", tips);
}

- (void)collectSimilarKeys:(NSMutableArray *)outKeys
                   likeKey:(const char *)keyStr
                 valueType:(Class)valueType
                objectType:(Class)objectType
{
    // Search similar properties
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(objectType, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        
        Class propertyType = nil;
        NSString* propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
        NSArray* splitPropertyAttributes = [propertyAttributes componentsSeparatedByString:@"\""];
        if ([splitPropertyAttributes count] >= 2)
        {
            propertyType = NSClassFromString([splitPropertyAttributes objectAtIndex:1]);
        }
        
        if (propertyType == nil) {
            continue;
        }
        
        if (![valueType isSubclassOfClass:propertyType]) {
            continue;
        }
        
        if ([self isSimilarString:keyStr toString:propertyName]) {
            [outKeys addObject:[NSString stringWithUTF8String:propertyName]];
        }
    }
    free(properties);
    
    // Search similar methods
    Method *methods = class_copyMethodList(objectType, &outCount);
    for (i = 0; i < outCount; i++) {
        Method method = methods[i];
        if (method_getNumberOfArguments(method) != 2) { // no args
            continue;
        }
        
        const char *methodName = sel_getName(method_getName(method));
        if ([self isSimilarString:keyStr toString:methodName]) {
            [outKeys addObject:[NSString stringWithUTF8String:methodName]];
        }
    }
    
    free(methods);
    
    // Search super class
    objectType = class_getSuperclass(objectType);
    if (objectType == nil) {
        return;
    }
    
    [self collectSimilarKeys:outKeys likeKey:keyStr valueType:valueType objectType:objectType];
}
@end
