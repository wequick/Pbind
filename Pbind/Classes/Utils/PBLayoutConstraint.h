//
//  PBLayoutConstraint.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 07/01/2017.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PBLayoutConstraint : NSLayoutConstraint

+ (void)addConstraintsWithPbindFormats:(NSArray<NSString *> *)formats metrics:(nullable NSDictionary<NSString *,id> *)metrics views:(NSDictionary<NSString *, id> *)views forParentView:(UIView *)parentView;

+ (void)removeAllConstraintsOfSubview:(UIView *)subview fromParentView:(UIView *)parentView;

@end
