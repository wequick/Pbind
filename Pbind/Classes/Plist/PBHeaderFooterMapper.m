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

- (void)initDefaultViewClass {
    if ([self.owner isKindOfClass:[UICollectionView class]]) {
        self.clazz = @"UICollectionReusableView";
    } else {
        self.clazz = @"UIView";
    }
}

- (void)setTitle:(NSString *)title {
    _title = title;
    if (title != nil) {
        self.height = UITableViewAutomaticDimension;
        self.estimatedHeight = 21.f;
    } else {
        self.height = 0.f;
        self.estimatedHeight = 0.f;
    }
}

@end
