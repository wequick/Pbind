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
#import "UIView+PBLayoutConstraint.h"

@interface _PBPlistProperties : NSObject

@property (nonatomic, copy) NSString *plist;
@property (nonatomic, strong) NSDictionary *constants;
@property (nonatomic, strong) NSDictionary *expressions;

@end

@implementation _PBPlistProperties

@end

@interface Pbind (UIView)

+ (NSArray *)viewValueSetters;

+ (NSArray *)viewValueAsyncSetters;

@end

@implementation UIView (Pbind)

@dynamic data;

- (PBMapper *)pb_mapper
{
    // Lazy init
    if (self.PB_internalMapper == nil) {
        if (self._pbPlistURL != nil) {
            self.PB_internalMapper = [PBMapper mapperWithContentsOfURL:self._pbPlistURL];
            self.PB_internalMapper.plist = self.plist;
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

- (void)pb_mapData:(id)data
{
    [self pb_mapData:data underType:PBMapToAll dataTag:PBDataTagUnset];
}

- (void)pb_mapData:(id)data forKey:(NSString *)key
{
    if (key == nil) {
        return;
    }
    [self pb_mapData:data forKeys:@[key] withContext:self underType:PBMapToAll dataTag:PBDataTagUnset];
}

- (void)pb_mapData:(id)data withContext:(UIView *)context {
    [self pb_mapData:data withContext:context underType:PBMapToAll dataTag:PBDataTagUnset];
}

- (void)pb_mapData:(id)data underType:(PBMapType)type dataTag:(unsigned char)tag
{
    [self pb_mapData:data withContext:self underType:type dataTag:tag];
}

- (void)pb_mapData:(id)data withContext:(UIView *)context underType:(PBMapType)type dataTag:(unsigned char)tag
{
    [self pb_mapData:data forKeys:nil withContext:context underType:type dataTag:tag];
    
    // Recursive
    BOOL canReload = [self respondsToSelector:@selector(reloadData)];
    if (!canReload) {
        for (UIView *subview in [self subviews]) {
            [subview pb_mapData:data withContext:context underType:type dataTag:tag];
        }
    } else {
        if (type == PBMapToContext && self.frame.size.height == 0) {
            return;
        }
        [(id)self reloadData];
    }
}

- (void)pb_mapData:(id)data forKeys:(NSArray *)keys withContext:(UIView *)context underType:(PBMapType)type dataTag:(unsigned char)tag
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
        
        [exp mapData:data toTarget:self forKeyPath:key inContext:context];
    }
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
        UIView<PBDataFetching> *fetchingView = (id) view;
        PBDataFetcher *fetcher = [fetchingView fetcher];
        if (fetcher == nil) {
            fetcher = [[PBDataFetcher alloc] init];
            fetcher.owner = fetchingView;
            fetchingView.fetcher = fetcher;
        }
        [fetcher refetchData];
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
    [self pb_mapData:self.rootData];
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

- (void)pb_setValue:(id)value forKeyPath:(NSString *)keyPath
{
    char initial = 0;
    if (keyPath.length > 1) {
        initial = [keyPath characterAtIndex:0];
    }
    
    if (initial == '+') {
        [self setValue:value forAdditionKey:[keyPath substringFromIndex:1]];
    } else {
        id target = self;
        NSArray *keys = [keyPath componentsSeparatedByString:@"."];
        NSUInteger N = keys.count;
        NSValue *structValue = nil;
        NSUInteger structKeyIndex = 0;
        NSString *key = keyPath;
        if (N > 1) {
            int i = 0;
            for (; i < N - 1; i++) {
                key = keys[i];
                if ([key characterAtIndex:0] == '@') {
                    key = [key substringFromIndex:1];
                    target = [target viewWithAlias:key];
                } else {
                    id temp = [target valueForKey:key];
                    if ([temp isKindOfClass:[NSValue class]]) {
                        structValue = temp;
                        structKeyIndex = i + 1;
                        break;
                    }
                    target = temp;
                }
            }
            key = keys[i];
        }
        
        if (structValue != nil) {
            value = [self pb_valueByRewrapValue:structValue withSubvalue:value forKeys:keys index:structKeyIndex];
        }
        
        // Check if needs set value asynchronously
        initial = 0;
        if (key.length > 1) {
            initial = [key characterAtIndex:0];
        }
        if (initial == '~') {
            [target setValue:value forAdditionKey:key];
            
            NSArray *asyncSetters = [Pbind viewValueAsyncSetters];
            key = [key substringFromIndex:1];
            CGSize size = [target pb_constraintSize];
            for (PBViewValueAsyncSetter asyncSetter in asyncSetters) {
                asyncSetter(target, key, value, size, self, keyPath);
            }
            return;
        }
        
        // Invoke user-defined value setter
        NSArray *valueSetters = [Pbind viewValueSetters];
        if (valueSetters != nil) {
            BOOL canceld = NO;
            for (PBViewValueSetter setter in valueSetters) {
                value = setter(target, key, value, &canceld, self, keyPath);
                if (canceld) {
                    return;
                }
            }
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

- (NSValue *)pb_valueByRewrapValue:(NSValue *)value withSubvalue:(id)subvalue forKeys:(NSArray *)keys index:(NSUInteger)index {
    NSUInteger N = keys.count - index;
    const char *type = [value objCType];
    if (N == 1) {
        if (strcmp(type, @encode(CGPoint)) == 0) {
            CGPoint point = [value CGPointValue];
            NSString *key = keys[index];
            if ([key isEqualToString:@"x"]) {
                // center.x
                point.x = [subvalue doubleValue];
            } else {
                // center.y
                point.y = [subvalue doubleValue];
            }
            return [NSValue valueWithCGPoint:point];
        } else if (strcmp(type, @encode(CGRect)) == 0) {
            CGRect rect = [value CGRectValue];
            NSString *key = keys[index];
            if ([key isEqualToString:@"origin"]) {
                // frame.origin
                rect.origin = [subvalue CGPointValue];
            } else if ([key isEqualToString:@"size"]) {
                // frame.size
                rect.size = [subvalue CGSizeValue];
            }
            return [NSValue valueWithCGRect:rect];
        } else if (strcmp(type, @encode(CGAffineTransform)) == 0) {
            CGAffineTransform transform = [value CGAffineTransformValue];
            NSString *key = keys[index];
            if ([key isEqualToString:@"scale"]) {
                // transform.scale
                transform.a = transform.d = [subvalue doubleValue];
            } else if ([key isEqualToString:@"translation"]) {
                // transform.translation
                CGPoint translation = [subvalue CGPointValue];
                transform.tx = translation.x;
                transform.ty = translation.y;
            }
            return [NSValue valueWithCGAffineTransform:transform];
        }
    } else if (N == 2) {
        if (strcmp(type, @encode(CGRect)) == 0) {
            CGRect rect = [value CGRectValue];
            NSString *key = keys[index];
            NSString *key2 = keys[index + 1];
            if ([key isEqualToString:@"origin"]) {
                if ([key2 isEqualToString:@"x"]) {
                    // frame.origin.x
                    rect.origin.x = [subvalue doubleValue];
                } else if ([key2 isEqualToString:@"y"]) {
                    // frame.origin.y
                    rect.origin.y = [subvalue doubleValue];
                }
            } else if ([key isEqualToString:@"size"]) {
                if ([key2 isEqualToString:@"width"]) {
                    // frame.size.width
                    rect.size.width = [subvalue doubleValue];
                } else if ([key2 isEqualToString:@"height"]) {
                    // frame.size.height
                    rect.size.height = [subvalue doubleValue];
                }
            }
            return [NSValue valueWithCGRect:rect];
        } else if (strcmp(type, @encode(CGAffineTransform)) == 0) {
            CGAffineTransform transform = [value CGAffineTransformValue];
            NSString *key = keys[index];
            NSString *key2 = keys[index + 1];
            if ([key isEqualToString:@"scale"]) {
                if ([key2 isEqualToString:@"x"]) {
                    // transform.scale.x
                    transform.a = [subvalue doubleValue];
                } else if ([key2 isEqualToString:@"y"]) {
                    // transform.scale.x
                    transform.d = [subvalue doubleValue];
                }
            } else if ([key isEqualToString:@"translation"]) {
                if ([key2 isEqualToString:@"x"]) {
                    // transform.translation.x
                    transform.tx = [subvalue doubleValue];
                } else if ([key2 isEqualToString:@"y"]) {
                    // transform.translation.x
                    transform.ty = [subvalue doubleValue];
                }
            }
            return [NSValue valueWithCGAffineTransform:transform];
        }
    }
    return value;
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
                target = [target valueForKeyPath:key];
            }
        }
        key = keys[i];
    }
    
    char initial = 0;
    if (key.length > 1) {
        initial = [key characterAtIndex:0];
    }
    if (initial == '~') {
        return [target valueForAdditionKey:key];
    } else if (initial == '+') {
        return [target valueForAdditionKey:[key substringFromIndex:1]];
    }
    
    return [PBPropertyUtils valueForKeyPath:key ofObject:target failure:nil];
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
        [self setValue:expressions forAdditionKey:@"pb_expressions"];
    } else {
        expressions = [NSMutableDictionary dictionaryWithDictionary:self.pb_expressions];
    }
    [expressions setObject:aExpression forKey:keyPath];
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
    
    return [self _pb_lookupViewWithAlias:alias];
}

#pragma mark - Mapping

- (void)pb_setConstants:(NSDictionary *)constants fromPlist:(NSString *)plist {
    [self _pb_setProperties:constants expressive:NO fromPlist:plist];
}

- (void)pb_setExpressions:(NSDictionary *)expressions fromPlist:(NSString *)plist {
    [self _pb_setProperties:expressions expressive:YES fromPlist:plist];
}

#pragma mark - Addition properties

- (NSMutableDictionary *)pb_constantKeys {
    return [self valueForAdditionKey:@"pb_constantKeys"];
}

- (void)setPb_constantKeys:(NSMutableDictionary *)keys {
    [self setValue:keys forAdditionKey:@"pb_constantKeys"];
}

- (NSMutableDictionary *)pb_expressionKeys {
    return [self valueForAdditionKey:@"pb_expressionKeys"];
}

- (void)setPb_expressionKeys:(NSMutableDictionary *)keys {
    [self setValue:keys forAdditionKey:@"pb_expressionKeys"];
}

- (void)setPb_unmappableKeys:(NSMutableArray *)keys {
    [self setValue:keys forAdditionKey:@"pb_unmappableKeys"];
}

- (NSMutableArray *)pb_unmappableKeys {
    return [self valueForAdditionKey:@"pb_unmappableKeys"];
}

- (NSDictionary *)pb_constants {
    NSArray *properties = [self valueForAdditionKey:@"pb_properties"];
    if (properties.count == 0) {
        return nil;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (_PBPlistProperties *pp in properties) {
        [dict addEntriesFromDictionary:pp.constants];
    }
    return dict.count > 0 ? dict : nil;
//    return [self valueForAdditionKey:@"pb_constants"];
}

- (NSDictionary *)pb_expressions {
    NSArray *properties = [self valueForAdditionKey:@"pb_properties"];
    if (properties.count == 0) {
        return nil;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (_PBPlistProperties *pp in properties) {
        [dict addEntriesFromDictionary:pp.expressions];
    }
    return dict.count > 0 ? dict : nil;
//    return [self valueForAdditionKey:@"pb_expressions"];
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

#pragma mark - Internal

- (void)_pb_setProperties:(NSDictionary *)properties expressive:(BOOL)expressive fromPlist:(NSString *)plist {
    if (plist == nil || [plist isEqual:[NSNull null]]) {
        plist = @"";
    }
    
    _PBPlistProperties *pp = nil;
    NSMutableArray *pps = [self valueForAdditionKey:@"pb_properties"];
    if (pps != nil) {
        // 已经缓存，根据 plist 找出其对应的属性集
        NSArray *filters = [pps filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"plist = %@", plist]];
        if (filters.count > 0) {
            pp = [filters firstObject];
        }
        
        if (pp == nil) {
            // 未添加该 plist 对应的属性
            pp = [[_PBPlistProperties alloc] init];
            pp.plist = plist;
            if (expressive) {
                pp.expressions = properties;
            } else {
                pp.constants = properties;
            }
            [pps addObject:pp];
        } else {
            // 已添加该 plist 对应的属性，更新之
            NSDictionary *oldProperties;
            if (expressive) {
                oldProperties = pp.expressions;
                pp.expressions = properties;
            } else {
                oldProperties = pp.constants;
                pp.constants = properties;
            }
            
            // 检查是否有 删除 发生
            NSArray *newKeys = [properties allKeys];
            NSArray *oldKeys = [oldProperties allKeys];
            if (oldKeys.count > 0) {
                NSArray *removedKeys;
                if (newKeys.count == 0) {
                    removedKeys = oldKeys;
                } else {
                    NSPredicate *pd = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", newKeys];
                    removedKeys = [oldKeys filteredArrayUsingPredicate:pd];
                }
                
                if (removedKeys.count > 0) {
                    // 部分属性在当前 plist 被移除了，检查其他 plist 是否存在该配置，如果全部不存在，将该属性赋予初始值
                    NSMutableArray *realRemovedKeys = [NSMutableArray arrayWithArray:removedKeys];
                    NSPredicate *pd = [NSPredicate predicateWithFormat:@"SELF IN %@", removedKeys];
                    for (_PBPlistProperties *temp in pps) {
                        if (temp == pp) {
                            continue;
                        }
                        
                        NSDictionary *tempProperties = expressive ? temp.expressions : temp.constants;
                        NSArray *existedKeys = [[tempProperties allKeys] filteredArrayUsingPredicate:pd];
                        if (existedKeys.count > 0) {
                            [realRemovedKeys removeObjectsInArray:existedKeys];
                            pd = [NSPredicate predicateWithFormat:@"SELF IN %@", realRemovedKeys];
                        }
                    }
                    
                    if (realRemovedKeys.count > 0) {
                        if (expressive) {
                            // Unbind expression
                            for (NSString *key in realRemovedKeys) {
                                PBExpression *expression = [oldProperties objectForKey:key];
                                [expression unbind:self forKeyPath:key];
                            }
                        }
                        // Reset the default value for the key removed.
                        [self _pb_setDefaultValueForKeys:realRemovedKeys];
                    }
                }
            }
        }

    } else {
        // 首次添加
        if (properties == nil) {
            return;
        }
        
        pp = [[_PBPlistProperties alloc] init];
        pp.plist = plist;
        if (expressive) {
            pp.expressions = properties;
        } else {
            pp.constants = properties;
        }
        pps = [[NSMutableArray alloc] init];
        [pps addObject:pp];
        
        [self setValue:pps forAdditionKey:@"pb_properties"];
    }
}

- (void)_pb_setDefaultValueForKeys:(NSArray *)keys {
    UIView *temp = [[[self class] alloc] init];
    for (NSString *key in keys) {
        id defaultValue = [temp pb_valueForKeyPath:key];
        [self pb_setValue:defaultValue forKeyPath:key];
    }
}

- (UIView *)_pb_lookupViewWithAlias:(NSString *)alias {
    if ([self.alias isEqualToString:alias]) {
        return self;
    }
    for (UIView *subview in self.subviews) {
        UIView *theView = [subview _pb_lookupViewWithAlias:alias];
        if (theView != nil) {
            return theView;
        }
    }
    return nil;
}

@end
