//
//  PBRequest.h
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

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
