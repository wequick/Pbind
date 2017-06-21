//
//  PBPropertyUtils.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/10/28.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBPropertyUtils.h"
#import <objc/runtime.h>
#import "PBInline.h"
#import "UIView+Pbind.h"

@interface _PBPropertyInfo : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL  isObject;
@property (nonatomic, assign) BOOL  isProperty;
@property (nonatomic, assign) BOOL  isStruct;

@end

@implementation _PBPropertyInfo
{
    Class typeClass;
}

- (void)parseType:(const char *)typeStr {
    size_t len = strlen(typeStr);
    char *p = (char *) typeStr;
    char *p2, *temp;
    switch (*p) {
        case '@':
            p++;
            if (*p == '\0') {
                // '@'
                self.type = @"id";
            } else if (*p == '"') {
                // '@"NSString"'
                p++;
                p2 = temp = (char *) malloc(len + typeStr - p);
                while (*p != '"') {
                    *p2++ = *p++;
                }
                *p2 = '\0';
                self.type = [NSString stringWithUTF8String:temp];
                free(temp);
                self.isObject = YES;
            }
            break;
        case '{':
            p++;
            p2 = temp = (char *) malloc(len + typeStr - p);
            while (*p != '=') {
                *p2++ = *p++;
            }
            *p2 = '\0';
            self.type = [NSString stringWithUTF8String:temp];
            self.isStruct = YES;
            free(temp);
            break;
            
        case 'c': self.type = @"char"; p++; break;
        case 'd': self.type = @"double"; p++; break;
        case 'i': self.type = @"int"; p++; break;
        case 'l': self.type = @"long"; p++; break;
        case 's': self.type = @"short"; p++; break;
        case 'I': self.type = @"unsigned int"; p++; break;
        case '^': self.type = @"block"; p++; break;
        case 'B': self.type = @"BOOL"; p++; break;
        default:
            self.type = [NSString stringWithFormat:@"%c", *p];
            break;
    }
    
    if (self.isObject) {
        typeClass = NSClassFromString(self.type);
    } else if (self.isStruct) {
        typeClass = [NSValue class];
    } else {
        typeClass = [NSNumber class];
    }
}

- (BOOL)isWithType:(Class)theType {
    return [typeClass isSubclassOfClass:theType];
}

- (NSString *)description {
    NSMutableString *text = [[NSMutableString alloc] init];
    if (self.isProperty) {
        [text appendFormat:@"🅿️%@ ", self.name];
        [text appendFormat:@"( @property %@ ", self.type];
        if (self.isObject) {
            [text appendString:@"*"];
        }
        [text appendFormat:@"%@ )", self.name];
    } else {
        [text appendFormat:@"🎯%@ ", self.name];
        [text appendFormat:@"( set%c%@:(%@", toupper([self.name characterAtIndex:0]), [self.name substringFromIndex:1], self.type];
        if (self.isObject) {
            [text appendString:@" *"];
        }
        [text appendFormat:@")%@ )", self.name];
    }
    
    return text;
}

@end

@implementation PBPropertyUtils

+ (id)valueForKeyPath:(NSString *)keyPath ofObject:(id)object failure:(void (^)(void))failure {
    id value = nil;
    @try {
        value = [object valueForKeyPath:keyPath];
    } @catch (NSException *exception) {
        [self printError:exception byAccessingInconsistencyKeyPath:keyPath ofObject:object];
        if (failure) {
            failure();
        }
    }
    return value;
}

+ (void)setValue:(id)value forKey:(NSString *)key toObject:(id)object failure:(void (^)(void))failure
{
    if (value == nil) {
        value = [self safeNilValueForKey:key ofObject:object];
    }
    
    @try {
        [object setValue:value forKey:key];
    } @catch (NSException *exception) {
        [self printError:exception bySettingInconsistencyValue:value forKeyPath:key toObject:object];
        if (failure) {
            failure();
        }
    }
}

