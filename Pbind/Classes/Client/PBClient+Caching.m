//
//  PBClient+Caching.m
//  Pbind
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBClient.h"
#import <objc/runtime.h>
#import "PBCompat.h"

NSInteger const PBClientCacheNever = 0;
NSInteger const PBClientCacheForever = -1;

@implementation PBClient (Caching)

DEF_DYNAMIC_INTEGER_PROPERTY(cacheCount, setCacheCount, 0)
DEF_DYNAMIC_PROPERTY(readCacheCounts, setReadCacheCounts, NSMutableDictionary *)

- (NSString *)cacheKeyForRequest:(PBRequest *)request {
    return request.action;
}

- (id)cacheDataForKey:(NSString *)key {
    return nil;
}

- (void)setCacheData:(id)data forKey:(NSString *)key {
    
}

@end
