//
//  PBVariableMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 An instance of PBVariableMapper maps the `tag` to a `data source`.
 */
@interface PBVariableMapper : NSObject

/**
 Register a customized variable mapper.
 
 @discussion The parameters in block are:
 
 * data - The data to map.
 * target - The target to be map, usually is an UIView or a PBMapper.
 * context - The view who owns current mapper.
 
 */
+ (void)registerTag:(char)tag withMapper:(id (^)(id data, id target, UIView *context))mapper;

/**
 Whether a tag was registered.
 */
+ (BOOL)registersTag:(char)tag;

+ (id (^)(id data, id target, UIView *context))mapperForTag:(char)tag;

@end
