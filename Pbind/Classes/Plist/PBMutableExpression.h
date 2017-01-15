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
 A PBMutableExpression allows to calculate a set of PBExpressions.
 
 @discussion Supports:
 
 * %(%@: %@),$a,$b  -> String formater
 * %!(%@: %@),$a,$b -> Format the string only if arguments are not empty
 * %JS($2/$1),$a,$b -> Javascript evaluator
 * %AT(%@|%@),$a,$b
 
 */
@interface PBMutableExpression : PBExpression
{
    struct {
        unsigned int testEmpty:1; // '%!'
        unsigned int javascript:1; // '%JS'
        unsigned int attributedText:1; // '%AT'
        unsigned int customized:1; // user customization
    } _formatFlags;
    
    NSString *_formatterTag;
    NSString *(^_formatter)(NSString *tag, NSString *format, NSArray *args);
    
    NSArray<PBExpression *> *_expressions;
    PBMapperProperties *_properties;
    
    NSArray<NSDictionary *> *_attributes; // for attributed text
    
    NSMutableArray *_formatedArguments;
}

- (instancetype)initWithProperties:(PBMapperProperties *)properties;

@end
