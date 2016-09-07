//
//  LSClientMapper.h
//  Less
//
//  Created by Galen Lin on 16/9/2.
//  Copyright © 2016年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LSMapper.h"

@interface LSClientMapper : LSMapper

@property (nonatomic, strong) NSString *clazz;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, assign) BOOL parallel;

@end
