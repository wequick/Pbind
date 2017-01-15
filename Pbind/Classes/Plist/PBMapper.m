//
//  PBMapper.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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
    
    [self setPropertiesWithDictionary:dictionary];
    return self;
}

- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *selfProperties = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    NSDictionary *outletProperties = nil;
    NSMutableDictionary *aliasProperties = nil;
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
        
        // Filter alias properties who's key starts with '@' and doesn't follow any '.' subkeys.
        NSArray *aliasKeys = [[properties allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] '@' AND NOT SELF CONTAINS '.'"]];
        if (aliasKeys.count > 0) {
            aliasProperties = [NSMutableDictionary dictionaryWithCapacity:aliasKeys.count];
            for (NSString *key in aliasKeys) {
                id value = [properties objectForKey:key];
                [aliasProperties setObject:value forKey:[key substringFromIndex:1]];
            }
            
            NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:properties];
            [temp removeObjectsForKeys:aliasKeys];
            properties = temp;
        }
        
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
    
    if (aliasProperties != nil) {
        _aliasProperties = [NSMutableDictionary dictionaryWithCapacity:aliasProperties.count];
        for (NSString *tag in aliasProperties) {
            PBMapperProperties *p = [PBMapperProperties propertiesWithDictionary:aliasProperties[tag]];
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
    
    NSDictionary *navProperties = [dictionary objectForKey:@"nav"];
    if (navProperties != nil) {
        _navProperties = [PBMapperProperties propertiesWithDictionary:navProperties];
        [selfProperties removeObjectForKey:@"nav"];
    }
    
    _properties = [PBMapperProperties propertiesWithDictionary:selfProperties];
    [_properties initDataForOwner:self];
}

- (void)initDataForView:(UIView *)view
{
    if (_viewProperties == nil) {
        // Reset the view properties
        [view setPb_constants:nil];
        [view setPb_expressions:nil];
    } else {
        // Init owner's properties
        if (![_viewProperties initPropertiesForOwner:view]) {
            // TODO: avoid repeatly initializing.
            //        return;
        }
    }
    
    // Init navigation item
    if (_navProperties != nil) {
        [_navProperties initDataForOwner:view.supercontroller.navigationItem];
    }
    
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
    [_properties mapData:data toTarget:self withContext:view];
}

- (void)updateValueForKey:(NSString *)key withData:(id)data andView:(UIView *)view
{
    [_properties mapData:data toTarget:self forKeyPath:key withContext:view];
}

- (void)mapData:(id)data forView:(UIView *)view
{
    /* for self */
    /*----------*/
    [self _mapValuesForKeysWithData:data andView:view];
    
    /* for view */
    /*----------*/
    [view pb_mapData:data];
    
    /* for navigation */
    if (_navProperties != nil) {
        [_navProperties mapData:view.rootData toTarget:view.supercontroller.navigationItem withContext:view];
    }
}

- (void)setExpression:(PBExpression *)expression forKey:(NSString *)key
{
    [_properties setExpression:expression forKey:key];
}

- (void)unbind {
    if (_properties == nil) {
        return;
    }
    [_properties unbind:self];
}

- (void)dealloc
{
    if (_properties != nil) {
        [_properties unbind:self];
        _properties = nil;
    }
}

@end
