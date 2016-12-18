//
//  UIButton+PBForm.m
//  Pbind
//
//  Created by galen on 15/4/10.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "UIButton+PBForm.h"
#import "PBForm.h"
#import "UIView+Pbind.h"
#import "PBAction.h"

@implementation UIButton (PBForm)

- (void)setType:(NSString *)type {
    [self setValue:type forAdditionKey:@"type"];
}

- (NSString *)type {
    return [self valueForAdditionKey:@"type"];
}

- (void)setName:(NSString *)value {
    [self setValue:value forAdditionKey:@"name"];
}

- (NSString *)name {
    return [self valueForAdditionKey:@"name"];
}

- (void)setRequiredTips:(NSString *)value {
    [self setValue:value forAdditionKey:@"requiredTips"];
}

- (NSString *)requiredTips {
    return [self valueForAdditionKey:@"requiredTips"];
}

- (void)setPlaceholderLabel:(UILabel *)value {
    [self setValue:value forAdditionKey:@"placeholderLabel"];
}

- (UILabel *)placeholderLabel {
    return [self valueForAdditionKey:@"placeholderLabel"];
}

- (void)setRequired:(BOOL)required {
    [self setValue:(required ? @(required) : nil) forAdditionKey:@"required"];
}

- (BOOL)isRequired {
    return [[self valueForAdditionKey:@"required"] boolValue];
}

- (void)setTitle:(NSString *)title {
    [self setText:title];
}

- (void)setText:(NSString *)text {
    [self setTitle:text forState:UIControlStateNormal];
    if (text.length == 0) {
        self.placeholderLabel.hidden = NO;
    } else {
        self.placeholderLabel.hidden = YES;
    }
}

- (NSString *)text {
    return [self titleForState:UIControlStateNormal];
}

- (id)value {
    if ([[self type] isEqualToString:@"radio"] && !self.selected) {
        return nil;
    }
    return [self valueForAdditionKey:@"value"];
}

- (void)setValue:(id)value {
    [self setValue:value forAdditionKey:@"value"];
    if (value == nil) {
        [self setTitle:nil];
    }
}

- (void)reset {
}

#pragma mark -
#pragma mark - Placeholder

- (void)initPlaceholder {
    if (self.placeholderLabel == nil) {
        CGRect labelRect = [self.titleLabel convertRect:self.titleLabel.frame toView:self];
        self.placeholderLabel = [[UILabel alloc] initWithFrame:labelRect];
        [self.placeholderLabel setBackgroundColor:[UIColor clearColor]];
        [self.placeholderLabel setFont:self.titleLabel.font];
        [self.placeholderLabel setTextColor:[UIColor lightGrayColor]];
        [self.placeholderLabel setNumberOfLines:1];
        [self.placeholderLabel setTextAlignment:self.titleLabel.textAlignment];
        [self.placeholderLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:self.placeholderLabel];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    }
}

- (NSString *)placeholder {
    return [self valueForAdditionKey:@"placeholder"];
}

- (void)setPlaceholder:(NSString *)placeholder {
    [self initPlaceholder];
    [self.placeholderLabel setText:placeholder];
    [self.placeholderLabel sizeToFit];
    [self setValue:placeholder forAdditionKey:@"placeholder"];
}

- (UIColor *)placeholderColor {
    return [self valueForAdditionKey:@"placeholderColor"];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    [self initPlaceholder];
    [self.placeholderLabel setTextColor:placeholderColor];
    [self setValue:placeholderColor forAdditionKey:@"placeholderColor"];
}

#pragma mark -
#pragma mark - Click event

- (void)setHref:(NSString *)href {
    [self addTarget:self action:@selector(onHrefClick:) forControlEvents:UIControlEventTouchUpInside];
    [self setValue:href forAdditionKey:@"href"];
}

- (NSString *)href {
    return [self valueForAdditionKey:@"href"];
}

- (void)onHrefClick:(id)sender {
    PBViewClickHref(sender, [sender href]);
}

- (void)setAction:(NSDictionary *)action {
    [super setAction:action];
    [self addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)handleAction:(id)sender {
    [PBAction dispatchActionForView:sender];
}

- (void)textInput:(id<PBTextInput>)textInput didInputText:(NSString *)text value:(id)value {
    [self setTitle:text];
    [self setValue:value];
    id form = [self superview];
    while (form) {
        if ([form isKindOfClass:[PBForm class]]) {
            break;
        }
        form = [form superview];
    }
    if ([[form formDelegate] respondsToSelector:@selector(form:didEndEditingOnInput:)]) {
        [[form formDelegate] form:form didEndEditingOnInput:self];
    }
}

@end
