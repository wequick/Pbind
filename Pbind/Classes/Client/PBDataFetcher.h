//
//  PBDataFetcher.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 02/01/2017.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

@protocol PBDataFetching;

/**
 This class is used to fetch data from the specified clients.
 */
@interface PBDataFetcher : NSObject

#pragma mark - Source
///=============================================================================
/// @name Source
///=============================================================================

/** the mapper array used to create clients */
@property (nonatomic, strong) NSArray *clientMappers;

/**
 the clients to be fetch data.
 
 @discussion We just fetch data parallelly for all the clients.
 */
@property (nonatomic, strong) NSArray *clients;

#pragma mark - Context
///=============================================================================
/// @name Context
///=============================================================================

@property (nonatomic, weak) UIView<PBDataFetching> *owner;

/**
 Start fetch the data from clients.
 */
- (void)fetchData;

/**
 Fetch the data and do some transformations with it.

 @param transformation the block to handle the data
 */
- (void)fetchDataWithTransformation:(id (^)(id data, NSError *error))transformation;

/**
 Refetch the data.
 
 @discussion currently is same as `fetchData`.
 */
- (void)refetchData;

/**
 Cancel the data fetching.
 */
- (void)cancel;

@end
