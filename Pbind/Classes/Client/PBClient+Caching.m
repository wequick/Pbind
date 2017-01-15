//
//  PBClient+Caching.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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
