//
//  UIView+Pbind.m
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "UIView+Pbind.h"
#import "UIView+PBLayout.h"
#import "Pbind.h"
#import "PBClient.h"
#import "PBMapper.h"
#import "PBCompat.h"
#import "PBMutableExpression.h"
#import "PBClientMapper.h"
#import "PBArray.h"

NSString *const PBViewDidStartLoadNotification = @"PBViewDidStartLoadNotification";
NSString *const PBViewDidFinishLoadNotification = @"PBViewDidFinishLoadNotification";
NSString *const PBViewHasHandledLoadErrorKey = @"PBViewHasHandledLoadError";

NSString *const PBViewDidClickHrefNotification = @"PBViewDidClickHref";
NSString *const PBViewHrefKey = @"href";

@interface PBClient (Private)

- (void)_loadRequest:(PBRequest *)request mapper:(PBClientMapper *)mapper notifys:(BOOL)notifys complection:(void (^)(PBResponse *))complection;

@end

@interface UIView (Pbind_Private)

@property (nonatomic, strong) NSArray *_pbClients;
@property (nonatomic, strong) NSArray *_pbClientMappers;
@property (nonatomic, strong) NSDictionary *_pbActionClients;
@property (nonatomic, strong) NSDictionary *_pbActionMappers;

@end

@implementation UIView (Pbind)

@dynamic client;
@dynamic clients;
@dynamic data;
@dynamic needsLoad;

DEF_DYNAMIC_PROPERTY(PB_additionValues, setPB_additionValues, NSMutableDictionary *)
DEF_DYNAMIC_PROPERTY(pb_unmappableKeys, setPb_unmappableKeys, NSMutableArray *)

DEF_UNDEFINED_PROPERTY(NSURL *, _pbPlistURL);
DEF_UNDEFINED_PROPERTY(NSArray *, _pbClients);
DEF_UNDEFINED_PROPERTY(NSDictionary *, _pbActionClients);
DEF_UNDEFINED_PROPERTY(NSArray *, _pbClientMappers);
DEF_UNDEFINED_PROPERTY(PBMapper *, PB_internalMapper);
DEF_UNDEFINED_PROPERTY(NSDictionary *, _pbActionMappers);

DEF_UNDEFINED_PROPERTY2(NSString *, plist, setPlist)
DEF_UNDEFINED_PROPERTY2(NSArray *, clients, setClients)
DEF_UNDEFINED_PROPERTY2(NSDictionary *, actions, setActions)
DEF_UNDEFINED_PROPERTY2(NSString *, client, setClient)
DEF_UNDEFINED_PROPERTY2(NSString *, clientAction, setClientAction)
DEF_UNDEFINED_PROPERTY2(NSDictionary *, clientParams, setClientParams)
DEF_UNDEFINED_PROPERTY2(id, data, setData)
DEF_UNDEFINED_PROPERTY2(NSString *, href, setHref)
DEF_UNDEFINED_PROPERTY2(id<PBViewLoadingDelegate>, loadingDelegate, setLoadingDelegate)

DEF_UNDEFINED_INT_PROPERTY(pb_loadingCount, setPb_loadingCount, 0)
DEF_UNDEFINED_BOOL_PROPERTY(pb_interrupted, setPb_interrupted, NO)
DEF_UNDEFINED_BOOL_PROPERTY(showsLoadingCover, setShowsLoadingCover, YES) //void (^)(void)
DEF_UNDEFINED_PROPERTY2(void (^)(void), pb_pbeparation, setPb_pbeparation)
DEF_UNDEFINED_PROPERTY2(id (^)(id, NSError *), pb_transformation, setPb_transformation)

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow == nil) {
        if (self.pb_loading) {
            // If super controller is neither a singleton nor a child of `UITabBarController', mark interrupted flag to reload at next appearance
            if (![[[[self supercontroller] navigationController] parentViewController] isKindOfClass:[UITabBarController class]]) {
                self.pb_interrupted = YES;
                [self pb_cancelPull];
            }
        }
    } else {
        if (self.plist != nil && self._pbPlistURL == nil) {
            self._pbPlistURL = [self pb_URLForResource:self.plist withExtension:@"plist"];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
               dispatch_sync(dispatch_get_main_queue(), ^{
                   [[self pb_mapper] initDataForView:self];
               });
            });
        }
        if (self.pb_interrupted) {
            self.pb_interrupted = NO;
            [self pb_repullData];
        }
    }
}

