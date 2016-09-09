//
//  PBClient.h
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBResponse.h"
#import "PBRequest.h"
#import "PBClientMapper.h"

//______________________________________________________________________________

@class PBClient;
@protocol PBClientDelegate <NSObject>

- (void)client:(PBClient *)client didReceiveResponse:(PBResponse *)response;

@end

//______________________________________________________________________________

@interface PBClient : NSObject
{
    BOOL _canceled;
}

+ (Class)requestClass; // default is PBRequest.
+ (instancetype)clientWithName:(NSString *)clientName;
+ (void)registerAlias:(NSDictionary *)alias; // alias -> real

@property (nonatomic, assign) id<PBClientDelegate> delegate;
@property (nonatomic, strong, readonly) PBRequest *request;

- (void)GET:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection;
- (void)POST:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection;
- (void)PATCH:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection;
- (void)DELETE:(NSString *)action params:(NSDictionary *)params complection:(void (^)(PBResponse *response))complection;

- (void)cancel;

@end

/*
 * Override following category methods in your sub-class if needed.
 */

//______________________________________________________________________________

@interface PBClient (Caching)

@property (nonatomic, assign) NSInteger cacheCount; // default is PBClientCacheNever;
@property (nonatomic, strong) NSMutableDictionary *readCacheCounts;

- (NSString *)cacheKeyForRequest:(PBRequest *)request;

- (id)cacheDataForKey:(NSString *)key;
- (void)setCacheData:(id)data forKey:(NSString *)key;

@end

FOUNDATION_EXPORT NSInteger const PBClientCacheNever;
FOUNDATION_EXPORT NSInteger const PBClientCacheForever;

//______________________________________________________________________________

@interface PBClient (Loading)

- (id)loadRequest:(PBRequest *)request error:(NSError **)error; // synchronous loading
- (void)loadRequest:(PBRequest *)request success:(void (^)(id responseData))success failure:(void (^)(NSError *error))failure; // if above method has not been implemented, asynchronous loading

- (PBRequest *)transformingRequest:(PBRequest *)request; // user transforming for loading request
- (PBResponse *)debugResponse; // default is nil. if set, return the response without loading
- (PBResponse *)transformingResponse:(PBResponse *)response; // user transforming for loaded response

@end

//______________________________________________________________________________

@interface PBClient (Paging)

- (NSDictionary *)pagingParamsWithOffset:(NSUInteger)offset limit:(NSUInteger)limit page:(NSUInteger)page;

@end

FOUNDATION_EXPORT NSString *const PBClientWillLoadRequestNotification;
FOUNDATION_EXPORT NSString *const PBClientDidLoadRequestNotification;
FOUNDATION_EXPORT NSString *const PBResponseKey;
FOUNDATION_EXPORT NSString *const PBResultTipKey;
