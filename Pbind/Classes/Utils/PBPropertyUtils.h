//
//  PBPropertyUtils.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/10/28.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

@interface PBPropertyUtils : NSObject

+ (void)setValue:(id)value forKey:(NSString *)key toObject:(id)object failure:(void (^)(void))failure;

+ (void)setValue:(id)value forKeyPath:(NSString *)keyPath toObject:(id)object failure:(void (^)(void))failure;

+ (void)setValuesForKeysWithDictionary:(NSDictionary *)dictionary toObject:(id)object failure:(void (^)(void))failure;

@end