+ (void)invokeSetterWithValue:(id)value forKey:(NSString *)key toObject:(id)object failure:(void (^)(void))failure
{
    BOOL set = NO;
    do {
        if ([key length] <= 1) {
            break;
        }
        
        NSString *setterName = [NSString stringWithFormat:@"set%c%@:", toupper([key characterAtIndex:0]), [key substringFromIndex:1]];
        SEL setter = NSSelectorFromString(setterName);
        if (setter == nil) {
            break;
        }
        
        IMP imp = [object methodForSelector:setter];
        if (imp == nil) {
            break;
        }
        
        void (*func)(id target, SEL sel, id value) = (void (*)(id, SEL, id)) imp;
        func(object, setter, value);
        set = YES;
    } while (false);
    
    if (!set) {
        if (failure) {
            failure();
        }
    }
}

+ (void)setValue:(id)value forKeyPath:(NSString *)keyPath toObject:(id)object failure:(void (^)(void))failure
{
    @try {
        [object setValue:value forKeyPath:keyPath];
    } @catch (NSException *exception) {
        [self printError:exception bySettingInconsistencyValue:value forKeyPath:keyPath toObject:object];
        if (failure) {
            failure();
        }
    }
}

+ (void)setValuesForKeysWithDictionary:(NSDictionary *)dictionary toObject:(id)object failure:(void (^)(void))failure {
    for (NSString *key in dictionary) {
        [self setValue:dictionary[key] forKey:key toObject:object failure:failure];
    }
}

+ (id)safeNilValueForKey:(NSString *)key ofObject:(id)object {
    Class objectClass = [object class];
    objc_property_t property = class_getProperty(objectClass, [key UTF8String]);
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
    return [self defaultValueForKey:key inClass:objectClass];
}

+ (id)defaultValueForKeyPath:(NSString *)keyPath inClass:(Class)objectClass {
    id tempObject = [[objectClass alloc] init];
    return [tempObject valueForKeyPath:keyPath];
}

+ (id)defaultValueForKey:(NSString *)key inClass:(Class)objectClass {
    id tempObject = [[objectClass alloc] init];
    return [tempObject valueForKey:key];
}

+ (void)printAvailableKeysForKey:(NSString *)key withValue:(id)value ofObject:(id)object {
    NSMutableString *tips = [[NSMutableString alloc] init];
    [tips appendFormat:@"The '%@' is not key value coding-compliant for the key '%@'.", [[object class] description], key];
    
    NSMutableArray *similarKeys = [NSMutableArray array];
    [self collectSimilarKeys:similarKeys likeKey:[key UTF8String] valueType:[value class] objectType:[object class]];
    
    if (similarKeys.count > 0) {
        [tips appendString:@"\n🤔Did you mean:\n"];
        for (_PBPropertyInfo *info in similarKeys) {
            [tips appendFormat:@"  - %@\n", info];
        }
    }
    NSLog(@"Pbind: ⚠️%@", tips);
}

+ (_PBPropertyInfo *)propertyInfoForKey:(NSString *)key inClass:(Class)objectClass {
    objc_property_t property = class_getProperty(objectClass, [key UTF8String]);
    if (property != nil){
        const char *attrs = property_getAttributes(property);
        _PBPropertyInfo *info = [[_PBPropertyInfo alloc] init];
        [info parseType:attrs + 1];
        return info;
    }
    
    if (objectClass == [UIView class]) {
        
    }
    
    // Search super class
    objectClass = class_getSuperclass(objectClass);
    if (objectClass == nil) {
        return nil;
    }
    return [self propertyInfoForKey:key inClass:objectClass];
}

+ (_PBPropertyInfo *)argumentInfoForSetter:(SEL)setter inClass:(Class)objectClass {
    Method method = class_getInstanceMethod(objectClass, setter);
    if (method != nil) {
        const char *argType = method_copyArgumentType(method, 2);
        _PBPropertyInfo *info = [[_PBPropertyInfo alloc] init];
        [info parseType:argType];
        return info;
    }
    
    // Search super class
    objectClass = class_getSuperclass(objectClass);
    if (objectClass == nil) {
        return nil;
    }
    return [self argumentInfoForSetter:setter inClass:objectClass];
}

