//
//  LSMapperProperties.m
//  Less
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSMapperProperties.h"
#import "LSValueParser.h"
#import "LSMutableExpression.h"
#import "UIView+LSLayout.h"

@interface LSMapperProperties()
{
    NSMutableDictionary *_constants;
    NSMutableDictionary *_expressions;
    NSDictionary        *_params;     // Key='params'
}

@end

@implementation LSMapperProperties

+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary
{
    LSMapperProperties *properties = [[self alloc] init];
//    [properties setValuesForKeysWithDictionary:dictionary];
    for (NSString *key in dictionary) {
        id value = [dictionary objectForKey:key];
        if ([key isEqualToString:@"@params"]) {
            properties->_params = value;
            continue;
        }
        
        LSMutableExpression *expression = nil;
        if ([value isKindOfClass:[NSString class]]) {
            expression = [LSMutableExpression expressionWithString:value];
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
            [properties->_constants setObject:[LSValueParser valueWithString:value] forKey:key];
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
    [owner setLSConstantProperties:_constants];
    [owner setLSDynamicProperties:_expressions];
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
        LSExpression *exp = _expressions[key];
        id value = [exp valueWithData:data andOwner:view];
        if (value != nil) {
            [owner setValue:value forKeyPath:key];
        }
        [exp bindData:data withOwner:owner forKeyPath:key];
    }
}

@end
