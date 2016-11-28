//
//  PBMapper.m
//  Pbind
//
//  Created by galen on 15/2/15.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBMapper.h"
#import <UIKit/UIKit.h>
#import "UIView+Pbind.h"
#import "PBExpression.h"

@interface PBMapperProperties (Private)

- (void)setExpression:(PBExpression *)expression forKey:(NSString *)key;

@end

@interface PBMapper ()

@property (nonatomic, strong) id data;

@end

@implementation PBMapper

+ (instancetype)mapperWithContentsOfURL:(NSURL *)url
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:url];
    if (dictionary == nil) {
        return nil;
    }
    
    return [self mapperWithDictionary:dictionary];
}

+ (instancetype)mapperWithDictionary:(NSDictionary *)dictionary
{
    if ([dictionary isKindOfClass:self]) {
        return (id) dictionary;
    }
    return [[self alloc] initWithDictionary:dictionary];
}

+ (instancetype)mapperWithDictionary:(NSDictionary *)dictionary owner:(UIView *)owner {
    PBMapper *mapper = [self mapperWithDictionary:dictionary];
    return mapper;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    NSMutableDictionary *selfProperties = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    NSDictionary *outletProperties = nil;
    NSMutableDictionary *taggedProperties = nil;
    NSDictionary *properties = [dictionary objectForKey:@"properties"];
    if (properties != nil) {
        // Filter outlet properties who's key starts with '.'
        NSArray *outletKeys = [[properties allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] '.'"]];
        if (outletKeys.count > 0) {
            outletProperties = [properties dictionaryWithValuesForKeys:outletKeys];
            
            NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:properties];
            [temp removeObjectsForKeys:outletKeys];
            properties = temp;
        }
        
        // Filter tagged properties who's key starts with '@'
//        NSArray *taggedKeys = [[properties allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] '@'"]];
//        if (taggedKeys.count > 0) {
//            taggedProperties = [NSMutableDictionary dictionaryWithCapacity:taggedKeys.count];
//            for (NSString *key in taggedKeys) {
//                NSRange range = [key rangeOfString:@"."];
//                if (range.location == NSNotFound) {
//                    continue;
//                }
//                
//                NSString *keyForTaggedView = [key substringFromIndex:range.location + 1];
//                
//                range.length = range.location - 1;
//                range.location = 1;
//                NSString *tag = [key substringWithRange:range];
//                
//                NSMutableDictionary *aProperties = [taggedProperties objectForKey:tag];
//                if (aProperties == nil) {
//                    aProperties = [NSMutableDictionary dictionary];
//                    [taggedProperties setObject:aProperties forKey:tag];
//                }
//                [aProperties setObject:properties[key] forKey:keyForTaggedView];
//            }
//            
//            NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:properties];
//            [temp removeObjectsForKeys:taggedKeys];
//            properties = temp;
//        }
        
        _viewProperties = [PBMapperProperties propertiesWithDictionary:properties];
        [selfProperties removeObjectForKey:@"properties"];
    }
    
    NSArray *subproperties = [dictionary objectForKey:@"subproperties"];
    if (subproperties != nil) {
        _subviewProperties = [[NSMutableArray alloc] initWithCapacity:[subproperties count]];
        for (NSInteger index = 0; index < [subproperties count]; index++) {
            properties = [subproperties objectAtIndex:index];
            [_subviewProperties addObject:[PBMapperProperties propertiesWithDictionary:properties]];
        }
        [selfProperties removeObjectForKey:@"subproperties"];
    }
    
    if (taggedProperties != nil) {
        _aliasProperties = [NSMutableDictionary dictionaryWithCapacity:taggedProperties.count];
        for (NSString *tag in taggedProperties) {
            PBMapperProperties *p = [PBMapperProperties propertiesWithDictionary:taggedProperties[tag]];
            [_aliasProperties setObject:p forKey:tag];
        }
    }
    
    if (outletProperties != nil) {
        _outletProperties = [[NSMutableDictionary alloc] initWithCapacity:outletProperties.count];
        for (NSString *key in outletProperties) {
            NSString *aKey = [key substringFromIndex:1]; // bypass '.'
            NSDictionary *properties = [outletProperties objectForKey:key];
            [_outletProperties setObject:[PBMapperProperties propertiesWithDictionary:properties] forKey:aKey];
        }
    }
    
    _properties = [PBMapperProperties propertiesWithDictionary:selfProperties];
    [_properties initDataForOwner:self];
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    // Ignore
    NSLog(@"%@ undefinedKey: %@", [[self class] description], key);
}

- (void)initDataForView:(UIView *)view
{
    // Init owner's properties
    [_viewProperties initPropertiesForOwner:view];
    // Init owner's tagged-subviews properties
    for (NSString *alias in _aliasProperties) {
        id subview = [view viewWithAlias:alias];
        if (subview != nil) {
            PBMapperProperties *properties = [_aliasProperties objectForKey:alias];
            [properties initPropertiesForOwner:subview];
        }
    }
    // Init owner's subviews properties
    for (NSInteger index = 0; index < [_subviewProperties count]; index++) {
        if (index >= [[view subviews] count]) {
            break;
        }
        id subview = [[view subviews] objectAtIndex:index];
        PBMapperProperties *properties = [_subviewProperties objectAtIndex:index];
        [properties initPropertiesForOwner:subview];
    }
    // Init owner's outlet view properties
    for (NSString *key in _outletProperties) {
        id subview = [view valueForKey:key];
        if (subview == nil) {
            continue;
        }
        PBMapperProperties *properties = [_outletProperties objectForKey:key];
        [properties initPropertiesForOwner:subview];
    }
    
    [view pb_initData];
}

- (void)updateWithData:(id)data andView:(UIView *)view
{
    return [self _mapValuesForKeysWithData:data andView:view];
}

- (void)_mapValuesForKeysWithData:(id)data andView:(UIView *)view
{
    [_properties mapData:data toOwner:self withTarget:self context:view];
}

- (void)updateValueForKey:(NSString *)key withData:(id)data andView:(UIView *)view
{
    [_properties mapData:data toOwner:self forKeyPath:key withTarget:self context:view];
}

- (void)mapData:(id)data forView:(UIView *)view
{
    /* for self */
    /*----------*/
    [self _mapValuesForKeysWithData:data andView:view];
    
    /* for view */
    /*----------*/
    [view pb_mapData:data];
}

- (void)dealloc
{
    if (_properties != nil) {
        [_properties unbind:self forKeyPath:nil];
        _properties = nil;
    }
}

@end
