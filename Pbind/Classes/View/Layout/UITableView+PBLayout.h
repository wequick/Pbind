//
//  UITableView+PBLayout.h
//  Pbind
//
//  Created by galen on 15/3/11.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (PBLayout)

@property (nonatomic, strong) NSDictionary *PBCellConstantProperties;
@property (nonatomic, strong) NSDictionary *PBCellDynamicProperties;
@property (nonatomic, strong) NSMutableArray *PBCellSubviewDatas;

@end
