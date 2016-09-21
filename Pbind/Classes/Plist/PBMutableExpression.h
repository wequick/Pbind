//
//  PBMutableExpression.h
//  Pbind
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBExpression.h"
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
    
    NSArray<NSDictionary *> *_attributes; // for attributed text
    
    NSMutableArray *_formatedArguments;
}

@end
