//
//  PBActionMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBMapper.h"
#import "PBDictionary.h"

@interface PBActionMapper : PBMapper

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *params;

@property (nonatomic, assign) BOOL disabled;

@property (nonatomic, strong) NSDictionary *next;
@property (nonatomic, strong) NSDictionary *nextMappers;

@end
