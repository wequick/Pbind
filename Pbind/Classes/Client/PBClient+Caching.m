//
//  PBClient+Caching.m
//  Pbind
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBClient.h"

NSInteger const PBClientCacheNever = 0;
NSInteger const PBClientCacheForever = -1;

@implementation PBClient (Caching)

- (NSString *)cacheKeyForRequest:(PBRequest *)request {
    return request.action;
}

- (id)cacheDataForKey:(NSString *)key {
    return nil;
}

- (void)setCacheData:(id)data forKey:(NSString *)key {
    
}

@end
