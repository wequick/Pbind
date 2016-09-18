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
    NSDictionary        *_params;     // Key='params'
}

@end

@implementation PBMapperProperties

+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary
{
    PBMapperProperties *properties = [[self alloc] init];
//    [properties setValuesForKeysWithDictionary:dictionary];
    for (NSString *key in dictionary) {
        id value = [dictionary objectForKey:key];
        if ([key isEqualToString:@"@params"]) {
            properties->_params = value;
            continue;
        }
        
        PBMutableExpression *expression = nil;
        if ([value isKindOfClass:[NSString class]]) {
            expression = [PBMutableExpression expressionWithString:value];
        }
        
        if (expression != nil) {
            if (properties->_expressions == nil) {
                properties->_expressions = [[NSMutableDictionary alloc] init];
            }
            [properties->_expressions setObject:expression forKey:key];
        } else {
            if (properties->_constants == nil) {
                properties->_constants = [[NSMutableDictionary alloc] init];
            }
            [properties->_constants setObject:[PBValueParser valueWithString:value] forKey:key];
        }
    }
    
    return properties;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"%@ undefinedKey: %@", [[self class] description], key);
}

- (NSArray *)propertiesForKey:(NSString *)key
{
    NSMutableArray *properties = [NSMutableArray array];
    for (NSString *aKey in _constants) {
        if ([aKey isEqualToString:key]) {
            [properties addObject:[_constants objectForKey:aKey]];
        }
    }
    for (NSString *aKey in _expressions) {
        if ([aKey isEqualToString:key]) {
            [properties addObject:[_expressions objectForKey:aKey]];
        }
    }
    return properties;
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
