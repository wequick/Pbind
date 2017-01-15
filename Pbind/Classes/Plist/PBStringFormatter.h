//
//  PBVariableFormatter.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/28.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 This class used to register a custom tag for formating string.
 
 @discussion Built-in tags are:
 
 - t, for NSDate formation
 - T, for NSDate formation with date template
 
 @see PBString
 */
@interface PBStringFormatter : NSObject

+ (void)registerTag:(NSString *)tag withFormatterer:(NSString * (^)(NSString *format, id value))formatter;

+ (NSArray *)allTags;
+ (NSString * (^)(NSString *format, id value))formatterForTag:(NSString *)tag;

@end