- (NSURL *)pb_URLForResource:(NSString *)resource withExtension:(NSString *)extension
{
    NSArray *preferredBundles = @[[NSBundle bundleForClass:self.supercontroller.class],
                                  /* [NSBundle bundleWithPath:patchPath], */
                                  [NSBundle mainBundle]];
    for (NSBundle *bundle in preferredBundles) {
        NSURL *url = [bundle URLForResource:resource withExtension:extension];
        if (url != nil) {
            return url;
        }
    }
    return nil;
}

- (NSArray *)pb_clientMappers
{
    if (self._pbClientMappers != nil) return self._pbClientMappers;
    
    // Lazy init
    if (self.clients == nil) {
        if (self.client == nil) return nil;
        
        PBClientMapper *mapper = [[PBClientMapper alloc] init];
        mapper.clazz = self.client;
        mapper.action = self.clientAction;
        mapper.params = self.clientParams;
        self._pbClientMappers = @[mapper];
        return self._pbClientMappers;
    } else {
        NSMutableArray *mappers = [NSMutableArray arrayWithCapacity:self.clients.count];
        for (id data in self.clients) {
            PBClientMapper *mapper = [PBClientMapper mapperWithDictionary:data];
            [mappers addObject:mapper];
        }
        self._pbClientMappers = mappers;
        return mappers;
    }
}

- (NSArray *)pb_clients
{
    if (self._pbClients != nil) return self._pbClients;
    
    if (self.pb_clientMappers == nil) return nil;
    
    NSMutableArray *clients = [NSMutableArray arrayWithCapacity:self.clients.count];
    for (PBClientMapper *mapper in self.pb_clientMappers) {
        PBClient *client = [PBClient clientWithName:mapper.clazz];
        client.delegate = (id) self;
        [clients addObject:client];
    }
    self._pbClients = clients;
    return clients;
}

- (NSDictionary *)pb_actionMappers
{
    if (self._pbActionMappers != nil) return self._pbActionMappers;
    
    if (self.actions == nil) return nil;
    
    NSMutableDictionary *mappers = [NSMutableDictionary dictionaryWithCapacity:self.actions.count];
    for (NSString *key in self.actions) {
        PBClientMapper *mapper = [PBClientMapper mapperWithDictionary:self.actions[key]];
        [mapper initDataForView:self];
        [mappers setObject:mapper forKey:key];
    }
    self._pbActionMappers = mappers;
    return mappers;
}

- (NSDictionary *)pb_actionClients
{
    if (self._pbActionClients != nil) return self._pbActionClients;
    
    if (self.pb_actionMappers == nil) return nil;
    
    NSMutableDictionary *clients = [NSMutableDictionary dictionaryWithCapacity:self.pb_actionMappers.count];
    for (NSString *key in self.pb_actionMappers) {
        PBClientMapper *mapper = [self.pb_actionMappers objectForKey:key];
        PBClient *client = [PBClient clientWithName:mapper.clazz];
        client.delegate = (id) self;
        [clients setObject:client forKey:key];
    }
    self._pbActionClients = clients;
    return clients;
}

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

- (BOOL)pb_loading
{
    return self.pb_loadingCount > 0;
}

- (void)pb_pullData
{
    [self pb_pullDataWithPreparation:nil transformation:nil];
}

