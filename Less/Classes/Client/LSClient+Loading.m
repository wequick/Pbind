//
//  LSClient+Loading.m
//  Less
//
//  Created by galen on 15/2/13.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSClient.h"

@implementation LSClient (Loading)

- (LSRequest *)transformingRequest:(LSRequest *)request
{
    return request;
}

- (LSResponse *)debugResponse
{
    return nil;
}

- (LSResponse *)transformingResponse:(LSResponse *)response
{
    return response;
}

- (void)loadRequest:(LSRequest *)request success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        id data = [self loadRequest:request error:&error];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (error != nil) {
                failure(error);
            } else {
                success(data);
            }
        });
    });
}

- (id)loadRequest:(LSRequest *)request error:(NSError *__autoreleasing *)error
{
    return nil;
}

@end
