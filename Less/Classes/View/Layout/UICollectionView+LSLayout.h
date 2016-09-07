//
//  UICollectionView+LSLayout.h
//  Mobile OA
//
//  Created by galen on 15/3/16.
//  Copyright (c) 2015年 simicodev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (LSLayout)

@property (nonatomic, strong) NSDictionary *LSCollectionCellConstantProperties;
@property (nonatomic, strong) NSDictionary *LSCollectionCellDynamicProperties;
@property (nonatomic, strong) NSMutableArray *LSCollectionCellSubviewDatas;

@end
