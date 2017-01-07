//
//  PBTextView.m
//  Pbind
//
//  Created by galen on 15/4/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBTextView.h"
#import "NSString+PBInput.h"

@implementation PBTextView

@synthesize type, name, value, required, requiredTips;
@synthesize maxlength, maxchars, pattern, validators;
@synthesize acceptsClearOnAccessory;
@synthesize errorRow;

- (id)init {
    if (self = [super init]) {
        [self config];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self config];
}

- (void)config {
    self.delegate = self;
    self.type = @"text";
    self.font = [PBInput new].font;
    self.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.acceptsClearOnAccessory = YES;
}

- (void)setValue:(id)aValue {
    if ([aValue isEqual:[NSNull null]]) {
        value = nil;
    } else {
        value = aValue;
    }
}

- (void)reset {
    self.text = nil;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    value = text;
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
    
    if (![text isEqual:[NSNull null]] && text.length != 0) {
        if (!_placeholderLabel.hidden) {
            _placeholderLabel.hidden = YES;
        }
    } else {
        _placeholderLabel.hidden = NO;
    }
}

- (void)initPlaceholder {
    if (_placeholderLabel == nil) {
        PBInput *tempInput = [PBInput new];
        tempInput.placeholder = @"temp";
        UIColor *placeholderColor = tempInput.placeholderColor;
        
        _placeholderLabel = [[UILabel alloc] init];
        [_placeholderLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_placeholderLabel setBackgroundColor:[UIColor clearColor]];
        [_placeholderLabel setFont:self.font];
        [_placeholderLabel setTextColor:placeholderColor];
        [_placeholderLabel setNumberOfLines:0];
        [_placeholderLabel setTextAlignment:NSTextAlignmentLeft];
        [self addSubview:_placeholderLabel];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_placeholderLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    [self initPlaceholder];
    [_placeholderLabel setText:placeholder];
    _placeholder = placeholder;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    [self initPlaceholder];
    [_placeholderLabel setTextColor:placeholderColor];
    _placeholderColor = placeholderColor;
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    if (_placeholderLabel != nil) {
        [_placeholderLabel setFont:font];
    }
}

- (void)updateConstraints {
    // Update placeholder label left and right margin by caret rect.
    if (_placeholderLabel != nil) {
        CGRect caretRect = [self caretRectForPosition:self.beginningOfDocument];
        if (_placeholderLeftMarginConstraint == nil) {
            _placeholderLeftMarginConstraint = [NSLayoutConstraint constraintWithItem:_placeholderLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:caretRect.origin.x];
            [self addConstraint:_placeholderLeftMarginConstraint];
        } else {
            _placeholderLeftMarginConstraint.constant = caretRect.origin.x;
        }
        
        if (_placeholderRightMarginConstraint == nil) {
            _placeholderRightMarginConstraint = [NSLayoutConstraint constraintWithItem:_placeholderLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:caretRect.origin.x];
        } else {
            _placeholderRightMarginConstraint.constant = caretRect.origin.x;
        }
    }
    
    // Update height
    CGSize size = [self sizeThatFits:CGSizeMake(self.bounds.size.width, FLT_MAX)];
    if (_heightConstraint == nil) {
        _heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:size.height];
        [self addConstraint:_heightConstraint];
    } else {
        _heightConstraint.constant = size.height;
    }
    
    [super updateConstraints];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    _originalText = textView.text;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (self.text.length == 0) {
        [_placeholderLabel setHidden:NO];
    } else {
        [_placeholderLabel setHidden:YES];
    }
    // Re-check text length for auto-correction inputs (Chinese, etc.)
    if (maxchars != 0 && [textView.text charaterLength] > maxchars) {
        textView.text = value = _originalText;
        return;
    }
    if (maxlength != 0 && [textView.text length] > maxlength) {
        textView.text = value = _originalText;
        return;
    }
    _originalText = value = textView.text;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string {
    if ([string isEqualToString:@""]) { // Backspace
        return YES;
    }
    
//    NSLog(@"--- %i-%i", (int)[textView.text length], (int)maxlength);
    if (maxchars != 0 && strlen([textView.text cStringUsingEncoding:NSUTF8StringEncoding]) == maxchars) {
        return NO;
    }
    if (maxlength != 0 && [textView.text length] == maxlength) {
        return NO;
    }
    
    if (pattern != nil) {
        NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
        if (![test evaluateWithObject:string]){
            return NO;
        }
    }
    
    return YES;
}

@end
