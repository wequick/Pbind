//
//  UIView+Pbind.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIView+Pbind.h"
#import "PBInline.h"
#import "PBClient.h"
#import "PBMapper.h"
#import "PBMutableExpression.h"
#import "PBClientMapper.h"
#import "PBArray.h"
#import "PBPropertyUtils.h"
#import "PBValueParser.h"
#import "PBViewController.h"
#import "PBDataFetching.h"
#import "PBDataFetcher.h"

@implementation UIView (Pbind)

@dynamic data;

- (PBMapper *)pb_mapper
{
    // Lazy init
    if (self.PB_internalMapper == nil) {
        if (self._pbPlistURL != nil) {
            self.PB_internalMapper = [PBMapper mapperWithContentsOfURL:self._pbPlistURL];
        }
    }
    return self.PB_internalMapper;
}

- (void)_pb_initData {
    PBMapper *mapper = [self pb_mapper];
    if (mapper == nil) {
        [self pb_initData];
        return;
    }
    
    [mapper initDataForView:self];
}

- (void)_pb_mapData:(id)data {
    PBMapper *mapper = [self pb_mapper];
    if (mapper == nil) {
        [self pb_mapData:data];
        return;
    }
    
    [mapper mapData:data forView:self];
}

- (void)pb_initData
{
    NSDictionary *properties = [self pb_constants];
    for (NSString *key in properties) {
        id value = [properties objectForKey:key];
        value = [PBValueParser valueWithString:value];
        [self pb_setValue:value forKeyPath:key];
    }
    
    [self pb_bindData];
    
    // Recursive
    BOOL canReload = [self respondsToSelector:@selector(reloadData)];
    if (!canReload) {
        for (UIView *subview in [self subviews]) {
            [subview pb_initData];
        }
    }
    
    [self pb_mapData:nil underType:PBMapToContext dataTag:PBDataTagUnset];
}

- (void)pb_bindData
{
    NSDictionary *properties = [self pb_expressions];
    for (NSString *key in properties) {
        PBExpression *exp = [properties objectForKey:key];
        [exp bindData:nil toTarget:self forKeyPath:key inContext:self];
    }
}

- (void)pb_mapData:(id)data underType:(PBMapType)type dataTag:(unsigned char)tag
{
    [self pb_mapData:data forKeys:nil underType:type dataTag:tag];
    
    // Recursive
    BOOL canReload = [self respondsToSelector:@selector(reloadData)];
    if (!canReload) {
        for (UIView *subview in [self subviews]) {
            [subview pb_mapData:data underType:type dataTag:tag];
        }
    } else {
        if (type == PBMapToContext && self.frame.size.height == 0) {
            return;
        }
        [(id)self reloadData];
    }
}

- (void)pb_mapData:(id)data forKeys:(NSArray *)keys underType:(PBMapType)type dataTag:(unsigned char)tag
{
    NSDictionary *expressions = [self pb_expressions];
    if (keys == nil) {
        keys = [expressions allKeys];
    }
    
    for (NSString *key in keys) {
        if (![self mappableForKeyPath:key]) {
            continue;
        }
        
        PBExpression *exp = [expressions objectForKey:key];
        if (![exp matchesType:type dataTag:tag]) {
            continue;
        }
        
        [exp mapData:data toTarget:self forKeyPath:key inContext:self];
    }
}

- (void)pb_mapData:(id)data
{
    [self pb_mapData:data underType:PBMapToAll dataTag:PBDataTagUnset];
}

- (void)pb_mapData:(id)data forKey:(NSString *)key
{
    if (key == nil) {
        return;
    }
    [self pb_mapData:data forKeys:@[key] underType:PBMapToAll dataTag:PBDataTagUnset];
}

- (void)pb_loadData:(id)data
{
    [self setData:data];
    [[self pb_mapper] mapData:self.rootData forView:self];
    
    [self layoutIfNeeded];
}

- (void)pb_reloadPlist
{
    [self pb_unbindAll];
    
    // Re-init data if there is
    id initialData = [self pb_initialData];
    if (initialData != nil) {
        [self setData:initialData];
    }
    
    [self pb_reloadPlistForView:self];
}

