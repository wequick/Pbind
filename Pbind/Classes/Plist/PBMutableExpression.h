//
//  PBMutableExpression.h
//  Pbind
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBExpression.h"
#import <UIKit/UIKit.h>

@interface PBMutableExpression : PBExpression
{
    struct {
        unsigned int date:1; // '%DF'
        unsigned int dateTemplate:1; // '%DT'
        unsigned int attributedText:1; // '%AT'
        unsigned int custom:1; // user customize
    } _formatFlags;
    
    NSString *_formatterTag;
    NSString *(^_formatter)(NSString *tag, NSString *format, NSArray *args);
    
    NSArray *_expressions;
    
    NSParagraphStyle *_paragraphStyle; // for attributed text
    NSArray *_attributes; // for attributed text
    
    NSMutableArray *_formatedArguments;
}

@end
