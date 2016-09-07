//
//  LSClient+Caching.m
//  Less
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSClient.h"
#import <objc/runtime.h>
#import "LSCompat.h"

NSInteger const LSClientCacheNever = 0;
NSInteger const LSClientCacheForever = -1;

@implementation LSClient (Caching)

DEF_DYNAMIC_INTEGER_LSOPERTY(cacheCount, setCacheCount, 0)
DEF_DYNAMIC_LSOPERTY(readCacheCounts, setReadCacheCounts, NSMutableDictionary *)

- (NSString *)cacheKeyForRequest:(LSRequest *)request {
    return request.action;
}

- (id)cacheDataForKey:(NSString *)key {
    return nil;
}

- (void)setCacheData:(id)data forKey:(NSString *)key {
    
}

@end
