//
//  PBValueParser.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 This class is used to parse the constant value.
 
 @discussion The string in following format will be converted:
 
 - :some_enum -> enumerator value
 - #hex_string -> UIColor
 - ##hex_string -> CGColor
 - {num, num} -> CGSize, CGPoint or NSRange
 - {num, num, num, num} -> CGRect or UIEdgeInsets
 - {F:family, style, size} -> NSFont
 - @[...] -> NSArray
 - @{...} -> NSDictionary
 
 */
@interface PBValueParser : NSObject

+ (id)valueWithString:(NSString *)aString;

+ (void)registerEnums:(NSDictionary *)enums; // <NSString *, NSNumber *>

@end
