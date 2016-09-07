//
//  LSCompat.h
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <objc/runtime.h>
#import "UIView+Less.h"

//______________________________________________________________________________
// Singleton
#define AS_SINGLETON(_name_)            _AS_SINGLETON(instancetype, _name_)
#define DEF_SINGLETON(_name_)           _DEF_SINGLETON(instancetype, self, _name_)

#define AS_SINGLETON2(_class_, _name_)  _AS_SINGLETON(_class_ *, _name_)
#define DEF_SINGLETON2(_class_, _name_) _DEF_SINGLETON(_class_ *, _class_, _name_)

#define _AS_SINGLETON(_type_, _name_)  \
+ (_type_)_name_;

#define _DEF_SINGLETON(_type_, _class_, _name_) \
+ (_type_)_name_ { \
static id o = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
o = [[_class_ alloc] init]; \
}); \
return o; \
}

//______________________________________________________________________________
// KVC property
#define DEF_UNDEFINED_LSOPERTY2(_type_, _getter_, _setter_) \
static NSString *const _kViewKey##_getter_ = @#_getter_; \
- (void)_setter_:(_type_)v { \
[self willChangeValueForKey:_kViewKey##_getter_]; \
[self setValue:v forAdditionKey:_kViewKey##_getter_]; \
[self didChangeValueForKey:_kViewKey##_getter_]; \
} \
- (_type_)_getter_ { \
return [self valueForAdditionKey:_kViewKey##_getter_]; \
}

#define DEF_UNDEFINED_NUMBER_LSOPERTY(_type_, _getter_, _setter_, _convertor_, _defval_) \
static NSString *const _kViewKey##_getter_ = @#_getter_; \
- (void)_setter_:(_type_)v { \
[self willChangeValueForKey:_kViewKey##_getter_]; \
[self setValue:@(v) forAdditionKey:_kViewKey##_getter_]; \
[self didChangeValueForKey:_kViewKey##_getter_]; \
} \
- (_type_)_getter_ { \
    id value = [self valueForAdditionKey:_kViewKey##_getter_]; \
    if (value == nil) { \
        return _defval_; \
    } \
    return [value _convertor_]; \
}

#define DEF_UNDEFINED_LSOPERTY(_type_, _key_) \
DEF_UNDEFINED_LSOPERTY2(_type_, _key_, set##_key_)

#define DEF_UNDEFINED_BOOL_LSOPERTY(_getter_, _setter_, _defval_) \
    DEF_UNDEFINED_NUMBER_LSOPERTY(BOOL, _getter_, _setter_, boolValue, _defval_)

#define DEF_UNDEFINED_INT_LSOPERTY(_getter_, _setter_, _defval_) \
DEF_UNDEFINED_NUMBER_LSOPERTY(int, _getter_, _setter_, intValue, _defval_)


//______________________________________________________________________________
// Dynamic property
#define AS_DYNAMIC_LSOPERTY(_getter_, _setter_, _type_) \
- (void)_setter_:(_type_)v;  \
- (_type_)_getter_;

// Dynamic OBJECT property
#define DEF_DYNAMIC_OBJECT_LSOPERTY(_getter_, _setter_, _type_, _objc_ass_)    \
static const NSString *KEY_##_getter_ = @#_getter_;  \
- (void)_setter_:(_type_)v {    \
objc_setAssociatedObject(self, &KEY_##_getter_, v, _objc_ass_);  \
}   \
- (_type_)_getter_ {    \
_type_ value = objc_getAssociatedObject(self, &KEY_##_getter_); \
return value;   \
}
// Dynamic OBJECT-RETAIN-NONATOMIC property
#define DEF_DYNAMIC_LSOPERTY(_getter_, _setter_, _type_)    \
DEF_DYNAMIC_OBJECT_LSOPERTY(_getter_, _setter_, _type_, OBJC_ASSOCIATION_RETAIN_NONATOMIC)
// Dynamic OBJECT-ASSIGN property
#define DEF_DYNAMIC_ASSIGN_LSOPERTY(_getter_, _setter_, _type_)    \
DEF_DYNAMIC_OBJECT_LSOPERTY(_getter_, _setter_, _type_, OBJC_ASSOCIATION_ASSIGN)
// Dynamic OBJECT-COPY property
#define DEF_DYNAMIC_COPY_LSOPERTY(_getter_, _setter_, _type_)    \
DEF_DYNAMIC_OBJECT_LSOPERTY(_getter_, _setter_, _type_, OBJC_ASSOCIATION_COPY_NONATOMIC)

// Dynamic NUMBER property
#define DEF_DYNAMIC_NUMBER_LSOPERTY(_getter_, _setter_, _type_, _parser_, _defval_) \
static const NSString *KEY_##_getter_ = @#_getter_;  \
- (void)_setter_:(_type_)v {    \
NSNumber *value = @(v);   \
objc_setAssociatedObject(self, &KEY_##_getter_, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);  \
}   \
- (_type_)_getter_ {    \
NSNumber *value = objc_getAssociatedObject(self, &KEY_##_getter_); \
if (value) {    \
return [value _parser_];    \
} else {    \
return _defval_;    \
}   \
}
// Dynamic NUMBER-BOOL property
#define AS_DYNAMIC_BOOL_LSOPERTY(_getter_, _setter_)    \
AS_DYNAMIC_LSOPERTY(_getter_, _setter_, BOOL)
#define DEF_DYNAMIC_BOOL_LSOPERTY(_getter_, _setter_, _defval_)   \
DEF_DYNAMIC_NUMBER_LSOPERTY(_getter_, _setter_, BOOL, boolValue, _defval_)
// Dynamic NUMBER-INT property
#define AS_DYNAMIC_INT_LSOPERTY(_getter_, _setter_)    \
AS_DYNAMIC_LSOPERTY(_getter_, _setter_, int)
#define DEF_DYNAMIC_INT_LSOPERTY(_getter_, _setter_, _defval_)   \
DEF_DYNAMIC_NUMBER_LSOPERTY(_getter_, _setter_, int, intValue, _defval_)
// Dynamic NUMBER-INTEGER property
#define AS_DYNAMIC_INTEGER_LSOPERTY(_getter_, _setter_)    \
    AS_DYNAMIC_LSOPERTY(_getter_, _setter_, NSInteger)
#define DEF_DYNAMIC_INTEGER_LSOPERTY(_getter_, _setter_, _defval_)   \
    DEF_DYNAMIC_NUMBER_LSOPERTY(_getter_, _setter_, NSInteger, integerValue, _defval_)
#define DEF_DYNAMIC_UINTEGER_LSOPERTY(_getter_, _setter_, _defval_)   \
    DEF_DYNAMIC_NUMBER_LSOPERTY(_getter_, _setter_, NSUInteger, integerValue, _defval_)
// Dynamic NUMBER-CGFloat property
#define AS_DYNAMIC_FLOAT_LSOPERTY(_getter_, _setter_)    \
AS_DYNAMIC_LSOPERTY(_getter_, _setter_, CGFloat)
#define DEF_DYNAMIC_FLOAT_LSOPERTY(_getter_, _setter_, _defval_)  \
DEF_DYNAMIC_NUMBER_LSOPERTY(_getter_, _setter_, CGFloat, floatValue, _defval_)

// Dynamic STRUCT property (CGRect,CGSize...)
#define DEF_DYNAMIC_STRUCT_LSOPERTY(_getter_, _setter_, _type_, _defval_) \
static const NSString *KEY_##_getter_ = @#_getter_;  \
- (void)_setter_:(_type_)v {    \
NSValue *value = [NSValue value:&v withObjCType:@encode(_type_)];   \
objc_setAssociatedObject(self, &KEY_##_getter_, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);  \
}   \
- (_type_)_getter_ {    \
NSValue *value = objc_getAssociatedObject(self, &KEY_##_getter_); \
if (value) {    \
_type_ temp; [value getValue:&temp];    \
return temp;    \
} else {    \
return _defval_;    \
}   \
}
// Dynamic STRUCT-CGRECT property
#define DEF_DYNAMIC_CGRECT_LSOPERTY(_getter_, _setter_) \
DEF_DYNAMIC_STRUCT_LSOPERTY(_getter_, _setter_, CGRect, CGRectZero)
// Dynamic STRUCT-CGSIZE property
#define DEF_DYNAMIC_CGSIZE_LSOPERTY(_getter_, _setter_) \
DEF_DYNAMIC_STRUCT_LSOPERTY(_getter_, _setter_, CGSize, CGSizeZero)
