//
//  LSClient.m
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSClient.h"

@implementation LSClient

+ (Class)requestClass
{
    return LSRequest.class;
}

- (void)loadRequest:(LSRequest *)request complection:(void (^)(LSResponse *))complection
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
    } failure:^(NSError *error) {
        LSResponse *response = [[LSResponse alloc] init];
        response.error = error;
        response = [self transformingResponse:response];
        if (_canceled) {
            return;
        }
        complection(response);
    }];
}

- (void)cancel
{
    _canceled = YES;
}

@end