- (void)pb_reloadPlistForView:(UIView *)view {
    if (view.plist == nil) {
        for (UIView *subview in view.subviews) {
            [self pb_reloadPlistForView:subview];
        }
        return;
    }
    
    // Reset the plist mapper
    view._pbPlistURL = PBResourceURL(view.plist, @"plist");
    [view.PB_internalMapper resetForView:view];
    view.PB_internalMapper = nil;
    PBMapper *mapper = [view pb_mapper];
    
    // Reset all the PBMapper properties for self and subviews
    [self _pb_resetMappersForView:view];
    
    [mapper initDataForView:view];
    if ([view conformsToProtocol:@protocol(PBDataFetching)]) {
        [(id<PBDataFetching>)view setDataUpdated:YES];
    }
    [mapper mapData:view.rootData forView:view];
}

- (void)pb_reloadClient
{
    [self pb_reloadClientForView:self];
}

- (BOOL)pb_reloadClientForView:(UIView *)view {
    if ([view conformsToProtocol:@protocol(PBDataFetching)]) {
        [[(id<PBDataFetching>)view fetcher] refetchData];
        return YES;
    }
    
    for (UIView *subview in view.subviews) {
        if ([self pb_reloadClientForView:subview]) {
            return YES;
        }
    }
    return NO;
}

- (void)pb_reloadLayout {
    [self.pb_layoutMapper reload];
    [self.pb_layoutMapper renderToView:self];
}

- (void)pb_unbindAll
{
    [self _pb_unbindView:self];
    [self _pb_didUnbindView:self];
}

- (void)pb_unbind
{
    NSDictionary *expressions = [self pb_expressions];
    if (expressions != nil) {
        for (NSString *key in expressions) {
            PBExpression *expression = [expressions objectForKey:key];
            [expression unbind:self forKeyPath:key];
        }
    }
    
    NSArray *mappers = [self pb_mappersForBinding];
    if (mappers != nil) {
        for (PBMapper *mapper in mappers) {
            [mapper unbind];
        }
    }
}

- (void)pb_didUnbind
{
    
}

- (NSArray *)pb_mappersForBinding {
    return nil;
}

- (void)_pb_didUnbindView:(UIView *)view {
    [view pb_didUnbind];
    for (UIView *subview in view.subviews) {
        [self _pb_didUnbindView:subview];
    }
}

- (void)_pb_resetView:(UIView *)view {
    [view pb_reset];
    for (UIView *subview in view.subviews) {
        [self _pb_resetView:subview];
    }
}

- (void)pb_reset
{
    self.data = nil;
    if ([self conformsToProtocol:@protocol(PBDataFetching)]) {
        [(id<PBDataFetching>)self setDataUpdated:YES];
    }
}

- (void)_pb_unbindView:(UIView *)view {
    [view pb_unbind];
    
    for (UIView *subview in view.subviews) {
        [self _pb_unbindView:subview];
    }
}

- (void)_pb_resetMappersForView:(UIView *)view {
    if ([view respondsToSelector:@selector(pb_resetMappers)]) {
        [(id) view pb_resetMappers];
    }
    for (UIView *subview in view.subviews) {
        [self _pb_resetMappersForView:subview];
    }
}

#pragma mark -
#pragma mark - KVC

