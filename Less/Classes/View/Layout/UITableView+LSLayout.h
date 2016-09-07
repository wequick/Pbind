//
//  UITableView+LSLayout.h
//  Less
//
//  Created by galen on 15/3/11.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (LSLayout)

@property (nonatomic, strong) NSDictionary *LSCellConstantProperties;
@property (nonatomic, strong) NSDictionary *LSCellDynamicProperties;
@property (nonatomic, strong) NSMutableArray *LSCellSubviewDatas;

@end
