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

@synthesize tagProperties=_tagviewProperties;

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
    
    NSDictionary *properties = [dictionary objectForKey:@"properties"];
    if (properties != nil) {
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
    
    NSArray *tagproperties = [dictionary objectForKey:@"tagproperties"];
    if (tagproperties != nil) {
        _tagviewProperties = [[NSMutableArray alloc] initWithCapacity:[tagproperties count]];
        for (NSInteger index = 0; index < [tagproperties count]; index++) {
            properties = [tagproperties objectAtIndex:index];
            [_tagviewProperties addObject:[PBMapperProperties propertiesWithDictionary:properties]];
        }
        [selfProperties removeObjectForKey:@"tagproperties"];
    }
    
    NSArray *outletKeys = [[selfProperties allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] '.'"]];
    if (outletKeys.count > 0) {
        _outletProperties = [[NSMutableDictionary alloc] initWithCapacity:outletKeys.count];
        for (NSString *key in outletKeys) {
            NSString *aKey = [key substringFromIndex:1]; // bypass '.'
            properties = [selfProperties objectForKey:key];
            [_outletProperties setObject:[PBMapperProperties propertiesWithDictionary:properties] forKey:aKey];
        }
        [selfProperties removeObjectsForKeys:outletKeys];
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
    for (NSInteger index = 0; index < [_tagviewProperties count]; index++) {
        id subview = [view viewWithTag:index + 1];
        if (subview != nil) {
            PBMapperProperties *properties = [_tagviewProperties objectAtIndex:index];
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
    [_properties mapData:data forOwner:self withTarget:view context:view];
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

@end
