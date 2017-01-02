//
//  PBDataFetcher.h
//  Pods
//
//  Created by Galen Lin on 02/01/2017.
//
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
