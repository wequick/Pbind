//
//  UICollectionView+PBLayout.h
//  Mobile OA
//
//  Created by galen on 15/3/16.
//  Copyright (c) 2015年 simicodev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (PBLayout)

@property (nonatomic, strong) NSDictionary *PBCollectionCellConstantProperties;
@property (nonatomic, strong) NSDictionary *PBCollectionCellDynamicProperties;
@property (nonatomic, strong) NSMutableArray *PBCollectionCellSubviewDatas;

@end
