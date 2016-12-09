//
//  PBPropertyUtils.m
//  Pods
//
//  Created by Galen Lin on 2016/10/28.
//
//

#import "PBPropertyUtils.h"
#import <objc/runtime.h>

@implementation PBPropertyUtils

+ (void)setValue:(id)value forKey:(NSString *)key toObject:(id)object
{
    if (value == nil) {
        value = [self safeNilValueForKey:key ofObject:object];
    }
    
    @try {
        [object setValue:value forKey:key];
    } @catch (NSException *exception) {
        [self printAvailableKeysForKey:key withValue:value ofObject:object];
    }
}

+ (id)safeNilValueForKey:(NSString *)key ofObject:(id)object {
    objc_property_t property = class_getProperty([object class], [key UTF8String]);
    if (property == nil) {
        return nil;
    }
    
    const char *attrs = property_getAttributes(property);
    if (attrs[1] == '@') {
        // NSObject accepts nil value.
        return nil;
    }
    
    // Non-object type DO NOT accepts nil value.
    // As simply, we can set the value to `[NSNumber numberWithInt:0]',
    // but sometimes the default value for the key may not be zero,
    // as UILabel.numberOfLines should takes 1. So, we creating a
    // temporaty object with the related class and return it's initial value.
    id tempObject = [[[object class] alloc] init];
    return [tempObject valueForKey:key];
}

+ (void)printAvailableKeysForKey:(NSString *)key withValue:(id)value ofObject:(id)object {
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

+ (void)collectSimilarKeys:(NSMutableArray *)outKeys
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
        // attributes format refer to: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
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

+ (BOOL)isSimilarString:(const char *)str1 toString:(const char *)str2 {
    NSInteger len1 = strlen(str1);
    NSInteger len2 = strlen(str2);
    NSInteger len = MIN(len1, len2);
    NSInteger i = 0;
    char *p1 = (char *)str1;
    char *p2 = (char *)str2;
    while (i++ < len) {
        if (*p1++ != *p2++) {
            break;
        }
    }
    return ((i << 1) >= MAX(len1, len2));
}

@end
