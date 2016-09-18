//
//  PBVariableMapper.h
//  Pbind
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015年 galen. All rights reserved.
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
