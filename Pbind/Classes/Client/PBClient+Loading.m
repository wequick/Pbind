//
//  PBClient+Loading.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/13.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBClient.h"

@implementation PBClient (Loading)

- (PBRequest *)transformingRequest:(PBRequest *)request
{
    return request;
}

- (PBResponse *)debugResponse
{
    return nil;
}

- (PBResponse *)transformingResponse:(PBResponse *)response
{
    return response;
}

- (void)loadRequest:(PBRequest *)request success:(void (^)(id, PBResponseStatus))success failure:(void (^)(NSError *))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        id data = [self loadRequest:request error:&error];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (error != nil) {
                failure(error);
            } else {
                success(data, PBResponseStatusOK);
            }
        });
    });
}

- (id)loadRequest:(PBRequest *)request error:(NSError *__autoreleasing *)error
{
    return nil;
}

@end
