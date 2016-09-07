//
//  UIView+Less.m
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "UIView+Less.h"
#import "UIView+LSLayout.h"
#import "Less.h"
#import "LSClient.h"
#import "LSMapper.h"
#import "LSCompat.h"
#import "LSMutableExpression.h"
#import "LSClientMapper.h"
#import "LSArray.h"

NSString *const LSViewWillLoadRequestNotification = @"LSViewWillLoad";
NSString *const LSViewDidLoadRequestNotification = @"LSViewDidLoad";
NSString *const LSResponseKey = @"response";
NSString *const LSViewHasHandledLoadErrorKey = @"LSViewHasHandledLoadError";

NSString *const LSViewDidClickHrefNotification = @"LSViewDidClickHref";
NSString *const LSViewHrefKey = @"href";

@interface UIView (Less_Private)

@property (nonatomic, strong) NSArray *_lsClients;
@property (nonatomic, strong) NSArray *_lsClientMappers;

@end

@implementation UIView (Less)

@dynamic client;
@dynamic clients;
@dynamic data;
@dynamic needsLoad;

DEF_DYNAMIC_LSOPERTY(LS_additionValues, setLS_additionValues, NSMutableDictionary *)
DEF_DYNAMIC_LSOPERTY(pr_unmappableKeys, setPr_unmappableKeys, NSMutableArray *)

DEF_UNDEFINED_LSOPERTY(NSURL *, _lsPlistURL);
DEF_UNDEFINED_LSOPERTY(NSArray *, _lsClients);
DEF_UNDEFINED_LSOPERTY(NSArray *, _lsClientMappers);
DEF_UNDEFINED_LSOPERTY(LSMapper *, LS_internalMapper);

DEF_UNDEFINED_LSOPERTY2(NSString *, plist, setPlist)
DEF_UNDEFINED_LSOPERTY2(NSArray *, clients, setClients)
DEF_UNDEFINED_LSOPERTY2(NSString *, client, setClient)
DEF_UNDEFINED_LSOPERTY2(NSString *, clientAction, setClientAction)
DEF_UNDEFINED_LSOPERTY2(NSDictionary *, clientParams, setClientParams)
DEF_UNDEFINED_LSOPERTY2(id, data, setData)
DEF_UNDEFINED_LSOPERTY2(NSString *, href, setHref)
DEF_UNDEFINED_LSOPERTY2(id<LSViewLoadingDelegate>, loadingDelegate, setLoadingDelegate)

DEF_UNDEFINED_INT_LSOPERTY(pr_loadingCount, setPr_loadingCount, 0)
DEF_UNDEFINED_BOOL_LSOPERTY(pr_interrupted, setPr_interrupted, NO)
DEF_UNDEFINED_BOOL_LSOPERTY(showsLoadingCover, setShowsLoadingCover, YES) //void (^)(void)
DEF_UNDEFINED_LSOPERTY2(void (^)(void), pr_lseparation, setPr_lseparation)
DEF_UNDEFINED_LSOPERTY2(id (^)(id, NSError *), pr_transformation, setPr_transformation)

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow == nil) {
        if (self.pr_loading) {
            // If super controller is neither a singleton nor a child of `UITabBarController', mark interrupted flag to reload at next appearance
            if (![[[[self supercontroller] navigationController] parentViewController] isKindOfClass:[UITabBarController class]]) {
                self.pr_interrupted = YES;
                [self pr_cancelPull];
            }
        }
    } else {
        if (self.plist != nil && self._lsPlistURL == nil) {
            self._lsPlistURL = [self pr_URLForResource:self.plist withExtension:@"plist"];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
               dispatch_sync(dispatch_get_main_queue(), ^{
                   [[self pr_mapper] initDataForView:self];
               });
            });
        }
        if (self.pr_interrupted) {
            self.pr_interrupted = NO;
            [self pr_repullData];
        }
    }
}

- (NSURL *)pr_URLForResource:(NSString *)resource withExtension:(NSString *)extension
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

