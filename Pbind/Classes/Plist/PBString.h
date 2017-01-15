//
//  PBString.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/25.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 The PBString extends the ability of string formation.
 
 @discussion extension format tags:
 
 - %#.2f, NSNumber formation
 - %J, JSON formation
 - %<t>, NSDate formation
 - %<T>, NSDate formation with date template
 
 */
@interface PBString : NSString

+ (NSString *)stringWithFormat:(NSString *)format array:(NSArray *)arguments;
+ (NSString *)stringWithFormat:(NSString *)format object:(id)object;

@end
