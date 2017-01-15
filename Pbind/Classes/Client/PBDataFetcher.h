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

@interface PBDataFetcher : NSObject

@property (nonatomic, strong) NSArray *clientMappers;
@property (nonatomic, strong) NSArray *clients;

@property (nonatomic, weak) UIView<PBDataFetching> *owner;

- (void)fetchData;
- (void)fetchDataWithTransformation:(id (^)(id data, NSError *error))transformation;

- (void)refetchData;
- (void)cancel;

@end
