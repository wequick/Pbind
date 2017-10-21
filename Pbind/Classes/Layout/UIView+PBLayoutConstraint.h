//
//  UIView+PBLayoutConstraint.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 17/7/25.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@interface UIView (PBLayoutConstraint)

- (void)pb_addConstraintsWithSubviews:(NSDictionary<NSString *, id> *)views
                        visualFormats:(NSArray<NSString *> *)visualFormats
                         pbindFormats:(NSArray<NSString *> *)pbindFormats;

- (void)pb_addConstraintsWithSubviews:(NSDictionary<NSString *, id> *)views
                              metrics:(NSDictionary<NSString *, id> *)metrics
                        visualFormats:(NSArray<NSString *> *)visualFormats
                         pbindFormats:(NSArray<NSString *> *)pbindFormats;

- (CGSize)pb_constraintSize;

@end