+ (void)printRequiresValueTypeForKey:(NSString *)key butValue:(id)value ofObject:(id)object {
    NSMutableString *tips = [[NSMutableString alloc] init];
    
    Class objectClass = [object class];
    _PBPropertyInfo *info = [self propertyInfoForKey:key inClass:objectClass];
    if (info == nil) {
        SEL setter = NSSelectorFromString([NSString stringWithFormat:@"set%c%@:", toupper([key characterAtIndex:0]), [key substringFromIndex:1]]);
        info = [self argumentInfoForSetter:setter inClass:objectClass];
    }
    NSString *objectType = [objectClass description];
    NSString *valueType = [[value class] description];
    [tips appendFormat:@"%@.%@ requires a value with type \"%@\", but got a(n) \"%@\".", objectType, key, info.type, valueType];
    
    if (info.isStruct) {
        [tips appendString:@"\n🤔Accept literal(s):\n"];
        if ([info.type isEqualToString:@"UIEdgeInsets"]) {
            [tips appendString:@"  - ✅{top,left,bottom,right}"];
        } else if ([info.type isEqualToString:@"CGSize"]) {
            [tips appendString:@"  - ✅{width,height}"];
        } else if ([info.type isEqualToString:@"CGPoint"]) {
            [tips appendString:@"  - ✅{x,y}"];
        } else if ([info.type isEqualToString:@"CGRect"]) {
            [tips appendString:@"  - ✅{x,y,width,height}"];
            [tips appendString:@"  - ✅{{x,y},{width,height}}"];
        }
    }
    
    NSLog(@"Pbind: ⚠️%@", tips);
}

+ (void)printError:(NSException *)exception bySettingInconsistencyValue:(id)value forKeyPath:(NSString *)keyPath toObject:(id)object {
    UIViewController *controller = PBTopController();
    NSString *plist = controller.view.plist;
    if (plist != nil) {
        NSLog(@"Pbind: ⚠️An error occurs in %@.plist or it's sub layout plist.", plist);
    }
    
    if ([exception.name isEqualToString:@"NSUnknownKeyException"]) {
        [self printAvailableKeysForKey:keyPath withValue:value ofObject:object];
    } else if ([exception.name isEqualToString:@"NSInvalidArgumentException"]) {
        id target = object;
        NSString *key = keyPath;
        NSArray *keys = [key componentsSeparatedByString:@"."];
        NSUInteger N = keys.count;
        if (N > 1) {
            int i = 0;
            for (; i < N - 1; i++) {
                key = keys[i];
                id temp = [target valueForKey:key];
                if (temp == nil) {
                    break;
                }
                target = temp;
            }
            key = keys[i];
        }
        [self printRequiresValueTypeForKey:key butValue:value ofObject:target];
        id defaultValue = [self defaultValueForKeyPath:key inClass:[target class]];
        @try {
            [target setValue:defaultValue forKeyPath:key];
        } @catch (NSException *exception) {
            NSLog(@"Pbind: Failed to reset default value for key path '%@' of object '%@'", keyPath, [[object class] description]);
        }
    } else {
        NSMutableString *error = [[NSMutableString alloc] init];
        [error appendFormat:@"Failed to set value:'%@' for key path:'%@' to the %@, exception: %@", value, keyPath, [[object class] description], exception];
        NSLog(@"Pbind: %@", error);
    }
}

+ (void)printError:(NSException *)exception byAccessingInconsistencyKeyPath:(NSString *)keyPath ofObject:(id)object {
    UIViewController *controller = PBTopController();
    NSString *plist = controller.view.plist;
    if (plist != nil) {
        NSLog(@"Pbind: ⚠️An error occurs in %@.plist or it's sub layout plist.", plist);
    }
    
    NSMutableString *error = [[NSMutableString alloc] init];
    [error appendFormat:@"Failed to get value for key path:'%@' from the %@, exception: %@", keyPath, [[object class] description], exception];
    NSLog(@"Pbind: %@", error);
}