- (void)pb_pullDataWithPreparation:(void (^)(void))preparation transformation:(id (^)(id, NSError *))transformation
{
    if (self.pb_loading) {
        return;
    }
    
    if (self.pb_clientMappers == nil) {
        return;
    }
    
    if (self.pb_clients == nil) {
        return;
    }
    
    if (preparation) {
        preparation();
    }
    
    // Notify loading start
    [[NSNotificationCenter defaultCenter] postNotificationName:PBViewDidStartLoadNotification object:self];
    
    self.pb_pbeparation = preparation;
    self.pb_transformation = transformation;
    NSInteger N = self.pb_clients.count;
    self.pb_loadingCount = (int) N;
    
    // Init null data
    self.data = [PBArray arrayWithCapacity:self.clients.count];
    for (NSInteger i = 0; i < N; i++) {
        [self.data addObject:[NSNull null]];
    }
    
    // Load request parallel
    for (NSInteger i = 0; i < N; i++) {
        PBClient *client = [self.pb_clients objectAtIndex:i];
        PBClientMapper *mapper = [self.pb_clientMappers objectAtIndex:i];
        [mapper updateWithData:self.data andView:self];
        
        Class requestClass = [client.class requestClass];
        PBRequest *request = [[requestClass alloc] init];
        request.action = mapper.action;
        request.params = mapper.params;
//        if ([self.loadingDelegate respondsToSelector:@selector(pullParamsForView:)]) {
//            request.params = [self.loadingDelegate pullParamsForView:self];
//        } else {
//            request.params = self.clientParams;
//        }
        [client _loadRequest:request mapper:nil notifys:NO complection:^(PBResponse *response) {
            BOOL handledError = NO;
            if ([self.loadingDelegate respondsToSelector:@selector(view:didFinishLoading:handledError:)]) {
                [self.loadingDelegate view:self didFinishLoading:response handledError:&handledError];
            }
            NSDictionary *userInfo = nil;
            if (response != nil) {
                userInfo = @{PBResponseKey:response, PBViewHasHandledLoadErrorKey:@(handledError)};
            } else {
                userInfo = @{PBViewHasHandledLoadErrorKey:@(handledError)};
            }
            
            [client cancel];
            
            id data = response.data;
            if (transformation) {
                data = transformation(data, response.error);
            }
            if (data) {
                self.pb_pbeparation = nil;
                self.pb_transformation = nil;
                self.data[i] = data;
                [self pb_mapData:self.rootData];
                [self layoutIfNeeded];
            }
            
            self.pb_loadingCount--;
            if (self.pb_loadingCount == 0) {
                // Notify loading finish
                [[NSNotificationCenter defaultCenter] postNotificationName:PBViewDidFinishLoadNotification object:self userInfo:userInfo];
            }
        }];
    }
}

- (void)pb_repullData
{
    [self pb_pullDataWithPreparation:self.pb_pbeparation transformation:self.pb_transformation];
}

- (void)pb_loadData:(id)data
{
    [self pb_initData];
    
    [self setData:data];
    [self pb_mapData:self.rootData];
    
    [self layoutIfNeeded];
}

- (void)pb_mapData:(id)data
{
    if ([self pb_mapper] == nil) {
        [self pb_mapData:data];
        return;
    }
    [[self pb_mapper] mapData:data forView:self];
}

- (void)pb_initData
{
    if ([self pb_mapper] == nil) {
        return;
    }
    [[self pb_mapper] initDataForView:self];
}

- (void)pb_cancelPull
{
    if (self.pb_clients == nil) return;
    
    for (PBClient *client in self.pb_clients) {
        [client cancel];
    }
    self.pb_loadingCount = 0;
}

