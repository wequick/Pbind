//
//  PBActionState.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBResponse.h"

@interface PBActionState : NSObject

@property (nonatomic, assign) BOOL passed;
@property (nonatomic, weak) UIView *context;

@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, assign) PBResponseStatus status;
@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSError *error;

- (NSDictionary *)mergedParams:(NSDictionary *)params;

@end
