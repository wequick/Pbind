//
//  UIButton+PBForm.h
//  Pbind
//
//  Created by galen on 15/4/10.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBInput.h"

@interface UIButton (PBForm) <PBInput, PBInputDelegate>

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;
@property (nonatomic, strong) UILabel *placeholderLabel;

- (void)setTitle:(NSString *)title;
- (void)setHref:(NSString *)href;

@end

UIKIT_EXTERN NSString *const PBPopdownCoverWillShowNotification;
UIKIT_EXTERN NSString *const PBPopdownCoverDidShowNotification;
UIKIT_EXTERN NSString *const PBPopdownCoverWillHideNotification;
UIKIT_EXTERN NSString *const PBPopdownCoverDidHideNotification;
UIKIT_EXTERN NSString *const PBPopdownCoverViewKey;
