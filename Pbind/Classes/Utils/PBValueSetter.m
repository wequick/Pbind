//
//  PBValueSetter.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2017/9/24.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBValueSetter.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    PBValueTypeObject,
    PBValueTypeScalar,
    PBValueTypeStruct,
    PBValueTypePointer
} PBValueType;

typedef enum : NSUInteger {
    PBStructTypeCGPoint,
    PBStructTypeCGVector,
    PBStructTypeCGSize,
    PBStructTypeCGRect,
    PBStructTypeCGAffineTransform,
    PBStructTypeUIEdgeInsets,
    PBStructTypeUIOffset,
    PBStructTypeNSRange,
} PBStructType;

typedef enum : NSUInteger {
    PBScalarTypeBOOL,
    PBScalarTypeChar,
    PBScalarTypeShort,
    PBScalarTypeInt,
    PBScalarTypeLong,
    PBScalarTypeLongLong,
    PBScalarTypeFloat,
    PBScalarTypeDouble
} PBScalarType;

typedef struct {
    unsigned char type : 2;
    unsigned char subtype : 4;
    unsigned char isUnsigned : 1;
    unsigned char reserved : 1;
} PBSetterArg;

@implementation PBValueSetter
{
    union {
        struct {
            SEL sel;
            IMP imp;
            PBSetterArg arg;
        } func;
        Ivar var;
    } _setter;
}

- (instancetype)initWithTarget:(id)target key:(NSString *)key {
    if (self = [super init]) {
        NSLog(@"== size: [(%ld & %ld: %ld ) | %ld] => %ld",
              sizeof(IMP), sizeof(PBSetterArg), sizeof(_setter.func),
              sizeof(Ivar),
              sizeof(_setter));
        
        Class targetClass = [target class];
        const char *szKey = [key UTF8String];
        
        // set<Key>
        size_t len = strlen(szKey);
        char *setterName = malloc(len + 5);
        char *p1 = (char *)szKey;
        char *p2 = setterName;
        *p2++ = 's';
        *p2++ = 'e';
        *p2++ = 't';
        *p2++ = toupper(*p1++);
        while (*p1 != '\0') *p2++ = *p1++;
        *p2++ = ':';
        *p2 = '\0';
        
        SEL setter = sel_registerName(setterName);
        free(setterName);
        if ([target respondsToSelector:setter]) {
            Method method = class_getInstanceMethod(targetClass, setter);
            const char *argType = method_copyArgumentType(method, 2);
            _setter.func.sel = setter;
            _setter.func.imp = method_getImplementation(method);
            _setter.func.arg = [self argFromObjcType:argType];
        } else {
            _setter.var = class_getInstanceVariable(targetClass, szKey);
        }
    }
    return self;
}

