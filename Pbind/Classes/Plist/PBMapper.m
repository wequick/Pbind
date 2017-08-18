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
#import "PBInline.h"

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

+ (instancetype)mapperNamed:(NSString *)plistName {
    NSDictionary *dictionary = PBPlist(plistName);
    if (dictionary == nil) {
        return nil;
    }
    
    PBMapper *mapper = [self mapperWithDictionary:dictionary];
    mapper.plist = plistName;
    return mapper;
}

+ (instancetype)mapperWithDictionary:(NSDictionary *)dictionary
{
    return [self mapperWithDictionary:dictionary owner:nil];
}

+ (instancetype)mapperWithDictionary:(NSDictionary *)dictionary owner:(UIView *)owner {
    if ([dictionary isKindOfClass:self]) {
        return (id) dictionary;
    }
    return [[self alloc] initWithDictionary:dictionary owner:owner];
}

- (id)initWithDictionary:(NSDictionary *)dictionary owner:(UIView *)owner
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    self.owner = owner;
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
        
        _viewProperties = [PBMapperProperties propertiesWithDictionary:properties mapper:self];
        [selfProperties removeObjectForKey:@"properties"];
    }
    
    NSArray *subproperties = [dictionary objectForKey:@"subproperties"];
    if (subproperties != nil) {
        _subviewProperties = [[NSMutableArray alloc] initWithCapacity:[subproperties count]];
        for (NSInteger index = 0; index < [subproperties count]; index++) {
            properties = [subproperties objectAtIndex:index];
            [_subviewProperties addObject:[PBMapperProperties propertiesWithDictionary:properties mapper:self]];
        }
        [selfProperties removeObjectForKey:@"subproperties"];
    }
    
    if (aliasProperties != nil) {
        _aliasProperties = [NSMutableDictionary dictionaryWithCapacity:aliasProperties.count];
        for (NSString *tag in aliasProperties) {
            PBMapperProperties *p = [PBMapperProperties propertiesWithDictionary:aliasProperties[tag] mapper:self];
            [_aliasProperties setObject:p forKey:tag];
        }
    }
    
    if (outletProperties != nil) {
        _outletProperties = [[NSMutableDictionary alloc] initWithCapacity:outletProperties.count];
        for (NSString *key in outletProperties) {
            NSString *aKey = [key substringFromIndex:1]; // bypass '.'
            NSDictionary *properties = [outletProperties objectForKey:key];
            [_outletProperties setObject:[PBMapperProperties propertiesWithDictionary:properties mapper:self] forKey:aKey];
        }
    }
    
    NSDictionary *navProperties = [dictionary objectForKey:@"nav"];
    if (navProperties != nil) {
        _navProperties = [PBMapperProperties propertiesWithDictionary:navProperties mapper:self];
        [selfProperties removeObjectForKey:@"nav"];
    }
    
    _properties = [PBMapperProperties propertiesWithDictionary:selfProperties mapper:self];
    [_properties initDataForOwner:self];
}

#pragma mark - Update self

- (void)updateWithData:(id)data owner:(UIView *)owner context:(UIView *)context
{
    [self _mapValuesForKeysWithData:data owner:owner context:context];
}

- (void)_mapValuesForKeysWithData:(id)data owner:(UIView *)owner context:(UIView *)context
{
    [_properties mapData:data toTarget:self withOwner:owner context:context];
}

- (void)updateValueForKey:(NSString *)key withData:(id)data owner:(UIView *)owner context:(UIView *)context
{
    [_properties mapData:data toTarget:self forKeyPath:key withOwner:owner context:context];
}

- (void)updateValuesForKeys:(NSArray *)keys withData:(id)data owner:(UIView *)owner context:(UIView *)context
{
    [_properties mapData:data toTarget:self forKeyPaths:keys withOwner:owner context:context];
}

#pragma mark - Update target

- (void)initPropertiesForTarget:(id)target
{
    [self initPropertiesForTarget:target transform:nil];
}

- (void)initPropertiesForTarget:(id)target transform:(id (^)(NSString *key, id value))transform
{
    if (![target isKindOfClass:[UIView class]]) {
        [_viewProperties initDataForOwner:target transform:transform];
        return;
    }
    
    UIView *view = target;
    if (_viewProperties == nil) {
        // Reset the view properties
        [view pb_setConstants:nil fromPlist:self.plist];
        [view pb_setExpressions:nil fromPlist:self.plist];
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

- (void)mapPropertiesToTarget:(id)target withData:(id)data owner:(UIView *)owner context:(UIView *)context
{
    /* for self */
    /*----------*/
    [self _mapValuesForKeysWithData:data owner:owner context:context];
    
    if ([target isKindOfClass:[UIView class]]) {
        /* for view */
        /*----------*/
        [target pb_mapData:data withOwner:owner context:context];
        
        /* for navigation */
        if (_navProperties != nil) {
            [_navProperties mapData:context.rootData toTarget:context.supercontroller.navigationItem withOwner:owner context:context];
        }
    } else {
        /* for any object */
        /*----------------*/
        [_viewProperties mapData:data toTarget:target withOwner:owner context:context];
    }
}

#pragma mark - Properties

- (void)setExpression:(PBExpression *)expression forKey:(NSString *)key
{
    [_properties setExpression:expression forKey:key];
}

- (BOOL)isExpressiveForKey:(NSString *)key {
    return [_properties isExpressiveForKey:key];
}

- (void)setMappable:(BOOL)mappable forKey:(NSString *)key {
    [_properties setMappable:mappable forKey:key];
}

#pragma mark - Reset

- (void)resetForView:(UIView *)view {
    if (_navProperties != nil) {
        UIViewController *vc = view.supercontroller;
        UINavigationItem *item = vc.navigationItem;
        item.title = vc.title;
        item.leftBarButtonItem = nil;
        item.leftBarButtonItems = nil;
        item.rightBarButtonItem = nil;
        item.rightBarButtonItems = nil;
    }
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

#pragma mark - Debugging

- (NSDictionary *)targetSource {
    return [_viewProperties source];
}

#pragma mark - Depreciated

- (void)updateWithData:(id)data andView:(UIView *)view
{
    [self updateWithData:data owner:view context:view];
}

@end