- (void)pb_setValue:(id)value forKeyPath:(NSString *)key
{
    if ([key length] > 1 && [key characterAtIndex:0] == '+') {
        [self setValue:value forAdditionKey:[key substringFromIndex:1]];
    } else {
        id target = self;
        NSArray *keys = [key componentsSeparatedByString:@"."];
        NSUInteger N = keys.count;
        if (N > 1) {
            int i = 0;
            for (; i < N - 1; i++) {
                key = keys[i];
                if ([key characterAtIndex:0] == '@') {
                    key = [key substringFromIndex:1];
                    target = [target viewWithAlias:key];
                } else {
                    target = [target valueForKey:key];
                }
            }
            key = keys[i];
        }
        
        // Safely set value for key
        [PBPropertyUtils setValue:value forKey:key toObject:target failure:^{
            // Remove the unavailable key from constants and expressions
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF != %@", key];
            NSArray *properties = @[@"pb_constants", @"pb_expressions"];
            for (NSString *property in properties) {
                NSDictionary *value = [self valueForAdditionKey:property];
                if (value == nil) {
                    continue;
                }
                
                NSArray *keys = [value allKeys];
                NSArray *availableKeys = [keys filteredArrayUsingPredicate:predicate];
                if (keys.count != availableKeys.count) {
                    value = [value dictionaryWithValuesForKeys:availableKeys];
                    [self setValue:value forAdditionKey:property];
                }
            }
        }];
    }
}

- (id)pb_valueForKeyPath:(NSString *)key
{
    id target = self;
    NSArray *keys = [key componentsSeparatedByString:@"."];
    NSUInteger N = keys.count;
    if (N > 1) {
        int i = 0;
        for (; i < N - 1; i++) {
            key = keys[i];
            if ([key characterAtIndex:0] == '@') {
                key = [key substringFromIndex:1];
                target = [target viewWithAlias:key];
            } else {
                target = [target valueForKey:key];
            }
        }
        key = keys[i];
    }
    
    return [target valueForKey:key];
}

- (void)setMappable:(BOOL)mappable forKeyPath:(NSString *)keyPath
{
    if (self.pb_unmappableKeys == nil) {
        if (!mappable) {
            self.pb_unmappableKeys = [[NSMutableArray alloc] init];
            [self.pb_unmappableKeys addObject:keyPath];
        }
    } else {
        if (mappable) {
            [self.pb_unmappableKeys removeObject:keyPath];
        } else if (![self.pb_unmappableKeys containsObject:keyPath]) {
            [self.pb_unmappableKeys addObject:keyPath];
        }
    }
}

- (BOOL)mappableForKeyPath:(NSString *)keyPath
{
    id target = self;
    NSString *key = keyPath;
    NSArray *keys = [key componentsSeparatedByString:@"."];
    NSUInteger N = keys.count;
    if (N > 1) {
        int i = 0;
        for (; i < N - 1; i++) {
            key = keys[i];
            if ([key characterAtIndex:0] == '@') {
                key = [key substringFromIndex:1];
                target = [target viewWithAlias:key];
            } else {
                id temp = [target valueForKey:key];
                if (![temp isKindOfClass:[UIView class]]) {
                    break;
                }
                target = temp;
            }
        }
        key = keys[i];
        while (i < N - 1) {
            key = [key stringByAppendingFormat:@".%@", keys[i]];
            i++;
        }
    }
    
    NSArray *unmappableKeys = [target pb_unmappableKeys];
    return ![unmappableKeys containsObject:key];
}

- (void)setExpression:(NSString *)expression forKeyPath:(NSString *)keyPath
{
    PBMutableExpression *aExpression = [[PBMutableExpression alloc] initWithString:expression];
    if (aExpression == nil) {
        return;
    }
    
    NSMutableDictionary *expressions;
    if (self.pb_expressions == nil) {
        expressions = [[NSMutableDictionary alloc] init];
        self.pb_expressions = expressions;
    } else {
        expressions = [NSMutableDictionary dictionaryWithDictionary:self.pb_expressions];
    }
    [expressions setObject:aExpression forKey:keyPath];
    [self setValue:@(YES) forAdditionKey:@"pb_expressible"];
}

- (BOOL)hasExpressionForKeyPath:(NSString *)keyPath
{
    if (self.pb_expressions == nil) {
        return NO;
    }
    return [[self.pb_expressions allKeys] containsObject:keyPath];
}

- (UIViewController *)supercontroller
{
    id controller = self;
    while ((controller = [controller nextResponder]) != nil) {
        if ([controller isKindOfClass:[UIViewController class]]) {
            return PBVisibleController(controller);
        }
        
        if ([controller isKindOfClass:[UIWindow class]]) {
            return PBVisibleController([(id)controller rootViewController]);
        }
    }
    return controller;
}

