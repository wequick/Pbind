//
//  LSClient.h
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSResponse.h"
#import "LSRequest.h"
#import "LSClientMapper.h"

//______________________________________________________________________________

@class LSClient;
@protocol LSClientDelegate <NSObject>

- (void)client:(LSClient *)client didReceiveResponse:(LSResponse *)response;

@end

//______________________________________________________________________________

@interface LSClient : NSObject
{
    BOOL _canceled;
}

+ (Class)requestClass; // default is LSRequest.
+ (instancetype)clientWithName:(NSString *)clientName;
+ (void)registerAlias:(NSDictionary *)alias; // alias -> real

@property (nonatomic, assign) id<LSClientDelegate> delegate;
@property (nonatomic, strong, readonly) LSRequest *request;

- (void)GET:(NSString *)action params:(NSDictionary *)params complection:(void (^)(LSResponse *response))complection;
- (void)POST:(NSString *)action params:(NSDictionary *)params complection:(void (^)(LSResponse *response))complection;
- (void)PATCH:(NSString *)action params:(NSDictionary *)params complection:(void (^)(LSResponse *response))complection;
- (void)DELETE:(NSString *)action params:(NSDictionary *)params complection:(void (^)(LSResponse *response))complection;

- (void)cancel;

@end

/*
 * Override following category methods in your sub-class if needed.
 */

//______________________________________________________________________________

@interface LSClient (Caching)

@property (nonatomic, assign) NSInteger cacheCount; // default is LSClientCacheNever;
@property (nonatomic, strong) NSMutableDictionary *readCacheCounts;

- (NSString *)cacheKeyForRequest:(LSRequest *)request;

- (id)cacheDataForKey:(NSString *)key;
- (void)setCacheData:(id)data forKey:(NSString *)key;

@end

FOUNDATION_EXPORT NSInteger const LSClientCacheNever;
FOUNDATION_EXPORT NSInteger const LSClientCacheForever;

//______________________________________________________________________________

@interface LSClient (Loading)

- (id)loadRequest:(LSRequest *)request error:(NSError **)error; // synchronous loading
- (void)loadRequest:(LSRequest *)request success:(void (^)(id responseData))success failure:(void (^)(NSError *error))failure; // if above method has not been implemented, asynchronous loading

- (LSRequest *)transformingRequest:(LSRequest *)request; // user transforming for loading request
- (LSResponse *)debugResponse; // default is nil. if set, return the response without loading
- (LSResponse *)transformingResponse:(LSResponse *)response; // user transforming for loaded response

@end

//______________________________________________________________________________

@interface LSClient (Paging)

- (NSDictionary *)pagingParamsWithOffset:(NSUInteger)offset limit:(NSUInteger)limit page:(NSUInteger)page;

@end

FOUNDATION_EXPORT NSString *const LSClientWillLoadRequestNotification;
FOUNDATION_EXPORT NSString *const LSClientDidLoadRequestNotification;
FOUNDATION_EXPORT NSString *const LSResponseKey;
FOUNDATION_EXPORT NSString *const LSResultTipKey;