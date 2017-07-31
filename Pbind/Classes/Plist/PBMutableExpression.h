//
//  PBMutableExpression.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBExpression.h"
#import "PBMapperProperties.h"
#import <UIKit/UIKit.h>

/**
 An instance of PBMutableExpression provides the ability of evaluating a group of PBExpressions.
 
 @discussion Supports:
 
 * String formatter
    - @"%@: %@",$a,$b
    - %(%@: %@),$a,$b
 
 * Format the string only if arguments are not empty
    - %!(%@: %@),$a,$b

 * Javascript evaluator
    - `$2/$1`,$a,$b
    - %JS($2/$1),$a,$b
    - %JS:[return_type]($1+$2),$a,$b
 
 * Attributed string formatter
    - %AT(%@|%@),$a,$b
 
 */
@interface PBMutableExpression : PBExpression
{
    struct {
        unsigned int testEmpty:1; // '%!'
        unsigned int javascript:1; // '%JS'
        unsigned int attributedText:1; // '%AT'
        unsigned int customized:1; // user customization
    } _formatFlags;
    
    struct {
        unsigned int backticks:1; // ``
        unsigned int string:1; // @""
    } _keywordFlags;
    
    NSString *_formatterTag;
    NSString *(^_formatter)(NSString *tag, NSString *format, NSArray *args);
    
    NSArray<PBExpression *> *_expressions;
    PBMapperProperties *_properties;
    
    NSArray<NSDictionary *> *_attributes; // for attributed text
    
    NSMutableArray *_formatedArguments;
}

- (instancetype)initWithProperties:(PBMapperProperties *)properties;

@end
