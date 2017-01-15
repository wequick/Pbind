//
//  UIImageView+Pbind.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/9/13.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIImageView+Pbind.h"
#import "UIView+Pbind.h"
#import "PBInline.h"

@implementation UIImageView (Pbind)

- (void)setImageName:(NSString *)imageName {
    [self setImage:PBImage(imageName)];
}

@end