- (void)invokeWithTarget:(id)target value:(id)value {
    SEL sel = _setter.func.sel;
    if (sel != NULL) {
        IMP imp = _setter.func.imp;
        PBSetterArg arg = _setter.func.arg;
        switch (arg.type) {
            case PBValueTypeScalar:
                switch (arg.subtype) {
                    case PBScalarTypeChar:
                        if (arg.isUnsigned) {
                            ((void (*)(id, SEL, unsigned char))imp)(target, sel, [value unsignedCharValue]);
                        } else {
                            ((void (*)(id, SEL, char))imp)(target, sel, [value charValue]);
                        }
                        break;
                    case PBScalarTypeShort:
                        if (arg.isUnsigned) {
                            ((void (*)(id, SEL, unsigned short))imp)(target, sel, [value unsignedShortValue]);
                        } else {
                            ((void (*)(id, SEL, short))imp)(target, sel, [value shortValue]);
                        }
                        break;
                    case PBScalarTypeInt:
                        if (arg.isUnsigned) {
                            ((void (*)(id, SEL, unsigned int))imp)(target, sel, [value unsignedIntValue]);
                        } else {
                            ((void (*)(id, SEL, int))imp)(target, sel, [value intValue]);
                        }
                        break;
                    case PBScalarTypeLong:
                        if (arg.isUnsigned) {
                            ((void (*)(id, SEL, unsigned long))imp)(target, sel, [value unsignedLongValue]);
                        } else {
                            ((void (*)(id, SEL, long))imp)(target, sel, [value longValue]);
                        }
                        break;
                    case PBScalarTypeLongLong:
                        if (arg.isUnsigned) {
                            ((void (*)(id, SEL, unsigned long long))imp)(target, sel, [value unsignedLongLongValue]);
                        } else {
                            ((void (*)(id, SEL, long long))imp)(target, sel, [value longLongValue]);
                        }
                        break;
                    case PBScalarTypeBOOL:
                        ((void (*)(id, SEL, BOOL))imp)(target, sel, [value boolValue]);
                        break;
                        
                    default:
                        break;
                }
                break;
            case PBValueTypeStruct:
                switch (arg.subtype) {
                    case PBStructTypeCGRect:
                        ((void (*)(id, SEL, CGRect))imp)(target, sel, [value CGRectValue]);
                        break;
                    case PBStructTypeCGPoint:
                        ((void (*)(id, SEL, CGPoint))imp)(target, sel, [value CGPointValue]);
                        break;
                    case PBStructTypeCGSize:
                        ((void (*)(id, SEL, CGSize))imp)(target, sel, [value CGSizeValue]);
                        break;
                    case PBStructTypeCGVector:
                        ((void (*)(id, SEL, CGVector))imp)(target, sel, [value CGVectorValue]);
                        break;
                    case PBStructTypeCGAffineTransform:
                        ((void (*)(id, SEL, CGAffineTransform))imp)(target, sel, [value CGAffineTransformValue]);
                        break;
                    case PBStructTypeNSRange:
                        ((void (*)(id, SEL, NSRange))imp)(target, sel, [value rangeValue]);
                        break;
                    case PBStructTypeUIOffset:
                        ((void (*)(id, SEL, UIOffset))imp)(target, sel, [value UIOffsetValue]);
                        break;
                    case PBStructTypeUIEdgeInsets:
                        ((void (*)(id, SEL, UIEdgeInsets))imp)(target, sel, [value UIEdgeInsetsValue]);
                        break;
                    default:
                        break;
                }
                break;
            case PBValueTypeObject:
                ((void (*)(id, SEL, id))imp)(target, sel, value);
                break;
            default:
                ((void (*)(id, SEL, void *))imp)(target, sel, (__bridge void *)value);
                break;
        }
    } else if (_setter.var != NULL) {
        object_setIvar(target, _setter.var, value);
    }
}

- (PBSetterArg)argFromObjcType:(const char *)type {
    PBSetterArg arg = {0};
    switch (*type) {
        case 'c': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeChar;
            break;
        }
        case 'C': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeChar; arg.isUnsigned = 1;
            break;
        }
        case 's': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeShort;
            break;
        }
        case 'S': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeShort; arg.isUnsigned = 1;
            break;
        }
        case 'i': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeInt;
            break;
        }
        case 'I': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeInt; arg.isUnsigned = 1;
            break;
        }
        case 'l': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeLong;
            break;
        }
        case 'L': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeLong; arg.isUnsigned = 1;
            break;
        }
        case 'q': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeLongLong;
            break;
        }
        case 'Q': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeLongLong; arg.isUnsigned = 1;
            break;
        }
        case 'f': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeFloat;
            break;
        }
        case 'd': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeDouble;
            break;
        }
        case 'B': {
            arg.type = PBValueTypeScalar; arg.subtype = PBScalarTypeBOOL;
            break;
        }
        case '{': {
            arg.type = PBValueTypeStruct;
            if (strncmp(type + 1, "CGRect", 6) == 0) {
                arg.subtype = PBStructTypeCGRect;
            } else if (strncmp(type + 1, "CGPoint", 7) == 0) {
                arg.subtype = PBStructTypeCGPoint;
            } else if (strncmp(type + 1, "CGSize", 6) == 0) {
                arg.subtype = PBStructTypeCGSize;
            } else if (strncmp(type + 1, "NSRange", 7) == 0) {
                arg.subtype = PBStructTypeNSRange;
            } else if (strncmp(type + 1, "CGVector", 8) == 0) {
                arg.subtype = PBStructTypeCGVector;
            } else if (strncmp(type + 1, "UIOffset", 8) == 0) {
                arg.subtype = PBStructTypeUIOffset;
            } else if (strncmp(type + 1, "UIEdgeInsets", 12) == 0) {
                arg.subtype = PBStructTypeUIEdgeInsets;
            } else if (strncmp(type + 1, "CGAffineTransform", 17) == 0) {
                arg.subtype = PBStructTypeCGAffineTransform;
            }
            break;
        }
        case '@': {
            arg.type = PBValueTypeObject;
            break;
        }
        default: {
            arg.type = PBValueTypePointer;
            break;
        }
    }
    return arg;
}

@end

