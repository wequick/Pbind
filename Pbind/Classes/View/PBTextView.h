//
//  PBTextView.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBInput.h"
#import "PBViewResizingDelegate.h"

/**
 An instance of PBTextView extends the ability of configurating the placeholder.
 */
@interface PBTextView : UITextView <PBInput, PBTextInputValidator, UITextViewDelegate>
{
    UILabel *_placeholderLabel;
    NSString *_originalText;
    NSLayoutConstraint *_placeholderLeftMarginConstraint;
    NSLayoutConstraint *_placeholderRightMarginConstraint;
    NSLayoutConstraint *_heightConstraint;
}

/**
 The placeloder text.
 */
@property (nonatomic, strong) NSString *placeholder;

/**
 The text color for the placeholder label.
 */
@property (nonatomic, strong) UIColor *placeholderColor;

@end

//___________________________________________________________________________________________________

UIKIT_STATIC_INLINE CGFloat PBTextViewLeftMargin()
{
    static CGFloat kTextViewLeftMargin = 0;
    if (kTextViewLeftMargin == 0) {
        UITextView *tempTextView = [[UITextView alloc] init];
        kTextViewLeftMargin = [tempTextView caretRectForPosition:tempTextView.beginningOfDocument].origin.x;
    }
    return kTextViewLeftMargin;
}
