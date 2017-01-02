//
//  PBDataFetching.h
//  Pods
//
//  Created by Galen Lin on 02/01/2017.
//
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