- (NSArray *)pr_clientMappers
{
    if (self._lsClientMappers != nil) return self._lsClientMappers;
    
    // Lazy init
    if (self.clients == nil) {
        if (self.client == nil) return nil;
        
        LSClientMapper *mapper = [[LSClientMapper alloc] init];
        mapper.clazz = self.client;
        mapper.action = self.clientAction;
        mapper.params = self.clientParams;
        self._lsClientMappers = @[mapper];
        return self._lsClientMappers;
    } else {
        NSMutableArray *mappers = [NSMutableArray arrayWithCapacity:self.clients.count];
        for (id data in self.clients) {
            LSClientMapper *mapper = [LSClientMapper mapperWithDictionary:data];
            [mappers addObject:mapper];
        }
        self._lsClientMappers = mappers;
        return mappers;
    }
}

- (NSArray *)pr_clients
{
    if (self._lsClients != nil) return self._lsClients;
    
    if (self.pr_clientMappers == nil) return nil;
    
    NSMutableArray *clients = [NSMutableArray arrayWithCapacity:self.clients.count];
    for (LSClientMapper *mapper in self.pr_clientMappers) {
        Class clientClass = NSClassFromString(mapper.clazz);
        LSClient *client = [[clientClass alloc] init];
        client.delegate = (id) self;
        [clients addObject:client];
    }
    self._lsClients = clients;
    return clients;
}

- (LSMapper *)pr_mapper
{
    // Lazy init
    if (self.LS_internalMapper == nil) {
        if (self._lsPlistURL != nil) {
            self.LS_internalMapper = [LSMapper mapperWithContentsOfURL:self._lsPlistURL];
        }
    }
    return self.LS_internalMapper;
}

- (BOOL)pr_loading
{
    return self.pr_loadingCount > 0;
}

- (void)pr_pullData
{
    [self pr_pullDataWithPreparation:nil transformation:nil];
}

- (void)pr_pullDataWithPreparation:(void (^)(void))preparation transformation:(id (^)(id, NSError *))transformation
{
    if (self.pr_loading) {
        return;
    }
    
    if (self.pr_clientMappers == nil) {
        return;
    }
    
    if (self.pr_clients == nil) {
        return;
    }
    
    if (preparation) {
        preparation();
    }
    
    // Notify loading start
    [[NSNotificationCenter defaultCenter] postNotificationName:LSViewWillLoadRequestNotification object:self];
    
    self.pr_lseparation = preparation;
    self.pr_transformation = transformation;
    NSInteger N = self.pr_clients.count;
    self.pr_loadingCount = (int) N;
    
    // Init null data
    self.data = [LSArray arrayWithCapacity:self.clients.count];
    for (NSInteger i = 0; i < N; i++) {
        [self.data addObject:[NSNull null]];
    }
    
    // Load request parallel
    for (NSInteger i = 0; i < N; i++) {
        LSClient *client = [self.pr_clients objectAtIndex:i];
        LSClientMapper *mapper = [self.pr_clientMappers objectAtIndex:i];
        [mapper updateWithData:self.data andView:self];
        
        Class requestClass = [client.class requestClass];
        LSRequest *request = [[requestClass alloc] init];
        request.action = mapper.action;
        request.params = mapper.params;
//        if ([self.loadingDelegate respondsToSelector:@selector(pullParamsForView:)]) {
//            request.params = [self.loadingDelegate pullParamsForView:self];
//        } else {
//            request.params = self.clientParams;
//        }
        [client loadRequest:request complection:^(LSResponse *response) {
            BOOL handledError = NO;
            if ([self.loadingDelegate respondsToSelector:@selector(view:didFinishLoading:handledError:)]) {
                [self.loadingDelegate view:self didFinishLoading:response handledError:&handledError];
            }
            NSDictionary *userInfo = nil;
            if (response != nil) {
                userInfo = @{LSResponseKey:response, LSViewHasHandledLoadErrorKey:@(handledError)};
            } else {
                userInfo = @{LSViewHasHandledLoadErrorKey:@(handledError)};
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:LSViewDidLoadRequestNotification object:self userInfo:userInfo];
            
            [client cancel];
            
            id data = response.data;
            if (transformation) {
                data = transformation(data, response.error);
            }
            if (data) {
                self.pr_lseparation = nil;
                self.pr_transformation = nil;
                self.data[i] = data;
                [self pr_mapData:self.rootData];
                [self layoutIfNeeded];
            }
            
            self.pr_loadingCount--;
        }];
    }
}

