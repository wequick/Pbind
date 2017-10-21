//
//  _PBRowDataWrapper.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 2017/10/20.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "_PBRowDataWrapper.h"

@implementation _PBRowDataWrapper

- (instancetype)initWithData:(id)data indexPath:(NSIndexPath *)indexPath {
    if (self = [super init]) {
        self.data = data;
        self.indexPath = indexPath;
    }
    return self;
}

@end
