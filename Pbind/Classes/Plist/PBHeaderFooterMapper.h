//
//  PBVariableMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 17/7/13.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Pbind/Pbind.h>

@interface PBHeaderFooterMapper : PBRowMapper

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleColor;

@end
