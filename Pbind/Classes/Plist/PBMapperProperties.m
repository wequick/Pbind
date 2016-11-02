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
                || [key isEqualToString:@"footer"]) { // ignores the action mapper cause it have done by self.
                [properties setConstant:value forKey:key];
                continue;
            }
            
            // Nested
            PBMapperProperties *subproperties = [self propertiesWithDictionary:value];
            if (subproperties->_expressions == nil) {
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

- (void)mapData:(id)data forOwner:(id)owner withTarget:(id)target context:(UIView *)context
{
    for (NSString *key in _expressions) {
        PBExpression *exp = _expressions[key];
        id value = [exp valueWithData:data keyPath:key target:target context:context];
        if (value != nil) {
            [owner setValue:value forKeyPath:key];
        }
        [exp bindData:data toTarget:owner forKeyPath:key inContext:context];
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
