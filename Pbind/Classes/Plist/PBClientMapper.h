//
//  PBClientMapper.h
//  Pbind
//
//  Created by Galen Lin on 16/9/2.
//  Copyright © 2016年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PBMapper.h"

@class PBClient;

@interface PBClientMapper : PBMapper

@property (nonatomic, strong) NSString *clazz;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, assign) BOOL parallel;

@property (nonatomic, strong) NSString *successTips;
@property (nonatomic, strong) NSString *successHref; // Trigger a href while succeed
@property (nonatomic, strong) NSString *failureTips;

@property (nonatomic, strong) PBClient *nextClient;

@end
