//
//  PBValueSetter.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2017/9/24.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

@interface PBValueSetter : NSObject

- (instancetype)initWithTarget:(id)target key:(NSString *)key;

- (void)invokeWithTarget:(id)target value:(id)value;

@end

