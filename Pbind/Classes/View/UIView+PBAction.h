//
//  UIView+PBAction.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 17/8/14.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@interface UIView (PBAction)

- (void)pb_registerAction:(NSDictionary *)action forEvent:(NSString *)event;
- (NSDictionary *)pb_actionForEvent:(NSString *)event;

- (void)pb_unbindActionMappers;

@end
