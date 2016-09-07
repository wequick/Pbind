//
//  LSSectionMapper.h
//  Less
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LSMapper.h"

@interface LSSectionMapper : LSMapper

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) NSArray *rows; // LSRowMapper
@property (nonatomic, assign) BOOL floating;

- (CGFloat)heightForView:(id)view withData:(id)data;

@end
