//
//  UIImageView+Pbind.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/9/13.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Pbind)

/**
 The image name used to locate the image in preferred bundles.
 
 @discussion Where the preferred bundles are:
 
 * 1. The bundle of the image view's super controller class
 * 2. The main bundle
 * 3. The patch bundle
 
 */
- (void)setImageName:(NSString *)imageName;

@end
