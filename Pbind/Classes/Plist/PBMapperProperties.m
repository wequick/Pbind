//
//  PBMapperProperties.m
//  Pbind
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBMapperProperties.h"
#import "PBValueParser.h"
#import "PBMutableExpression.h"
#import "UIView+Pbind.h"
#import "PBPropertyUtils.h"

@interface PBMapperProperties()
{
    NSMutableDictionary *_constants;
    NSMutableDictionary *_expressions;
}

@end

@implementation PBMapperProperties

+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary
{
    PBMapperProperties *properties = [[self alloc] init];
    for (NSString *key in dictionary) {
        id value = [dictionary objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            if ([key isEqualToString:@"actions"]
                || [key isEqualToString:@"row"]
                || [key isEqualToString:@"item"]
                || [key isEqualToString:@"emptyRow"]
                || [key isEqualToString:@"footer"]
                || ([key isEqualToString:@"action"] || [key rangeOfString:@".action"].length != 0)
                || [key rangeOfString:@"next."].location == 0) { // ignores the action mapper cause it have done by self.
                [properties setConstant:value forKey:key];
                continue;
            }
            
            // Nested
            PBMapperProperties *subproperties = [self propertiesWithDictionary:value];
            if (subproperties->_expressions == nil) {
                [properties setConstant:subproperties->_constants forKey:key];
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
    
    return properties;
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
    
    if (![[owner pb_constants] isEqual:_constants]) {
        [owner setPb_constants:_constants];
        changed = YES;
    }
    
    if (![[owner pb_expressions] isEqual:_expressions]) {
        [owner setPb_expressions:_expressions];
        changed = YES;
    }
    
    return changed;
}

- (void)initDataForOwner:(id)owner
{
    for (NSString *key in _constants) {
        [PBPropertyUtils setValue:_constants[key] forKeyPath:key toObject:owner failure:nil];
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

- (void)mapData:(id)data toTarget:(id)target withContext:(UIView *)context
{
    [self mapData:data toTarget:target forKeyPath:nil withContext:context];
}

- (void)mapData:(id)data toTarget:(id)target forKeyPath:(NSString *)keyPath withContext:(UIView *)context
{
    if (keyPath == nil) {
        // Map all the expressions
        for (NSString *key in _expressions) {
            PBExpression *exp = _expressions[key];
            [exp mapData:data toTarget:target forKeyPath:key inContext:context];
        }
        return;
    }
    
    // Map the specify expression
    PBExpression *exp = _expressions[keyPath];
    if (exp == nil) {
        return;
    }
    
    [exp mapData:data toTarget:target forKeyPath:keyPath inContext:context];
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
    NSMutableDictionary *value = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    [self initDataForOwner:value];
    for (NSString *key in _expressions) {
        PBExpression *exp = _expressions[key];
        [value setObject:[exp stringValue] forKey:key];
    }
    return [value description];
}

@end
