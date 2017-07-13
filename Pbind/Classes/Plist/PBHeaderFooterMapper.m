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

#import "PBHeaderFooterMapper.h"

@implementation PBHeaderFooterMapper

- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary {
    [super setPropertiesWithDictionary:dictionary];
    if (self.title != nil) {
        self.height = UITableViewAutomaticDimension;
        self.estimatedHeight = 21.f;
    }
}

- (void)initDefaultViewClass {
    self.clazz = @"UIView";
}

@end