- (id)rootData
{
    UIView * view = self;
    while (view != nil && view.plist == nil) {
        view = [view superview];
    }
    if (view == nil) {
        return nil;
    }
    return view.data;
}

- (id)superviewWithClass:(Class)clazz
{
    id view = [self superview];
    while (![view isKindOfClass:clazz]) {
        view = [view superview];
        if (view == nil) {
            break;
        }
    }
    return view;
}

- (UIView *)viewWithAlias:(NSString *)alias
{
    if (alias == nil) {
        return nil;
    }
    
    if ([alias isKindOfClass:[NSNumber class]]) {
        return [self viewWithTag:[alias integerValue]];
    }
    
    NSInteger tag;
    NSScanner *scanner = [NSScanner scannerWithString:alias];
    if ([scanner scanInteger:&tag]) {
        return [self viewWithTag:tag];
    }
    
    return [self _lookupViewWithAlias:alias];
}

- (UIView *)_lookupViewWithAlias:(NSString *)alias {
    if ([self.alias isEqualToString:alias]) {
        return self;
    }
    for (UIView *subview in self.subviews) {
        UIView *theView = [subview _lookupViewWithAlias:alias];
        if (theView != nil) {
            return theView;
        }
    }
    return nil;
}

#pragma mark - Addition properties

- (void)setPb_unmappableKeys:(NSMutableArray *)keys {
    [self setValue:keys forAdditionKey:@"pb_unmappableKeys"];
}

- (NSMutableArray *)pb_unmappableKeys {
    return [self valueForAdditionKey:@"pb_unmappableKeys"];
}

- (void)setPb_constants:(NSDictionary *)constants {
    NSDictionary *orgConstants = self.pb_constants;
    if (orgConstants != nil) {
        // Check if any key has been removed.
        NSArray *orgKeys = [orgConstants allKeys];
        NSArray *newKeys = [constants allKeys];
        NSArray *removedKeys;
        if (constants == nil || newKeys.count == 0) {
            removedKeys = orgKeys;
        } else {
            NSPredicate *pd = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", [constants allKeys]];
            removedKeys = [[orgConstants allKeys] filteredArrayUsingPredicate:pd];
        }
        
        if (removedKeys.count > 0) {
            // Reset the default value for the key removed.
            [self setDefaultValueForKeys:removedKeys];
        }
    }
    
    [self setValue:constants forAdditionKey:@"pb_constants"];
}

- (NSDictionary *)pb_constants {
    return [self valueForAdditionKey:@"pb_constants"];
}

- (void)setDefaultValueForKeys:(NSArray *)keys {
    UIView *temp = [[[self class] alloc] init];
    for (NSString *key in keys) {
        id defaultValue = [temp pb_valueForKeyPath:key];
        [self pb_setValue:defaultValue forKeyPath:key];
    }
}

- (void)setPb_expressions:(NSDictionary *)expressions {
    NSDictionary *orgExpressions = self.pb_expressions;
    if (orgExpressions != nil) {
        // Check if any key has been removed.
        NSArray *orgKeys = [orgExpressions allKeys];
        NSArray *newKeys = [expressions allKeys];
        NSArray *removedKeys;
        if (expressions == nil || newKeys.count == 0) {
            removedKeys = orgKeys;
        } else {
            NSPredicate *pd = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", [expressions allKeys]];
            removedKeys = [[orgExpressions allKeys] filteredArrayUsingPredicate:pd];
        }
        
        if (removedKeys.count > 0) {
            // Clear the value for the key removed.
            for (NSString *key in removedKeys) {
                PBExpression *expression = [orgExpressions objectForKey:key];
                [expression unbind:self forKeyPath:key];
            }
            [self setDefaultValueForKeys:removedKeys];
        }
    }
    
    [self setValue:expressions forAdditionKey:@"pb_expressions"];
}

- (NSDictionary *)pb_expressions {
    return [self valueForAdditionKey:@"pb_expressions"];
}

- (void)set_pbPlistURL:(NSURL *)value {
    [self setValue:value forAdditionKey:@"_pbPlistURL"];
}

