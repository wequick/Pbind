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
#import "UIView+PBLayout.h"

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
                || [key isEqualToString:@"item"]) { // ignores the action mapper cause it have done by self.
                [properties setConstant:value forKey:key];
                continue;
            }
            
            // Nested
            NSMutableDictionary *constantPartValue = [[NSMutableDictionary alloc] init];
            PBMapperProperties *subproperties = [self propertiesWithDictionary:value];
            [subproperties initDataForOwner:constantPartValue];
            [properties setConstant:constantPartValue forKey:key];
            
            if (subproperties->_expressions != nil) {
                for (NSString *subkey in subproperties->_expressions) {
                    NSString *keyPath = [NSString stringWithFormat:@"%@.%@", key, subkey];
                    PBExpression *exp = [subproperties->_expressions objectForKey:subkey];
                    [properties setExpression:exp forKey:keyPath];
                }
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

- (void)initPropertiesForOwner:(id)owner
{
    [owner setPBConstantProperties:_constants];
    [owner setPBDynamicProperties:_expressions];
}

- (void)initDataForOwner:(id)owner
{
    for (NSString *key in _constants) {
        [owner setValue:_constants[key] forKey:key];
    }
}

- (void)mapData:(id)data forOwner:(id)owner withView:(id)view
{
    for (NSString *key in _expressions) {
        PBExpression *exp = _expressions[key];
        id value = [exp valueWithData:data target:owner context:view];
        if (value != nil) {
            [owner setValue:value forKeyPath:key];
        }
        [exp bindData:data toTarget:owner forKeyPath:key inContext:view];
    }
}

@end
