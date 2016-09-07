//
//  LSTextView.h
//  Less
//
//  Created by galen on 15/4/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSInput.h"

@interface LSTextView : UITextView <LSInput, LSTextInputValidator, UITextViewDelegate>
{
    UILabel *_placeholderLabel;
    NSString *_originalText;
}

@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;

@end

//___________________________________________________________________________________________________

UIKIT_STATIC_INLINE CGFloat LSTextViewLeftMargin()
{
    static CGFloat kTextViewLeftMargin = 0;
    if (kTextViewLeftMargin == 0) {
        UITextView *tempTextView = [[UITextView alloc] init];
        kTextViewLeftMargin = [tempTextView caretRectForPosition:[UITextPosition new]].origin.x;
    }
    return kTextViewLeftMargin;
}
