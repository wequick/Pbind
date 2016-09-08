//
//  LSClientMapper.h
//  Less
//
//  Created by Galen Lin on 16/9/2.
//  Copyright © 2016年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LSMapper.h"

@class LSClient;

@interface LSClientMapper : LSMapper

@property (nonatomic, strong) NSString *clazz;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, assign) BOOL parallel;

@property (nonatomic, strong) NSString *successTip;
@property (nonatomic, strong) NSString *successHref; // Trigger a href while succeed
@property (nonatomic, strong) NSString *failureTip;

@property (nonatomic, strong) LSClient *nextClient;

@end
