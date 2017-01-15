//
//  PBDataFetching.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 02/01/2017.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

@class PBDataFetcher;

@protocol PBDataFetching <NSObject>

@property (nonatomic, strong) NSArray *clients;

@property (nonatomic, assign, getter=isFetching) BOOL fetching;
@property (nonatomic, assign) BOOL dataUpdated;
@property (nonatomic, assign) BOOL interrupted;

@property (nonatomic, strong) PBDataFetcher *fetcher;

@end
