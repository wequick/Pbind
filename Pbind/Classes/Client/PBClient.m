//
//  PBClient.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBClient.h"
#import "PBDictionary.h"

NSString *const PBClientWillLoadRequestNotification = @"PBClientWillLoadRequestNotification";
NSString *const PBClientDidLoadRequestNotification = @"PBClientDidLoadRequestNotification";
NSString *const PBResponseKey = @"PBResponseKey";

@implementation PBClient

static NSMutableDictionary *kAliasNames;
static void (^kDebugServer)(PBClient *client, PBRequest *request, void (^complection)(PBResponse *response));

+ (Class)requestClass
{
    return PBRequest.class;
}

+ (instancetype)clientWithName:(NSString *)clientName
{
    if (clientName == nil) {
        if (kAliasNames == nil) {
            // If not set, return self for DEBUG.
            NSLog(@"Pbind: Failed to find a registered client, use PBClient as default.");
            return [[self alloc] init];
        }
        
        clientName = [kAliasNames objectForKey:@""];
        if (clientName == nil) {
            return nil;
        }
    } else {
        if (kAliasNames != nil) {
            NSString *realName = [kAliasNames objectForKey:clientName];
            if (realName != nil) {
                clientName = realName;
            }
        }
    }
    
    Class clientClazz = NSClassFromString(clientName);
    if (clientClazz == nil) {
        return nil;
    }
    
    return [[clientClazz alloc] init];
}

+ (void)registerAlias:(NSString *)alias
{
    if (kAliasNames == nil) {
        kAliasNames = [[NSMutableDictionary alloc] init];
    }
    [kAliasNames setObject:[[self class] description] forKey:alias];
}

+ (NSString *)alias {
    return nil;
}

+ (void)registerDebugServer:(void (^)(PBClient *client, PBRequest *request, void (^complection)(PBResponse *response)))server {
    kDebugServer = server;
}

- (void)GET:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection
{
    PBRequest *request = [[PBRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"GET";
    [self _loadRequest:request notifys:YES complection:complection];
}

- (void)POST:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection
{
    PBRequest *request = [[PBRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"POST";
    [self _loadRequest:request notifys:YES complection:complection];
}

- (void)PATCH:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection
{
    PBRequest *request = [[PBRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"PATCH";
    [self _loadRequest:request notifys:YES complection:complection];
}

- (void)DELETE:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection
{
    PBRequest *request = [[PBRequest alloc] init];
    request.action = action;
    request.params = params;
    request.method = @"DELETE";
    [self _loadRequest:request notifys:YES complection:complection];
}

- (void)_loadRequest:(PBRequest *)request notifys:(BOOL)notifys complection:(void (^)(PBResponse *))complection
{
    _canceled = NO;
    
    // Custom debug response
    PBResponse *debugResponse = [self debugResponse];
    if (debugResponse != nil) {
        debugResponse = [self transformingResponse:debugResponse withRequest:request];
        complection(debugResponse);
        return;
    }
    
    // Global debug response
    if (kDebugServer != nil) {
        kDebugServer(self, request, ^(PBResponse *response) {
            if (response != nil) {
                response = [self transformingResponse:response withRequest:request];
                complection(response);
            } else {
                [self __loadRequest:request notifys:notifys complection:complection];
            }
        });
        return;
    }
    
    [self __loadRequest:request notifys:notifys complection:complection];
}

- (void)__loadRequest:(PBRequest *)request notifys:(BOOL)notifys complection:(void (^)(PBResponse *))complection {
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
        response =  [self transformingResponse:response withRequest:request];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:PBClientDidLoadRequestNotification object:self userInfo:userInfo];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:PBClientDidLoadRequestNotification object:self userInfo:userInfo];
        }
    }];
}

- (PBResponse *)transformingResponse:(PBResponse *)response withRequest:(PBRequest *)request {
    response = [self transformingResponse:response];
    if (response == nil || response.data == nil) {
        return response;
    }
    
    if (request.requiresMutableResponse) {
        response.data = [self editableDataWithData:response.data];
    }
    return response;
}

- (id)editableDataWithData:(id)data {
    if ([data isKindOfClass:[NSArray class]]) {
        NSInteger N = [data count];
        if (N > 0) {
            id firstObject = [data firstObject];
            id convertedObject = [self editableDataWithData:firstObject];
            if (convertedObject != firstObject) {
                NSMutableArray *convertedArray = [NSMutableArray arrayWithCapacity:N];
                [convertedArray addObject:convertedObject];
                for (NSInteger i = 1; i < N; i++) {
                    convertedObject = [self editableDataWithData:[data objectAtIndex:i]];
                    [convertedArray addObject:convertedObject];
                }
                return convertedArray;
            }
        }
        return data;
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        PBDictionary *dict = [[PBDictionary alloc] init];
        for (NSString *key in data) {
            id value = [self editableDataWithData:[data objectForKey:key]];
            [dict setObject:value forKey:key];
        }
        return dict;
    }
    return data;
}

- (void)cancel
{
    _canceled = YES;
}

@end
