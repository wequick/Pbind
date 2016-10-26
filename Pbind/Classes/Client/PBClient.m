//
//  PBClient.m
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBClient.h"

NSString *const PBClientWillLoadRequestNotification = @"PBClientWillLoadRequestNotification";
NSString *const PBClientDidLoadRequestNotification = @"PBClientDidLoadRequestNotification";
NSString *const PBResponseKey = @"PBResponseKey";

@implementation PBClient

static NSMutableDictionary *kAliasNames;
static id (^kDebugServer)(PBClient *client, PBRequest *request);

+ (Class)requestClass
{
    return PBRequest.class;
}

+ (instancetype)clientWithName:(NSString *)clientName
{
    NSString *realName = [kAliasNames objectForKey:clientName];
    if (realName == nil) {
        realName = clientName;
    }
    Class clientClazz = NSClassFromString(realName);
    if (clientClazz == nil) {
        return nil;
    }
    
    return [[clientClazz alloc] init];
}

+ (void)registerAlias:(NSDictionary *)alias
{
    if (kAliasNames == nil) {
        kAliasNames = [NSMutableDictionary dictionaryWithDictionary:alias];
    } else {
        [kAliasNames addEntriesFromDictionary:alias];
    }
}

+ (void)registerDebugServer:(id (^)(PBClient *, PBRequest *))server {
    kDebugServer = server;
}

- (void)GET:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection
{
    PBRequest *request = [[PBRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"GET";
    [self _loadRequest:request mapper:nil notifys:YES complection:complection];
}

- (void)POST:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection
{
    PBRequest *request = [[PBRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"POST";
    [self _loadRequest:request mapper:nil notifys:YES complection:complection];
}

- (void)PATCH:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection
{
    PBRequest *request = [[PBRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"PATCH";
    [self _loadRequest:request mapper:nil notifys:YES complection:complection];
}

- (void)DELETE:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection
{
    PBRequest *request = [[PBRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"DELETE";
    [self _loadRequest:request mapper:nil notifys:YES complection:complection];
}

- (void)_loadRequest:(PBRequest *)request mapper:(PBClientMapper *)mapper notifys:(BOOL)notifys complection:(void (^)(PBResponse *))complection
{
    _canceled = NO;
    
    // Custom debug response
    PBResponse *debugResponse = [self debugResponse];
    if (debugResponse != nil) {
        debugResponse = [self transformingResponse:debugResponse];
        complection(debugResponse);
        return;
    }
    
    // Global debug response
    if (kDebugServer != nil) {
        id data = kDebugServer(self, request);
        if (data != nil) {
            PBResponse *response = [[PBResponse alloc] init];
            response.data = data;
            response = [self transformingResponse:response];
            complection(response);
            return;
        }
    }
    
    PBRequest *aRequest = [self transformingRequest:request];
    // Read cache
    NSString *cacheKey = [self cacheKeyForRequest:aRequest];
    id cacheData = nil;
    if (self.cacheCount != PBClientCacheNever) {
        int readCacheCount = 0;
        if (self.readCacheCounts != nil) {
            readCacheCount = [[self.readCacheCounts objectForKey:cacheKey] intValue];
        }
        if (self.cacheCount == PBClientCacheForever || readCacheCount < self.cacheCount) {
            cacheData = [self cacheDataForKey:cacheKey];
            if (cacheData != nil) {
                PBResponse *response = [[PBResponse alloc] init];
                response.data = cacheData;
                response = [self transformingResponse:response];
                if (_canceled) {
                    return;
                }
                if (self.cacheCount != PBClientCacheForever) {
                    if (self.readCacheCounts == nil) {
                        self.readCacheCounts = [[NSMutableDictionary alloc] init];
                    }
                    [self.readCacheCounts setObject:@(readCacheCount + 1) forKey:cacheKey];
                }
                complection(response);
                return;
            }
        }
    }
    
    // Post notification
    _request = request;
    if (notifys) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PBClientWillLoadRequestNotification object:self];
    }
    
    // Load request
    [self loadRequest:aRequest success:^(id responseData) {
        PBResponse *response = [[PBResponse alloc] init];
        response.data = responseData;
        response = [self transformingResponse:response];
        if (_canceled) {
            return;
        }
        // Save cache
        if (self.cacheCount != PBClientCacheNever && cacheData == nil) {
            [self setCacheData:responseData forKey:cacheKey];
            if (self.cacheCount != PBClientCacheForever) {
                [self.readCacheCounts setObject:@(0) forKey:cacheKey];
            }
        }
        
        complection(response);
        
        if (notifys) {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
            userInfo[PBResponseKey] = response;
            if (mapper.successTips != nil) {
                response.tips = mapper.successTips;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:PBClientDidLoadRequestNotification object:self userInfo:userInfo];
        }

        if (mapper != nil && mapper.nextClient != nil) {
            // TODO: Call next
        }
    } failure:^(NSError *error) {
        PBResponse *response = [[PBResponse alloc] init];
        response.error = error;
        response = [self transformingResponse:response];
        if (_canceled) {
            return;
        }
        complection(response);
        
        if (notifys) {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
            userInfo[PBResponseKey] = response;
            if (mapper.failureTips != nil) {
                response.tips = mapper.failureTips;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:PBClientDidLoadRequestNotification object:self userInfo:userInfo];
        }
    }];
}

- (void)cancel
{
    _canceled = YES;
}

@end
