//
//  UIButton+LSForm.h
//  Less
//
//  Created by galen on 15/4/10.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSInput.h"

@interface UIButton (LSForm) <LSInput, LSInputDelegate>

@property (nonatomic, strong) NSString *type; // accepts ACTIONs(submit, present, push, popdown), radio
@property (nonatomic, strong) NSString *action; // for present/push/popdown. action is the class name of the controller which confirms to protocol `LSTextInput'
@property (nonatomic, strong) NSDictionary *actionProperties; // setValuesForKeysWithDictionary to `action controller'

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;
@property (nonatomic, strong) UILabel *placeholderLabel;

- (void)setTitle:(NSString *)title;
- (void)setHref:(NSString *)href;

@end

UIKIT_EXTERN NSString *const LSPopdownCoverWillShowNotification;
UIKIT_EXTERN NSString *const LSPopdownCoverDidShowNotification;
UIKIT_EXTERN NSString *const LSPopdownCoverWillHideNotification;
UIKIT_EXTERN NSString *const LSPopdownCoverDidHideNotification;
UIKIT_EXTERN NSString *const LSPopdownCoverViewKey;