+ (void)collectSimilarKeys:(NSMutableArray *)outKeys
                   likeKey:(const char *)keyStr
                 valueType:(Class)valueType
                objectType:(Class)objectType
{
    // Search similar properties
    // -------------------------
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(objectType, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        if (![self isSimilarString:keyStr toString:propertyName]) {
            continue;
        }
        
        // attributes format refer to: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
        //
        // NSString *title      => T@"NSString"         ,&,N,V_title
        // id data              => T@                   ,&,N,V_data
        // UIEdgeInsets inset   => T{UIEdgeInsets=dddd} ,  N,V_inset
        // CGSize inner         => T{CGSize=dd}         ,  N,V_inner
        // BOOL enabled         => TB                   ,  N,V_enabled
        // CGFloat height       => Td                   ,  N,V_height
        //
        // (readonly, getter=isHeightExpressive) BOOL heightExpressive => TB,R,N,GisHeightExpressive
        //
        const char *attrs = property_getAttributes(property);
        
        _PBPropertyInfo *info = [[_PBPropertyInfo alloc] init];
        info.isProperty = YES;
        
        size_t len = strlen(attrs) + 1;
        char *p = (char *)attrs + 1; // bypass 'T'
        char *temp;
        char *p2;
        
        p2 = temp = (char *) malloc(len);
        while (*p != ',') {
            *p2++ = *p++;
        }
        *p2 = '\0';
        
        [info parseType:temp];
        free(temp);

        while (*p != 'V' && *p != '\0') {
            p++;
        }
        if (*p == '\0') {
            continue;
        }
        p++;
        if (*p == '_') {
            p++;
        }
        p2 = temp = (char *) malloc(len + attrs - p);
        while (*p != '\0') {
            *p2++ = *p++;
        }
        *p2 = '\0';
        info.name = [NSString stringWithUTF8String:temp];
        free(temp);
        
        [outKeys addObject:info];
    }
    free(properties);
    
    
    // Search similar setter methods (setXX:)
    // --------------------------------------
    Method *methods = class_copyMethodList(objectType, &outCount);
    for (i = 0; i < outCount; i++) {
        Method method = methods[i];
        NSInteger argCount = method_getNumberOfArguments(method);
        if (argCount != 3) { // func(id target, SEL, id value)
            continue;
        }
        
        const char *methodName = sel_getName(method_getName(method));
        size_t len = strlen(methodName);
        
        // The method name should starts with 'set' and ends with ':'
        if (len < 4) {
            continue;
        }
        if (strncmp(methodName, "set", 3) != 0) {
            continue;
        }
        
        // Check if has been added
        char *methodKey = (char *) malloc(len - 3);
        char *p2 = methodKey;
        char *p = (char *)methodName + 3;
        while (*p != ':') {
            *p2++ = *p++;
        }
        *p2 = '\0';
        *methodKey = tolower(*methodKey);

        BOOL added = NO;
        NSString *name = [NSString stringWithUTF8String:methodKey];
        for (_PBPropertyInfo *info in outKeys) {
            if ([info.name isEqualToString:name]) {
                added = YES;
                break;
            }
        }
        if (added || ![self isSimilarString:keyStr toString:methodKey]) {
            free(methodKey);
            continue;
        }
        
        free(methodKey);
        
        _PBPropertyInfo *info = [[_PBPropertyInfo alloc] init];
        char *argType = method_copyArgumentType(method, 2);
        [info parseType:argType];
        info.name = name;
        [outKeys addObject:info];
    }
    
    free(methods);
    
    // Search super class
    // ------------------
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
        if (tolower(*p1++) != tolower(*p2++)) {
            break;
        }
    }
    return ((i << 1) >= MAX(len1, len2));
}

@end
