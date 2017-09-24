//
//  PBMapperProperties.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBMapperProperties.h"
#import "PBValueParser.h"
#import "PBMutableExpression.h"
#import "UIView+Pbind.h"
#import "PBPropertyUtils.h"

@interface PBMapperProperties()

@property (nonatomic, strong) NSMutableDictionary *constants;
@property (nonatomic, strong) NSMutableDictionary *expressions;

@end

@implementation PBMapperProperties

+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary
{
    return [self propertiesWithDictionary:dictionary mapper:nil];
}

+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary mapper:(PBMapper *)mapper
{
    PBMapperProperties *properties = [[self alloc] init];
    for (NSString *key in dictionary) {
        if ([key rangeOfString:@"//"].location == 0) {
            continue;
        }
        
        id value = [dictionary objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            if ([key isEqualToString:@"actions"]
                || [key isEqualToString:@"row"]
                || [key isEqualToString:@"item"]
                || [key isEqualToString:@"emptyRow"]
                || [key isEqualToString:@"errorRow"]
                || [key isEqualToString:@"header"]
                || [key isEqualToString:@"footer"]
                || [key isEqualToString:@"accessoryView"]
                || [key isEqualToString:@"views"]
                || ([key isEqualToString:@"action"] || [key rangeOfString:@".action"].length != 0)
                || [key rangeOfString:@"next."].location == 0) { // ignores the action mapper cause it have done by self.
                [properties setConstant:value forKey:key];
                continue;
            }
            
            // Nested
            PBMapperProperties *subproperties = [self propertiesWithDictionary:value mapper:mapper];
            if (subproperties->_expressions == nil) {
                if (subproperties->_constants != nil) {
                    value = subproperties->_constants;
                }
                [properties setConstant:value forKey:key];
            } else {
                PBMutableExpression *expression = [[PBMutableExpression alloc] initWithProperties:subproperties];
                [properties setExpression:expression forKey:key];
            }
            continue;
        }
        
        if ([value isKindOfClass:[NSString class]]) {
            PBMutableExpression *expression = [PBMutableExpression expressionWithString:value];
            if (expression != nil) {
                [properties setExpression:expression forKey:key];
                continue;
            }
            
            value = [PBValueParser valueWithString:value];
        }
        
        [properties setConstant:value forKey:key];
    }
    
    properties.mapper = mapper;
    return properties;
}

- (id)constantForKey:(NSString *)key {
    if (_constants == nil || key == nil) {
        return nil;
    }
    return [_constants objectForKey:key];
}

- (void)setConstant:(id)value forKey:(NSString *)key
{
    if (_constants == nil) {
        _constants = [[NSMutableDictionary alloc] init];
    }
    [_constants setObject:value forKey:key];
}

- (void)setExpression:(PBExpression *)expression forKey:(NSString *)key
{
    if (_expressions == nil) {
        _expressions = [[NSMutableDictionary alloc] init];
    }
    [_expressions setObject:expression forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"%@ undefinedKey: %@", [[self class] description], key);
}

- (BOOL)isExpressiveForKey:(NSString *)key
{
    return [[_expressions allKeys] containsObject:key];
}

- (BOOL)initPropertiesForOwner:(id)owner
{
    BOOL changed = NO;
    
//    if (![[owner pb_constants] isEqual:_constants]) {
//        [owner pb_setConstants:_constants fromPlist:self.mapper.plist];
//        changed = YES;
//    }
//
//    if (![[owner pb_expressions] isEqual:_expressions]) {
//        [owner pb_setExpressions:_expressions fromPlist:self.mapper.plist];
//        changed = YES;
//    }
    
    for (NSString *key in _constants) {
        id value = [self constantForKey:key];
        [owner pb_setValue:value forKeyPath:key];
    }
    
    return changed;
}

- (void)initDataForOwner:(id)owner
{
    [self initDataForOwner:owner transform:nil];
}

- (void)initDataForOwner:(id)owner transform:(id (^)(NSString *key, id value))transform
{
    for (NSString *key in _constants) {
        id value = _constants[key];
        if (transform != nil) {
            value = transform(key, value);
        }
        [PBPropertyUtils setValue:value forKeyPath:key toObject:owner failure:nil];
    }
}

- (void)setDataToOwner:(id)owner
{
    for (NSString *key in _constants) {
        [PBPropertyUtils invokeSetterWithValue:_constants[key] forKey:key toObject:owner failure:nil];
    }
}

- (BOOL)matchesType:(PBMapType)type dataTag:(unsigned char)dataTag
{
    if (_expressions == nil) {
        return NO;
    }
    
    for (NSString *key in _expressions) {
        PBExpression *exp = _expressions[key];
        if ([exp matchesType:type dataTag:dataTag]) {
            return YES;
        }
    }
    return NO;
}

- (void)mapData:(id)data toTarget:(id)target withOwner:(UIView *)owner context:(UIView *)context
{
    [self mapData:data toTarget:target forKeyPath:nil withOwner:owner context:context];
}

- (void)mapData:(id)data toTarget:(id)target forKeyPaths:(NSArray *)keyPaths withOwner:(UIView *)owner context:(UIView *)context {
    for (NSString *key in keyPaths) {
        PBExpression *exp = _expressions[key];
        if (exp == nil) {
            continue;
        }
        
        [exp mapData:data toTarget:target forKeyPath:key withOwner:owner inContext:context];
    }
}

- (void)mapData:(id)data toTarget:(id)target forKeyPath:(NSString *)keyPath withOwner:(UIView *)owner context:(UIView *)context
{
    NSArray *keyPaths = nil;
    if (keyPath == nil) {
        // Map all the expressions
        keyPaths = [_expressions allKeys];
    } else {
        keyPaths = @[keyPath];
    }
    
    [self mapData:data toTarget:target forKeyPaths:keyPaths withOwner:owner context:context];
}

- (void)setMappable:(BOOL)mappable forKey:(NSString *)key {
    PBExpression *exp = _expressions[key];
    if (exp == nil) {
        return;
    }
    
    exp.enabled = mappable;
}

- (void)unbind:(id)target
{
    if (_expressions == nil) return;
    
    for (NSString *key in _expressions) {
        PBExpression *exp = [_expressions objectForKey:key];
        [exp unbind:target forKeyPath:key];
    }
}

- (NSInteger)count
{
    return [_constants count] + [_expressions count];
}

- (NSString *)description
{
    return [[self source] description];
}

- (NSDictionary *)source {
    NSMutableDictionary *value = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    [self initDataForOwner:value];
    for (NSString *key in _expressions) {
        PBExpression *exp = _expressions[key];
        [value setObject:[exp source] forKey:key];
    }
    return value;
}

@end
