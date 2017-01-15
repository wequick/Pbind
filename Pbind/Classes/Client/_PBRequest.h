//
//  PBRequest.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 An instance of PBRequest defines the base factors of fetching a data.
 
 @discussion Cause the private ProtocolBuffer.framework use the same class name,
 we had to rename it as _PBRequest, but owe to the ability of `@compatibility_alias` annotation,
 we can also use PBRequest in our source code.
 */
@interface _PBRequest : NSObject

@property (nonatomic, strong) NSString *action; // Interface action.
@property (nonatomic, strong) NSString *method; // Interface action.
@property (nonatomic, strong) NSDictionary *params; // Major params.
@property (nonatomic, strong) NSDictionary *extParams; // Minor params.

/**
 Whether the response data should be mutable, default is NO.
 
 @discussion if set to YES then will convert all the response data from NSDictionary to PBDictionary in nested.
 */
@property (nonatomic, assign) BOOL requiresMutableResponse;

@end

@compatibility_alias PBRequest _PBRequest;