- (void)pb_clickHref:(NSString *)href
{
    if (href == nil) {
        return;
    }
    
    NSURL *url;
    NSDictionary *userInfo = nil;
    NSRange range = [href rangeOfString:@"?"];
    if (range.location != NSNotFound) {
        url = [NSURL URLWithString:[href substringToIndex:range.location]];
        NSString *query = [href substringFromIndex:range.location + 1];
        NSMutableDictionary *queries = [[NSMutableDictionary alloc] init];
        NSArray *pairs = [query componentsSeparatedByString:@"&"];
        for (NSString *pair in pairs) {
            NSRange range = [pair rangeOfString:@"="];
            if (range.location != NSNotFound) {
                NSString *key = [pair substringToIndex:range.location];
                NSString *value = [pair substringFromIndex:range.location + 1];
                queries[key] = value;
            }
        }
        userInfo = queries;
    } else {
        url = [NSURL URLWithString:href];
    }
    
    NSString *scheme = url.scheme;
    if ([scheme isEqualToString:@"note"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:url.host object:self userInfo:userInfo];
    } else if ([scheme isEqualToString:@"ctl"]) {
        // Call a view controller method
        UIViewController *controller = [self supercontroller];
        SEL action = NSSelectorFromString([NSString stringWithFormat:@"%@:", url.host]);
        if ([controller respondsToSelector:action]) {
            [self setValue:userInfo forAdditionKey:@"hrefParams"];
            IMP imp = [controller methodForSelector:action];
            PBCallControllerFunc func = (PBCallControllerFunc)imp;
            func(controller, action, self);
        }
    } else if ([scheme isEqualToString:@"push"]) {
        // Push to a view controller
        UIViewController *controller = [self supercontroller];
        UIViewController *nextController = [[NSClassFromString(url.host) alloc] init];
        [controller.navigationController pushViewController:nextController animated:YES];
    } else if ([scheme isEqualToString:@"action"]) {
        NSString *action = url.host;
        if ([action length] == 1) {
            NSDictionary *clients = [self pb_actionClients];
            PBClient *client = [clients objectForKey:action];
            if (client == nil) {
                return;
            }
            
            NSDictionary *mappers = [self pb_actionMappers];
            PBClientMapper *mapper = [mappers objectForKey:action];
            [mapper updateWithData:self.data andView:self];
            PBRequest *request = [[[client.class requestClass] alloc] init];
            request.action = mapper.action;
            request.params = mapper.params;
            [client _loadRequest:request mapper:mapper notifys:YES complection:^(PBResponse *response) {
                if (response.error == nil) {
                    if (mapper.successHref != nil) {
                        [self pb_clickHref:mapper.successHref];
                    }
                }
            }];
        } else if ([action isEqualToString:@"alert"]) {
            // Show alert
            NSString *title = userInfo[@"title"];
            NSString *msg = userInfo[@"msg"];
            NSArray *buttonTitles = [userInfo[@"btns"] componentsSeparatedByString:@"|"];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
            [self setValue:alert forAdditionKey:@"__alert"];
            int buttonCount = (int) buttonTitles.count;
            NSDictionary *mappers = [self pb_actionMappers];
            NSDictionary *clients = [self pb_actionClients];
            for (int index = 0; index < buttonCount; index++) {
                NSString *buttonTitle = [buttonTitles objectAtIndex:index];
                NSString *key = [NSString stringWithFormat:@"%i", (int) index];
                PBClient *client = [clients objectForKey:key];
                UIAlertActionStyle style = (index == 0) ? UIAlertActionStyleCancel : UIAlertActionStyleDefault;
                if (client == nil) {
                    [alert addAction:[UIAlertAction actionWithTitle:buttonTitle style:style handler:^(UIAlertAction *alertAction) {
                        [self setValue:nil forAdditionKey:@"__alert"];
                    }]];
                } else {
                    [alert addAction:[UIAlertAction actionWithTitle:buttonTitle style:style handler:^(UIAlertAction *alertAction) {
                        [self setValue:nil forAdditionKey:@"__alert"];
                        
                        PBClientMapper *mapper = [mappers objectForKey:key];
                        [mapper updateWithData:self.data andView:self];
                        
                        PBRequest *request = [[[client.class requestClass] alloc] init];
                        request.action = mapper.action;
                        request.params = mapper.params;
                        
                        [client _loadRequest:request mapper:mapper notifys:YES complection:^(PBResponse *response) {
                            if (response.error == nil) {
                                if (mapper.successHref != nil) {
                                    [self pb_clickHref:mapper.successHref];
                                }
                            }
                        }];
                    }]];
                }
            }
            [self.supercontroller presentViewController:alert animated:YES completion:nil];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PBViewDidClickHrefNotification object:self userInfo:@{@"href":href}];
}

#pragma mark -
#pragma mark - KVC

- (void)setValue:(id)value forKey:(NSString *)key
{
    if ([key length] > 1 && [key characterAtIndex:0] == '+') {
        [self setValue:value forAdditionKey:[key substringFromIndex:1]];
    } else {
        NSArray *keys = [key componentsSeparatedByString:@"."];
        NSUInteger N = keys.count;
        if (N > 1) {
            id target = self;
            int i = 0;
            for (; i < N - 1; i++) {
                target = [target valueForKey:keys[i]];
            }
            [target setValue:value forKey:keys[i]];
        } else {
            [super setValue:value forKey:key];
        }
    }
}

- (void)setValue:(id)value forAdditionKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    if (value == nil) {
        [self.PB_additionValues removeObjectForKey:key];
        if (self.PB_additionValues != nil && [self.PB_additionValues count] == 0) {
            self.PB_additionValues = nil;
        }
    } else {
        if (self.PB_additionValues == nil) {
            self.PB_additionValues = [[NSMutableDictionary alloc] init];
        }
        [self.PB_additionValues setObject:value forKey:key];
    }
    [self didChangeValueForKey:key];
}

