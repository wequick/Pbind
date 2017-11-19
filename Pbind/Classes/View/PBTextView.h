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

@interface PBTextLinkMatcher : NSObject

#pragma mark - Building
///=============================================================================
/// @name Building
///=============================================================================

@property (nonatomic, strong) NSString *pattern;

@property (nonatomic, strong) NSString *replacement;

#pragma mark - Styling
///=============================================================================
/// @name Styling
///=============================================================================

@property (nonatomic, strong) NSDictionary *attributes;

@property (nonatomic, strong) NSDictionary *deletingAttributes;

@end

/**
 An instance of PBTextView extends the ability of configuring the placeholder.
 */
@interface PBTextView : UITextView <PBInput, PBTextInputValidator, UITextViewDelegate>
{
    UILabel *_placeholderLabel;
    id/*NSString|NSAttributedString*/ _originalText;
    NSString *_originalValue;
    UIFont *_originalFont;
    NSString *_replacingString;
    NSRange _replacingRange;
    UITextRange *_previousMarkedTextRange;
    NSLayoutConstraint *_placeholderLeftMarginConstraint;
    NSLayoutConstraint *_placeholderRightMarginConstraint;
    NSLayoutConstraint *_heightConstraint;
    
    struct {
        unsigned int needsUpdateValue: 1;
        unsigned int lazyPostChangedNotification: 1;
    } _pbFlags;
}

/**
 The placeloder text.
 */
@property (nonatomic, strong) NSString *placeholder;

/**
 The text color for the placeholder label.
 */
@property (nonatomic, strong) UIColor *placeholderColor;

#pragma mark - AutoResizing
///=============================================================================
/// @name AutoResizing
///=============================================================================

/**
 The minimum frame size height for auto resizing
 */
@property (nonatomic, assign) CGFloat minHeight;

/**
 The maximum frame size height for auto resizing
 */
@property (nonatomic, assign) CGFloat maxHeight;

@property (nonatomic, strong) NSArray<PBTextLinkMatcher *> *linkMatchers; // pattern=>string, replacement=>string, attributes=>dict

#pragma mark - Forming
///=============================================================================
/// @name Forming
///=============================================================================

- (void)insertValue:(NSString *)value;

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

UIKIT_EXTERN NSNotificationName const PBTextViewTextWillBeginEditingNotification;
