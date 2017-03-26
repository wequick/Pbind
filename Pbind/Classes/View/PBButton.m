//
//  PBButton.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/21.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBButton.h"
#import "UIView+Pbind.h"
#import "PBActionStore.h"
#import "PBInline.h"

@implementation PBButton
{
    UIColor *_backgroundColor;
    PBActionMapper *_actionMapper;
}

#pragma mark - PBInput

@synthesize type, name, value, required, requiredTips;

- (void)reset {
    
}

#pragma mark -

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    [super setBackgroundColor:backgroundColor];
}

- (void)setAction:(NSDictionary *)action {
    _actionMapper = [PBActionMapper mapperWithDictionary:action];
    [self addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)handleAction:(id)sender {
    [[PBActionStore defaultStore] dispatchActionWithActionMapper:_actionMapper context:self];
}

#pragma mark - State changing

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        [super setBackgroundColor:self.highlightedBackgroundColor];
    } else {
        [super setBackgroundColor:_backgroundColor];
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        [super setBackgroundColor:self.selectedBackgroundColor];
    } else {
        [super setBackgroundColor:_backgroundColor];
    }
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    if (enabled) {
        [super setBackgroundColor:_backgroundColor];
    } else {
        [super setBackgroundColor:self.disabledBackgroundColor];
    }
}

- (UIColor *)disabledBackgroundColor {
    if (_disabledBackgroundColor != nil) {
        return _disabledBackgroundColor;
    }
    return [_backgroundColor colorWithAlphaComponent:.2];
}

- (UIColor *)highlightedBackgroundColor {
    if (_highlightedBackgroundColor != nil) {
        return _highlightedBackgroundColor;
    }
    return [_backgroundColor colorWithAlphaComponent:.8];
}

- (UIColor *)selectedBackgroundColor {
    if (_selectedBackgroundColor != nil) {
        return _selectedBackgroundColor;
    }
    return _backgroundColor;
}

- (void)setTitleColor:(UIColor *)titleColor {
    [self setTitleColor:titleColor forState:UIControlStateNormal];
}

- (UIColor *)titleColor {
    return [self titleColorForState:UIControlStateNormal];
}

- (void)setTextColor:(UIColor *)titleColor {
    [self setTitleColor:titleColor forState:UIControlStateNormal];
}

- (UIColor *)textColor {
    return [self titleColorForState:UIControlStateNormal];
}

- (void)setDisabledTitleColor:(UIColor *)titleColor {
    [self setTitleColor:titleColor forState:UIControlStateDisabled];
}

- (UIColor *)disabledTitleColor {
    return [self titleColorForState:UIControlStateDisabled];
}

- (void)setHighlightedTitleColor:(UIColor *)titleColor {
    [self setTitleColor:titleColor forState:UIControlStateHighlighted];
}

- (UIColor *)highlightedTitleColor {
    return [self titleColorForState:UIControlStateHighlighted];
}

- (void)setSelectedTitleColor:(UIColor *)titleColor {
    [self setTitleColor:titleColor forState:UIControlStateSelected];
}

- (UIColor *)selectedTitleColor {
    return [self titleColorForState:UIControlStateSelected];
}

#pragma mark - PBInput

- (void)setText:(NSString *)text {
    [self setTitle:text forState:UIControlStateNormal];
}

- (NSString *)text {
    return [self titleForState:UIControlStateNormal];
}

#pragma mark - Configurable state

- (void)setTitle:(NSString *)title {
    [self setTitle:title forState:UIControlStateNormal];
}

- (NSString *)title {
    return [self titleForState:UIControlStateNormal];
}

- (void)setDisabledTitle:(NSString *)disabledTitle {
    [self setTitle:disabledTitle forState:UIControlStateDisabled];
}

- (NSString *)disabledTitle {
    return [self titleForState:UIControlStateDisabled];
}

- (void)setHighlightedTitle:(NSString *)highlightedTitle {
    [self setTitle:highlightedTitle forState:UIControlStateHighlighted];
}

- (NSString *)highlightedTitle {
    return [self titleForState:UIControlStateHighlighted];
}

- (void)setSelectedTitle:(NSString *)selectedTitle {
    [self setTitle:selectedTitle forState:UIControlStateSelected];
}

- (NSString *)selectedTitle {
    return [self titleForState:UIControlStateSelected];
}

- (void)setImage:(NSString *)image {
    _image = image;
    [self setImage:PBImage(image) forState:UIControlStateNormal];
}

- (void)setDisabledImage:(NSString *)disabledImage {
    _disabledImage = disabledImage;
    [self setImage:PBImage(disabledImage) forState:UIControlStateDisabled];
}

- (void)setHighlightedImage:(NSString *)highlightedImage {
    _highlightedImage = highlightedImage;
    [self setImage:PBImage(highlightedImage) forState:UIControlStateHighlighted];
}

- (void)setSelectedImage:(NSString *)selectedImage {
    _selectedImage = selectedImage;
    [self setImage:PBImage(selectedImage) forState:UIControlStateSelected];
}

- (void)setBackgroundImage:(NSString *)image {
    _backgroundImage = image;
    [self setBackgroundImage:PBImage(image) forState:UIControlStateNormal];
}

- (void)setDisabledBackgroundImage:(NSString *)disabledImage {
    _disabledBackgroundImage = disabledImage;
    [self setBackgroundImage:PBImage(disabledImage) forState:UIControlStateDisabled];
}

- (void)setHighlightedBackgroundImage:(NSString *)highlightedImage {
    _highlightedBackgroundImage = highlightedImage;
    [self setBackgroundImage:PBImage(highlightedImage) forState:UIControlStateHighlighted];
}

- (void)setSelectedBackgroundImage:(NSString *)selectedImage {
    _selectedBackgroundImage = selectedImage;
    [self setBackgroundImage:PBImage(selectedImage) forState:UIControlStateSelected];
}

@end