- (id)valueForAdditionKey:(NSString *)key
{
    return [self.PB_additionValues objectForKey:key];
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
    if (self.pb_unmappableKeys == nil) {
        return YES;
    }
    return ![self.pb_unmappableKeys containsObject:keyPath];
}

- (void)setNeedsLoad:(BOOL)needsLoad
{
    if (needsLoad) {
        if (self.data == nil && self.client != nil) {
            [self pb_pullData];
        } else {
            [self pb_loadData:self.data];
        }
    }
}

- (void)setExpression:(NSString *)expression forKeyPath:(NSString *)keyPath
{
    PBMutableExpression *aExpression = [[PBMutableExpression alloc] initWithString:expression];
    if (aExpression == nil) {
        return;
    }
    NSMutableDictionary *dynamicProperties;
    if (self.PBDynamicProperties == nil) {
        dynamicProperties = [[NSMutableDictionary alloc] init];
        self.PBDynamicProperties = dynamicProperties;
    } else {
        dynamicProperties = [NSMutableDictionary dictionaryWithDictionary:self.PBDynamicProperties];
    }
    [dynamicProperties setObject:aExpression forKey:keyPath];
}

- (NSDictionary *)hrefParams {
    return [self valueForAdditionKey:@"hrefParams"];
}

- (UIViewController *)supercontroller
{
    id controller = self;
    while (controller = [controller nextResponder]) {
        if ([controller isKindOfClass:[UIViewController class]]) {
            break;
        }
        
        if ([controller isKindOfClass:[UIWindow class]]) {
            return [self topcontroller:[(id)controller rootViewController]];
        }
    }
    return controller;
}

- (UIViewController *)topcontroller:(UIViewController *)controller
{
    UIViewController *presentedController = [controller presentedViewController];
    if (presentedController != nil) {
        return [self topcontroller:presentedController];
    }
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return [self topcontroller:[(id)controller topViewController]];
    }
    
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return [self topcontroller:[(id)controller selectedViewController]];
    }
    
    return controller;
}

- (id)rootData
{
    return self.supercontroller.view.data;
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

@end
