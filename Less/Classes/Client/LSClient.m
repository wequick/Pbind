//
//  LSClient.m
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSClient.h"

NSString *const LSClientWillLoadRequestNotification = @"LSClientWillLoadRequestNotification";
NSString *const LSClientDidLoadRequestNotification = @"LSClientDidLoadRequestNotification";
NSString *const LSResponseKey = @"LSResponseKey";
NSString *const LSResultTipKey = @"LSResultTipKey";

@implementation LSClient

static NSMutableDictionary *kAliasNames;

+ (Class)requestClass
{
    return LSRequest.class;
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

- (void)GET:(NSString *)action params:(NSDictionary *)params complection:(void (^)(LSResponse *response))complection
{
    LSRequest *request = [[LSRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"GET";
    [self _loadRequest:request mapper:nil notifys:YES complection:complection];
}

- (void)POST:(NSString *)action params:(NSDictionary *)params complection:(void (^)(LSResponse *response))complection
{
    LSRequest *request = [[LSRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"POST";
    [self _loadRequest:request mapper:nil notifys:YES complection:complection];
}

- (void)PATCH:(NSString *)action params:(NSDictionary *)params complection:(void (^)(LSResponse *response))complection
{
    LSRequest *request = [[LSRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"PATCH";
    [self _loadRequest:request mapper:nil notifys:YES complection:complection];
}

- (void)DELETE:(NSString *)action params:(NSDictionary *)params complection:(void (^)(LSResponse *response))complection
{
    LSRequest *request = [[LSRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"DELETE";
    [self _loadRequest:request mapper:nil notifys:YES complection:complection];
}

- (void)_loadRequest:(LSRequest *)request mapper:(LSClientMapper *)mapper notifys:(BOOL)notifys complection:(void (^)(LSResponse *))complection
{
    _canceled = NO;
    LSResponse *debugResponse = [self debugResponse];
    if (debugResponse != nil) {
        debugResponse = [self transformingResponse:debugResponse];
        complection(debugResponse);
        return;
    }
    
    LSRequest *aRequest = [self transformingRequest:request];
    // Read cache
    NSString *cacheKey = [self cacheKeyForRequest:aRequest];
    id cacheData = nil;
    if (self.cacheCount != LSClientCacheNever) {
        int readCacheCount = 0;
        if (self.readCacheCounts != nil) {
            readCacheCount = [[self.readCacheCounts objectForKey:cacheKey] intValue];
        }
        if (self.cacheCount == LSClientCacheForever || readCacheCount < self.cacheCount) {
            cacheData = [self cacheDataForKey:cacheKey];
            if (cacheData != nil) {
                LSResponse *response = [[LSResponse alloc] init];
                response.data = cacheData;
                response = [self transformingResponse:response];
                if (_canceled) {
                    return;
                }
                if (self.cacheCount != LSClientCacheForever) {
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
        [[NSNotificationCenter defaultCenter] postNotificationName:LSClientWillLoadRequestNotification object:self];
    }
    
    // Load request
    [self loadRequest:aRequest success:^(id responseData) {
        LSResponse *response = [[LSResponse alloc] init];
        response.data = responseData;
        response = [self transformingResponse:response];
        if (_canceled) {
            return;
        }
        // Save cache
        if (self.cacheCount != LSClientCacheNever && cacheData == nil) {
            [self setCacheData:responseData forKey:cacheKey];
            if (self.cacheCount != LSClientCacheForever) {
                [self.readCacheCounts setObject:@(0) forKey:cacheKey];
            }
        }
        
        complection(response);
        
        if (notifys) {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
            userInfo[LSResponseKey] = response;
            if (mapper.successTip != nil) {
                userInfo[LSResultTipKey] = mapper.successTip;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:LSClientDidLoadRequestNotification object:self userInfo:userInfo];
        }

        if (mapper != nil && mapper.nextClient != nil) {
            // TODO: Call next
        }
    } failure:^(NSError *error) {
        LSResponse *response = [[LSResponse alloc] init];
        response.error = error;
        response = [self transformingResponse:response];
        if (_canceled) {
            return;
        }
        complection(response);
        
        if (notifys) {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
            userInfo[LSResponseKey] = response;
            if (mapper.failureTip != nil) {
                userInfo[LSResultTipKey] = mapper.failureTip;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:LSClientDidLoadRequestNotification object:self userInfo:userInfo];
        }
    }];
}

- (void)cancel
{
    _canceled = YES;
}

@end
