//
//  UINavigationItem+Pbind.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/18.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@interface UINavigationItem (Pbind)

- (void)setRight:(NSDictionary *)right;
- (void)setRights:(NSArray *)rights;

- (void)setLeft:(NSDictionary *)left;
- (void)setLefts:(NSArray *)lefts;

@end
