//
//  PBResponse.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    PBResponseStatusOK = 200, // GET|POST done
    PBResponseStatusCreated = 201, // POST but has been created
    PBResponseStatusNoModified = 304, // GET but no modified
    PBResponseStatusNoContent = 204, // DELETE done
} PBResponseStatus;

/**
 An instance of PBResponse stores the result of the data fetching from client.
 */
@interface PBResponse : NSObject

#pragma mark - Resulting
///=============================================================================
/// @name Resulting
///=============================================================================

/** The data fetched by client. Default is nil */
@property (nonatomic, strong) id data;

/** The error occured while fetching data. Default is nil */
@property (nonatomic, strong) NSError *error;

/** The code of the fetching status */
@property (nonatomic, assign) PBResponseStatus status;

/** The user info passed from PBRequest */
@property (nonatomic, strong) NSDictionary *userInfo;

@end