- (NSURL *)_pbPlistURL {
    return [self valueForAdditionKey:@"_pbPlistURL"];
}

- (void)setPB_internalMapper:(PBMapper *)value {
    [self setValue:value forAdditionKey:@"PB_internalMapper"];
}

- (PBMapper *)PB_internalMapper {
    return [self valueForAdditionKey:@"PB_internalMapper"];
}

- (void)setPlist:(NSString *)value {
    [self setValue:value forAdditionKey:@"plist"];
    if (self._pbPlistURL == nil) {
        [self pb_setInitialData:self.data];
        self._pbPlistURL = PBResourceURL(self.plist, @"plist");
        [self _pb_initData];
    }
}

- (NSString *)plist {
    return [self valueForAdditionKey:@"plist"];
}

- (void)setData:(id)value {
    // If the `data' changed, then we needs to be reload
    id data = self.data;
    if (data == nil) {
        if (value != nil) {
            if ([self conformsToProtocol:@protocol(PBDataFetching)]) {
                [(id<PBDataFetching>)self setDataUpdated:YES];
            }
        }
    } else if (![data isEqual:value]) {
        if ([self conformsToProtocol:@protocol(PBDataFetching)]) {
            [(id<PBDataFetching>)self setDataUpdated:YES];
        }
    }
    
    [self setValue:value forAdditionKey:@"data"];
}

- (id)data {
    return [self valueForAdditionKey:@"data"];
}

- (void)pb_setInitialData:(id)value {
    [self setValue:value forAdditionKey:@"initialData"];
}

- (id)pb_initialData {
    return [self valueForAdditionKey:@"initialData"];
}

- (void)setLoadingDelegate:(id<PBViewLoadingDelegate>)value {
    [self setValue:value forAdditionKey:@"loadingDelegate"];
}

- (id<PBViewLoadingDelegate>)loadingDelegate {
    return [self valueForAdditionKey:@"loadingDelegate"];
}

- (void)setPb_preparation:(void (^)(void))value {
    [self setValue:value forAdditionKey:@"pb_preparation"];
}

- (void (^)(void))pb_preparation {
    return [self valueForAdditionKey:@"pb_preparation"];
}

- (void)setPb_transformation:(id (^)(id, NSError *))value {
    [self setValue:value forAdditionKey:@"pb_transformation"];
}

- (id (^)(id, NSError *))pb_transformation {
    return [self valueForAdditionKey:@"pb_transformation"];
}

- (void)setPb_complection:(void (^)(void))value {
    [self setValue:value forAdditionKey:@"pb_complection"];
}

- (void (^)(void))pb_complection {
    return [self valueForAdditionKey:@"pb_complection"];
}

- (void)setPb_loadingCount:(NSInteger)value {
    [self setValue:[NSNumber numberWithInteger:value] forAdditionKey:@"pb_loadingCount"];
}

- (NSInteger)pb_loadingCount {
    return [[self valueForAdditionKey:@"pb_loadingCount"] integerValue];
}

- (void)setPb_interrupted:(BOOL)value {
    [self setValue:[NSNumber numberWithBool:value] forAdditionKey:@"pb_interrupted"];
}

- (BOOL)pb_interrupted {
    return [[self valueForAdditionKey:@"pb_interrupted"] boolValue];
}

- (void)setAlias:(NSString *)alias {
    [self setValue:alias forAdditionKey:@"alias"];
}

- (NSString *)alias {
    return [self valueForAdditionKey:@"alias"];
}

- (void)setPb_layoutName:(NSString *)name {
    [self setValue:name forAdditionKey:@"pb_layoutName"];
}

- (NSString *)pb_layoutName {
    return [self valueForAdditionKey:@"pb_layoutName"];
}

- (void)setPb_layoutMapper:(PBLayoutMapper *)mapper {
    [self setValue:mapper forAdditionKey:@"pb_layoutMapper"];
}

- (PBLayoutMapper *)pb_layoutMapper {
    return [self valueForAdditionKey:@"pb_layoutMapper"];
}

@end
