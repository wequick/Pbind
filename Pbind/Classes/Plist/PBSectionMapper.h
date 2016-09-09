//
//  PBSectionMapper.h
//  Pbind
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PBMapper.h"

@interface PBSectionMapper : PBMapper

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) NSArray *rows; // PBRowMapper
@property (nonatomic, assign) BOOL floating;

- (CGFloat)heightForView:(id)view withData:(id)data;

@end