- (void)pr_repullData
{
    [self pr_pullDataWithPreparation:self.pr_lseparation transformation:self.pr_transformation];
}

- (void)pr_loadData:(id)data
{
    [self pr_initData];
    
    [self setData:data];
    [self pr_mapData:self.rootData];
    
    [self layoutIfNeeded];
}

- (void)pr_mapData:(id)data
{
    if ([self pr_mapper] == nil) {
        [self pr_mapData:data];
        return;
    }
    [[self pr_mapper] mapData:data forView:self];
}

- (void)pr_initData
{
    if ([self pr_mapper] == nil) {
        return;
    }
    [[self pr_mapper] initDataForView:self];
}

- (void)pr_cancelPull
{
    if (self.pr_clients == nil) return;
    
    for (LSClient *client in self.pr_clients) {
        [client cancel];
    }
    self.pr_loadingCount = 0;
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
        [self.LS_additionValues removeObjectForKey:key];
        if (self.LS_additionValues != nil && [self.LS_additionValues count] == 0) {
            self.LS_additionValues = nil;
        }
    } else {
        if (self.LS_additionValues == nil) {
            self.LS_additionValues = [[NSMutableDictionary alloc] init];
        }
        [self.LS_additionValues setObject:value forKey:key];
    }
    [self didChangeValueForKey:key];
}

- (id)valueForAdditionKey:(NSString *)key
{
    return [self.LS_additionValues objectForKey:key];
}

- (void)setMappable:(BOOL)mappable forKeyPath:(NSString *)keyPath
{
    if (self.pr_unmappableKeys == nil) {
        if (!mappable) {
            self.pr_unmappableKeys = [[NSMutableArray alloc] init];
            [self.pr_unmappableKeys addObject:keyPath];
        }
    } else {
        if (mappable) {
            [self.pr_unmappableKeys removeObject:keyPath];
        } else if (![self.pr_unmappableKeys containsObject:keyPath]) {
            [self.pr_unmappableKeys addObject:keyPath];
        }
    }
}

- (BOOL)mappableForKeyPath:(NSString *)keyPath
{
    if (self.pr_unmappableKeys == nil) {
        return YES;
    }
    return ![self.pr_unmappableKeys containsObject:keyPath];
}

- (void)setNeedsLoad:(BOOL)needsLoad
{
    if (needsLoad) {
        if (self.data == nil && self.client != nil) {
            [self pr_pullData];
        } else {
            [self pr_loadData:self.data];
        }
    }
}

- (void)setExpression:(NSString *)expression forKeyPath:(NSString *)keyPath
{
    LSMutableExpression *aExpression = [[LSMutableExpression alloc] initWithString:expression];
    if (aExpression == nil) {
        return;
    }
    NSMutableDictionary *dynamicProperties;
    if (self.LSDynamicProperties == nil) {
        dynamicProperties = [[NSMutableDictionary alloc] init];
        self.LSDynamicProperties = dynamicProperties;
    } else {
        dynamicProperties = [NSMutableDictionary dictionaryWithDictionary:self.LSDynamicProperties];
    }
    [dynamicProperties setObject:aExpression forKey:keyPath];
}

- (NSDictionary *)hrefParams {
    return [self valueForAdditionKey:@"hrefParams"];
}

- (UIViewController *)supercontroller
{
    id controller = [self nextResponder];
    while (![controller isKindOfClass:[UIViewController class]]) {
        controller = [controller nextResponder];
        if (controller == nil) {
            break;
        }
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
