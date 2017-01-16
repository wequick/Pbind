//
//  PBMessageInterceptor.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/28.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 An instance of PBMessageInterceptor intercepts the OC messages from receiver to a middle man.
 */
@interface PBMessageInterceptor : NSObject

@property (nonatomic, weak) id receiver;
@property (nonatomic, weak) id middleMan;

@end
