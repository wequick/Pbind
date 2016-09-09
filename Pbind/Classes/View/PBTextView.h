//
//  PBTextView.h
//  Pbind
//
//  Created by galen on 15/4/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBInput.h"

@interface PBTextView : UITextView <PBInput, PBTextInputValidator, UITextViewDelegate>
{
    UILabel *_placeholderLabel;
    NSString *_originalText;
}

@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;

@end

//___________________________________________________________________________________________________

UIKIT_STATIC_INLINE CGFloat PBTextViewLeftMargin()
{
    static CGFloat kTextViewLeftMargin = 0;
    if (kTextViewLeftMargin == 0) {
        UITextView *tempTextView = [[UITextView alloc] init];
        kTextViewLeftMargin = [tempTextView caretRectForPosition:[UITextPosition new]].origin.x;
    }
    return kTextViewLeftMargin;
}
