//
//  PBInput.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBInput.h"
#import "PBDatePicker.h"
#import "PBForm.h"
#import "UIView+Pbind.h"
#import "PBOptionPicker.h"
#import "PBTextView.h"
#import "NSString+PBInput.h"

NSNotificationName const PBInputTextWillBeginEditingNotification = @"PBInputTextWillBeginEditingNotification";

//______________________________________________________________________________
// input type
NSString *const PBInputTypeText = @"text";
NSString *const PBInputTypePassword = @"password";
NSString *const PBInputTypeNumber = @"number";
NSString *const PBInputTypeDecimal = @"decimal";
NSString *const PBInputTypePhone = @"phone";
NSString *const PBInputTypeUrl = @"url";
NSString *const PBInputTypeEmail = @"email";
NSString *const PBInputTypeDate = @"date";
NSString *const PBInputTypeTime = @"time";
NSString *const PBInputTypeDateAndTime = @"datetime";
NSString *const PBInputTypeMonth = @"month";
NSString *const PBInputTypeSelect = @"select";
NSString *const PBInputTypeCustom = @"custom";
static const NSInteger kInputTypeUnknown = 0;
static const NSInteger kInputTypeText = 1;
static const NSInteger kInputTypePassword = 2;
static const NSInteger kInputTypeNumber = 3;
static const NSInteger kInputTypeDecimal = 4;
static const NSInteger kInputTypePhone = 5;
static const NSInteger kInputTypeUrl = 6;
static const NSInteger kInputTypeEmail = 7;
static const NSInteger kInputTypeDate = 8;
static const NSInteger kInputTypeTime = 9;
static const NSInteger kInputTypeDateAndTime = 10;
static const NSInteger kInputTypeMonth = 11;
static const NSInteger kInputTypeSelect = 12;
static const NSInteger kInputTypeCustom = 0xf;

// format
static NSString *const kInputFormatNumber = @"%lld";
static NSString *const kInputFormatDecimal = @"%.1lf";
static NSString *const kInputFormatDateAndTime = @"yyyy-MM-dd HH:mm";
static NSString *const kInputFormatDate = @"yyyy-MM-dd";
static NSString *const kInputFormatTime = @"HH:mm";
static NSString *const kInputFormatMonth = @"yyyy-MM";
static NSString *const kInputFlagSharp = @"#";
static const char      kInputCharSharp = '#';
// pattern
static NSString *const kInputPatternNumber = @"[0-9]";
static NSString *const kInputPatternDecimal = @"[0-9\\.]";
// key path
static NSString *const kInputKeyPathPlaceholderTextColor = @"_placeholderLabel.textColor";

//______________________________________________________________________________

@implementation PBInput

@synthesize acceptsClearOnAccessory;
@synthesize accessoryItems = _accessoryItems;
@synthesize name, value, required, requiredTips;
@synthesize maxlength, maxchars, pattern, validators;
@synthesize errorRow;

static NSMutableDictionary *kInitializations = nil;

+ (void)registerType:(NSString *)type withInitialization:(void (^)(PBInput *input))initialization
{
    if (type == nil || initialization == nil) {
        return;
    }
    if (kInitializations == nil) {
        kInitializations = [[NSMutableDictionary alloc] init];
    }
    [kInitializations setObject:initialization forKey:type];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self config];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self config];
}

- (void)config
{
    super.delegate = self;
    [self addTarget:self action:@selector(textFieldDidBegin:) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    _type = PBInputTypeText;
    self.acceptsClearOnAccessory = YES;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self initValues];
}

- (void)dealloc {
    
}

- (void)setUnit:(NSString *)unit
{
    UILabel *label = (id)self.rightView;
    if (label == nil || ![label isKindOfClass:[UILabel class]]) {
        NSDictionary *textAttrs = @{NSFontAttributeName: self.font};
        CGFloat width = [unit sizeWithAttributes:textAttrs].width;
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width + 8, self.bounds.size.height)];
        [label setTextAlignment:NSTextAlignmentRight];
        [label setFont:self.font];
        [label setBackgroundColor:[UIColor clearColor]];
        self.rightView = label;
        self.rightViewMode = UITextFieldViewModeAlways;
    }
    [label setText:unit];
    if (_unitColor != nil) {
        [label setTextColor:_unitColor];
    }
    _unit = unit;
}

- (void)setUnitColor:(UIColor *)unitColor
{
    UILabel *label = (id)self.rightView;
    if (label != nil) {
        [label setTextColor:unitColor];
    }
    _unitColor = unitColor;
}

- (void)setFormat:(NSString *)format
{
    _format = format;
    BOOL hasSharpChar = [format rangeOfString:kInputFlagSharp].length != 0;
    BOOL hasFormatChar = [format rangeOfString:@"%"].length != 0;
    _inputFlag.usingSharpFormat = (hasSharpChar && !hasFormatChar);
}

- (id)value
{
    // TODO: fix number crash
    if (_inputFlag.usingSharpFormat && value != nil) {
        return [NSString stringWithString:value];
    }
    return value;
}

- (void)setValue:(id)aValue
{
    if (value == nil && aValue != nil && !_inputFlag.hasInitTextByValue) {
        value = aValue;
        [self __initText];
        _inputFlag.hasInitTextByValue = YES;
    } else {
        value = aValue;
    }
    if (self.inputView != nil && [self isEditing]) {
        /* Notify form to validate value of self
         * @see [PBForm inputDidChange:]
         */
        if ([self.inputView superview] == nil) {
            // Not yet presented, delay to post notification
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
            });
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
        }
    }
}

- (void)setHidesCursor:(BOOL)hidesCursor
{
    _inputFlag.hidesCursor = hidesCursor;
}

- (BOOL)hidesCursor
{
    return _inputFlag.hidesCursor;
}

- (void)reset {
    if (_inputFlag.initValueOnRest && _initialValue) {
        value = _initialValue;
        [self __initText];
    } else {
        self.text = nil;
        value = nil;
    }
    
    if (self.onReset != nil) {
        self.onReset(self);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
}

- (NSString *)__stringByFormattingString:(NSString *)text {
    if (_inputFlag.usingSharpFormat) {
        NSMutableString *formattedString = [[NSMutableString alloc] init];
        NSInteger iSrc = 0, iFmt = 0;
        NSInteger srcLength = [text length];
        NSInteger fmtLength = [_format length];
        while (iSrc < srcLength && iFmt < fmtLength) {
            NSString *aChar;
            NSRange charRange = NSMakeRange(iFmt++, 1);
            NSString *flag = [_format substringWithRange:charRange];
            if ([flag isEqualToString:kInputFlagSharp]) {
                charRange.location = iSrc++;
                aChar = [text substringWithRange:charRange];
            } else {
                aChar = flag;
            }
            [formattedString appendString:aChar];
        }
        return formattedString;
    }
    
    return text;
}

- (void)textInput:(id<PBTextInput>)textInput didInputText:(NSString *)text value:(id)aValue
{
    [super setText:text];
    [self setValue:aValue];
}

#pragma mark - Extensions

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    [self setValue:placeholderColor forKeyPath:kInputKeyPathPlaceholderTextColor];
}

- (UIColor *)placeholderColor
{
    return [self valueForKeyPath:kInputKeyPathPlaceholderTextColor];
}

- (void)setSelected:(BOOL)selected
{
    if (selected) {
        if (_selectedTextColor != nil) {
            if (_originalTextColor == nil) {
                _originalTextColor = [self textColor];
            }
            [super setTextColor:_selectedTextColor];
        }
    } else {
        if (_originalTextColor != nil) {
            [super setTextColor:_originalTextColor];
        }
    }
}

- (void)setTextColor:(UIColor *)textColor {
    if (_selectedTextColor != nil) {
        _originalTextColor = textColor;
    }
    [super setTextColor:textColor];
}

- (void)setEditing:(BOOL)editing {
    if (editing) {
        if (![self canBecomeFirstResponder]) {
            return;
        }
        [self becomeFirstResponder];
    } else {
        if (![self canResignFirstResponder]) {
            return;
        }
        [self resignFirstResponder];
    }
}

- (void)notifyEditingChanged {
    [self willChangeValueForKey:@"editing"];
    [self didChangeValueForKey:@"editing"];
}


#pragma mark - Hacker

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    if (self.hidesCursor) {
        return CGRectZero; // Hide cursor
    }
    return [super caretRectForPosition:position];
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect rect = [super textRectForBounds:bounds];
    return [self rectByAdjustingRect:rect];
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect rect = [super editingRectForBounds:bounds];
    return [self rectByAdjustingRect:rect];
}

- (CGRect)rectByAdjustingRect:(CGRect)rect {
    if (self.borderStyle != UITextBorderStyleRoundedRect &&
        (self.textAlignment == NSTextAlignmentLeft || self.textAlignment == NSTextAlignmentNatural)) {
        CGFloat margin = PBTextViewLeftMargin();
        rect.origin.x += margin;
        rect.size.width -= margin;
    }
    return rect;
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range
{
    if (self.hidesCursor) {
        return nil; // Disable selection
    }
    return [super selectionRectsForRange:range];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (self.hidesCursor) {
        if (action == @selector(copy:) || action == @selector(selectAll:) || action == @selector(paste:))
        {
            return NO; // Diable magnifying glass
        }
    }
    return [super canPerformAction:action withSender:sender];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([NSStringFromSelector(aSelector) isEqualToString:@"customOverlayContainer"]) {
        // Hack for iOS6, avoid stack overflow
        return NO;
    }
    return [super respondsToSelector:aSelector];
}

- (BOOL)canBecomeFirstResponder {
    UIView *inputView = self.inputView;
    if (inputView != nil && inputView.bounds.size.height == 0) {
        return NO;
    }
    return [super canBecomeFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] postNotificationName:PBInputTextWillBeginEditingNotification object:self];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self notifyEditingChanged];
    if (self.inputView != nil) {
        if ([self.inputView isKindOfClass:[PBDatePicker class]]) {
            PBDatePicker *picker = (id)self.inputView;
            [picker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
            // Init settings
            picker.datePickerMode = _inputFlag.pickerMode;
            picker.minimumDate = _minValue;
            picker.maximumDate = _maxValue;
            NSLog(@"%@", _maxValue);
            // Init value
            if (value == nil) {
                [picker setDate:[NSDate date]];
                [picker sendActionsForControlEvents:UIControlEventValueChanged]; // Invoke the registered event listener to init `self.value'
            } else if ([value isKindOfClass:[NSDate class]]) {
                [picker setDate:value animated:YES];
            }
        } else if ([self.inputView isKindOfClass:[PBOptionPicker class]]) {
            PBOptionPicker *picker = (id)self.inputView;
            [picker addTarget:self action:@selector(optionPickerValueChanged:) forControlEvents:UIControlEventValueChanged];
            picker.options = _options;
            // Init value
            if (value == nil) {
                [picker setValue:[[_options firstObject] objectForKey:@"value"]];
                [picker sendActionsForControlEvents:UIControlEventValueChanged]; // Invoke the registered event listener to init `self.value'
            } else {
                [picker setValue:value animated:YES];
            }
        } else if ([self.inputView respondsToSelector:@selector(inputDidBegin:)]) {
            [(id)self.inputView inputDidBegin:self];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL shouldChange = YES;
    
    do {
        if ([string isEqualToString:@""]) { // Backspace
            break;
        }
        
        // Limits length
        if (maxchars != 0 && [textField.text charaterLength] == maxchars) {
            shouldChange = NO;
            break;
        }
        if (maxlength != 0 && [textField.text length] == maxlength) {
            shouldChange = NO;
            break;
        }
        
        // Validates pattern
        if (pattern != nil) {
            NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
            if (![test evaluateWithObject:string]){
                shouldChange = NO;
                break;
            }
        }
        
        // Limits value range
        if (_inputFlag.type == kInputTypeNumber) {
            NSString *newString = [self.text stringByAppendingString:string];
            NSInteger newValue = [newString integerValue];
            if (_maxValue != nil && newValue > [_maxValue integerValue]) {
                shouldChange = NO;
                break;
            }
        } else if (_inputFlag.type == kInputTypeDecimal) {
            NSString *newString = [self.text stringByAppendingString:string];
            CGFloat newValue = [newString floatValue];
            if (_maxValue != nil && newValue > [_maxValue floatValue]) {
                shouldChange = NO;
                break;
            }
        }
    } while (false);
    
    if (shouldChange) {
        if (_replacingString == nil) { // Save to format text at `textFieldDidChange:'
            _replacingRange = range;
            _replacingString = string;
        }
    }
    
    return shouldChange;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self notifyEditingChanged];
    if (self.inputView != nil) {
        if ([self.inputView isKindOfClass:[PBDatePicker class]]) {
            PBDatePicker *picker = (id)self.inputView;
            [picker removeTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
        } else if ([self.inputView isKindOfClass:[PBOptionPicker class]]) {
            PBOptionPicker *picker = (id)self.inputView;
            [picker removeTarget:self action:@selector(optionPickerValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
    } else if (!_inputFlag.usingSharpFormat) {
        // Update value by text (endEditing)
        if (_inputFlag.type == kInputTypeNumber) {
            long long number = [textField.text longLongValue];
            if (number != 0) {
                NSString *format = self.format ?: kInputFormatNumber;
                textField.text = [NSString stringWithFormat:format, number];
                value = [NSNumber numberWithLongLong:number];
            } else {
                value = nil;
            }
        } else if (_inputFlag.type == kInputTypeDecimal) {
            double decimal = [textField.text doubleValue];
            if (decimal != 0) {
                NSString *format = self.format ?: kInputFormatDecimal;
                textField.text = [NSString stringWithFormat:format, decimal];
                value = [NSNumber numberWithDouble:decimal];
            } else {
                value = nil;
            }
        }
    }
}

- (BOOL)textFieldShouldClear:(nonnull UITextField *)textField {
    // Add this for AOP
    return YES;
}

- (BOOL)textFieldShouldReturn:(nonnull UITextField *)textField {
    // Add this for AOP
    if (_originalText != nil && ![_originalText isEqualToString:textField.text]) {
        // Re-check for auto-correction inputs (Chinese, etc.)
        NSString *temp = [_originalText copy];
        [self textFieldDidChange:textField];
        if (![temp isEqualToString:_originalText]) {
            // Allow changing
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
            });
        }
    }
    return YES;
}

#pragma mark - ControlEvents

- (void)textFieldDidBegin:(UITextField *)textField {
    _originalText = textField.text;
}

- (void)textFieldDidChange:(UITextField *)textField {
    // Re-check text length for auto-correction inputs (Chinese, etc.)
    if (maxchars != 0 && [textField.text charaterLength] > maxchars) {
        textField.text = _originalText;
        return;
    }
    if (maxlength != 0 && [textField.text length] > maxlength) {
        textField.text = _originalText;
        return;
    }
    
    // Format text
    if (_inputFlag.usingSharpFormat) {
        if (textField.markedTextRange == nil) { // End inputing
            // Limits length
            NSInteger maxLength = [self.format length];
            if ([textField.text length] > maxLength) {
                textField.text = [textField.text substringToIndex:maxLength];
                _originalText = textField.text;
                _replacingString = nil;
                [value setString:textField.text];
                return;
            }
            
            NSString *replacingString = _replacingString;
            NSRange replacingRange = _replacingRange;
            if (_previousMarkedTextRange != nil) {
                // Autocomplete
                UITextRange *replacingTextRange = _previousMarkedTextRange;
                if (replacingString == nil) {
                    replacingRange.location = [textField offsetFromPosition:textField.beginningOfDocument toPosition:replacingTextRange.start];
                    replacingRange.length = 0;
                }
                replacingString = [textField textInRange:replacingTextRange];
            }
            if (replacingString == nil) {
                const char *str1 = [_originalText UTF8String];
                const char *str2 = [textField.text UTF8String];
                if (*str2 == '\0') {
                    _originalText = textField.text;
                    value = nil;
                    return;
                }
                
                char *p1 = (char *)str1;
                char *p2 = (char *)str2;
                int pos = 0;
                while (*p1++ == *p2++) {
                    pos++;
                    if (*p1 == '\0' || *p2 == '\0') {
                        break;
                    }
                }
                
                replacingRange = NSMakeRange(pos, strlen(str1) - pos);
                replacingString = [[NSString alloc] initWithUTF8String:p2-1];
            }
            [self formatTextField:textField afterChangeCharactersInRange:replacingRange replacementString:replacingString];
            _replacingString = nil;
        }
        
        _previousMarkedTextRange = textField.markedTextRange;
    }
    
    _originalText = textField.text;
    
    // Update value
    [self __updateValueByTextOnChanged:textField.text];
}

- (void)datePickerValueChanged:(UIDatePicker *)picker {
    if (![self isFirstResponder]) {
        return;
    }
    
    [self setValue:picker.date];
    NSString *text = [(id)self.inputView textForValue:picker.date];
    [self setText:text];
}

- (void)optionPickerValueChanged:(PBOptionPicker *)picker {
    if (![self isFirstResponder]) {
        return;
    }
    
    [self setValue:picker.value];
    NSString *text = [(id)self.inputView textForValue:picker.value];
    [self setText:text];
}

#pragma mark - Other

#define TryReturn(_type_) \
if ([type isEqualToString:PBInputType##_type_]) return kInputType##_type_

- (unsigned int)inputTypeForString:(NSString *)type {
    TryReturn(Text);
    TryReturn(Password);
    TryReturn(Number);
    TryReturn(Decimal);
    TryReturn(Phone);
    TryReturn(Url);
    TryReturn(Email);
    TryReturn(Date);
    TryReturn(Time);
    TryReturn(DateAndTime);
    TryReturn(Month);
    TryReturn(Select);
    TryReturn(Custom);
    return kInputTypeUnknown;
}

- (void)initValues
{
    if (_inputFlag.type != 0) {
        return;
    }
    _initialValue = value;
    // Initialize input view
    NSString *dateFormat = nil;
    unsigned int pickerMode = 0;
    
    _inputFlag.type = [self inputTypeForString:self.type];
    
    switch (_inputFlag.type) {
        case kInputTypeText:
            _inputFlag.isTextInput = YES;
            break;
        case kInputTypePassword:
            _inputFlag.isTextInput = YES;
            self.secureTextEntry = YES;
            break;
        case kInputTypeNumber:
            [self setKeyboardType:UIKeyboardTypeNumberPad];
            [self setPattern:kInputPatternNumber];
            if (_min != nil) {
                _minValue = [NSNumber numberWithLongLong:[_min longLongValue]];
            }
            if (_max != nil) {
                _maxValue = [NSNumber numberWithLongLong:[_max longLongValue]];
            }
            break;
        case kInputTypeDecimal:
            [self setKeyboardType:UIKeyboardTypeDecimalPad];
            [self setPattern:kInputPatternDecimal];
            if (_min != nil) {
                _minValue = [NSNumber numberWithDouble:[_min doubleValue]];
            }
            if (_max != nil) {
                _maxValue = [NSNumber numberWithDouble:[_max doubleValue]];
            }
            break;
        case kInputTypePhone:
            _inputFlag.isTextInput = YES;
            [self setKeyboardType:UIKeyboardTypePhonePad];
            break;
        case kInputTypeUrl:
            _inputFlag.isTextInput = YES;
            [self setKeyboardType:UIKeyboardTypeURL];
            break;
        case kInputTypeEmail:
            _inputFlag.isTextInput = YES;
            [self setKeyboardType:UIKeyboardTypeEmailAddress];
            break;
        case kInputTypeDate:
            pickerMode = UIDatePickerModeDate;
            dateFormat = kInputFormatDate;
            break;
        case kInputTypeTime:
            pickerMode = UIDatePickerModeTime;
            dateFormat = kInputFormatTime;
            break;
        case kInputTypeDateAndTime:
            pickerMode = UIDatePickerModeDateAndTime;
            dateFormat = kInputFormatDateAndTime;
            break;
        case kInputTypeMonth:
            pickerMode = PBDatePickerModeMonth;
            dateFormat = kInputFormatMonth;
            break;
        case kInputTypeSelect:
            if (self.selector != nil) {
                UIView *view;
                Class clazz = NSClassFromString(self.selector);
                if ([clazz instancesRespondToSelector:@selector(sharedInput)]) {
                    view = [clazz sharedInput];
                } else {
                    view = [[clazz alloc] init];
                }
                if ([view conformsToProtocol:@protocol(PBTextInput)]) {
                    [(id<PBTextInput>)view setInputDelegate:self];
                }
                [self setInputView:view];
                [self setHidesCursor:YES];
                [self setSelectedTextColor:[self tintColor]];
            } else if (self.options != nil) {
                PBOptionPicker *picker = [PBOptionPicker sharedOptionPicker];
                [self setInputView:picker];
                [self setHidesCursor:YES];
                [self setSelectedTextColor:[self tintColor]];
            } else {
                NSLog(@"Pbind: the 'select' input requires 'options' or 'selector'.");
            }
            self.acceptsClearOnAccessory = !self.required;
            _inputFlag.initValueOnRest = self.required;
            break;
        case kInputTypeCustom: {
                void (^initialization)(PBInput *) = [kInitializations objectForKey:self.type];
                if (initialization != nil) {
                    initialization(self);
                }
            }
            break;
        default:
            NSLog(@"Pbind: Unknown input type: '%@'.", self.type);
            break;
    }
    
    // Initialize min & max value
    if (dateFormat != nil) {
        PBDatePicker *picker = [PBDatePicker sharedDatePicker];
        [self setInputView:picker];
        [self setHidesCursor:YES];
        [self setSelectedTextColor:[self respondsToSelector:@selector(tintColor)] ? [self tintColor] : [UIColor blackColor]];
        if (_min != nil) {
            if ([_min isKindOfClass:[NSString class]]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:dateFormat];
                _minValue = [formatter dateFromString:_min];
            } else if ([_min isKindOfClass:[NSDate class]]) {
                _minValue = _min;
            }
        }
        if (_max != nil) {
            if ([_max isKindOfClass:[NSString class]]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:dateFormat];
                _maxValue = [formatter dateFromString:_max];
            } else if ([_max isKindOfClass:[NSDate class]]) {
                _maxValue = _max;
            }
        }
        _inputFlag.pickerMode = pickerMode;
        self.acceptsClearOnAccessory = !self.required;
        _inputFlag.initValueOnRest = self.required;
    }
    
    // Initialize text by value
    if (value != nil) {
        [self __initText];
        _inputFlag.hasInitTextByValue = YES;
    }
    
    // Formattor
    if ([self.format length] > 0) {
        if (_inputFlag.usingSharpFormat) {
            value = [[NSMutableString alloc] initWithString:self.text];
            if ([self.text length] > 0) {
                self.text = [self __stringByFormattingString:value];
            }
        }
    }
}

- (void)__initText {
    if (_inputFlag.type == kInputTypeNumber) {
        long long num = [value longLongValue];
        if (num != 0) {
            NSString *format = [self format] ?: kInputFormatNumber;
            [super setText:[NSString stringWithFormat:format, num]];
        }
    } else if (_inputFlag.type == kInputTypeDecimal) {
        double num = [value doubleValue];
        if (num != 0) {
            NSString *format = [self format] ?: kInputFormatDecimal;
            [super setText:[NSString stringWithFormat:format, num]];
        }
    } else if ([self.inputView respondsToSelector:@selector(textForValue:)]) {
        if ([self.inputView isKindOfClass:[PBDatePicker class]]) {
            PBDatePicker *picker = (id)self.inputView;
            // Init settings
            picker.datePickerMode = _inputFlag.pickerMode;
            picker.minimumDate = _minValue;
            picker.maximumDate = _maxValue;
            NSLog(@"%@", _maxValue);
            // Init value
            if ([self.value isKindOfClass:[NSNumber class]]) {
                NSTimeInterval interval = [self.value longLongValue];
                if (interval == 0) {
                    self.value = nil;
                } else if (interval > 0) {
                    self.value = [NSDate dateWithTimeIntervalSince1970:interval];
                }
            }
            if ([self.value isKindOfClass:[NSDate class]]) {
                [picker setDate:self.value];
            }
        } else if ([self.inputView isKindOfClass:[PBOptionPicker class]]) {
            PBOptionPicker *picker = (id)self.inputView;
            picker.options = _options;
            // Init value
            [picker setValue:self.value];
        }
        NSString *text = [(id)self.inputView textForValue:value];
        if (text != nil) {
            [super setText:text];
        }
    } else if (_inputFlag.isTextInput) {
//        [super setText:value];
    }
}

- (BOOL)isEmpty {
    if (_inputFlag.usingSharpFormat) {
        return [value length] == 0;
    } else {
        if (value != nil) {
            return NO;
        } else {
            return ([self.text isEqual:[NSNull null]] || [self.text length] == 0);
        }
    }
}

- (void)formatTextField:(nonnull UITextField *)textField afterChangeCharactersInRange:(NSRange)range replacementString:(nonnull NSString *)string {
    NSInteger location = range.location;
    NSInteger length = 0;
    NSInteger index = 0;
    
    if (value == nil) {
        value = [[NSMutableString alloc] init];
    }
    
    for (; index < range.length; index++) {
        char flag = [self.format characterAtIndex:location+index];
        if (flag == kInputCharSharp) {
            length++;
        }
    }
    for (index = location - 1; index > 0; index--) {
        char flag = [self.format characterAtIndex:index];
        if (flag != kInputCharSharp) {
            location--;
        }
    }
    
    if (length == 0) {
        if (location >= [value length]) {
            if ([string length] == 0) {
                if (location == 0) {
                    // ??? If the text is empty -> Delete -> Append, go to this.
                    [value setString:textField.text];
                    return;
                } else {
                    // Delete
                    NSRange deleteRange = NSMakeRange(location - 1, length + 1);
                    [value deleteCharactersInRange:deleteRange];
                }
            } else {
                // Append
                [value appendString:string];
            }
        } else {
            // Insert
            [value insertString:string atIndex:location];
        }
    } else {
        // Replace
        NSRange replaceRange = NSMakeRange(location, length);
        [value replaceCharactersInRange:replaceRange withString:string];
    }
    
    NSString *formatText = [self __stringByFormattingString:value];
    [textField setText:formatText];
}

- (void)__updateValueByTextOnChanged:(NSString *)text {
    if (_inputFlag.isTextInput && !_inputFlag.usingSharpFormat) {
        if ([text length] == 0) {
            value = _initialValue;
        } else {
            value = text;
        }
    }
}

#pragma mark - Accessory

- (void)addAccessoryItem:(UIBarButtonItem *)item withClickHandler:(void (^)(UIBarButtonItem *sender, PBInput *input))handler {
    if (_accessoryItems == nil) {
        _accessoryItems = [[NSMutableArray alloc] init];
    }
    [_accessoryItems addObject:item];
    [item setTarget:self];
    [item setAction:@selector(accessoryItemClick:)];
    
    if (_accessoryItemClickHandlers == nil) {
        _accessoryItemClickHandlers = [[NSMutableDictionary alloc] init];
    }
    [_accessoryItemClickHandlers setObject:handler forKey:@([item hash])];
}

- (void)accessoryItemClick:(UIBarButtonItem *)item {
    void (^handler)(UIBarButtonItem *sender, PBInput *) = [_accessoryItemClickHandlers objectForKey:@([item hash])];
    if (handler != nil) {
        handler(item, self);
    }
}

#pragma mark - UITextInput

- (BOOL)shouldChangeTextInRange:(nonnull UITextRange *)range replacementText:(nonnull NSString *)text {
    NSInteger loc = [self offsetFromPosition:self.beginningOfDocument toPosition:range.start];
    NSInteger len = [self offsetFromPosition:range.start toPosition:range.end];
    return [self textField:self shouldChangeCharactersInRange:NSMakeRange(loc, len) replacementString:text];
}

- (void)insertText:(nonnull NSString *)text {
    if ([self shouldChangeTextInRange:self.selectedTextRange replacementText:text]) {
        [super insertText:text];
    }
}

- (void)replaceRange:(nonnull UITextRange *)range withText:(nonnull NSString *)text {
    if ([self shouldChangeTextInRange:range replacementText:text]) {
        [super replaceRange:range withText:text];
    }
}

- (void)deleteBackward {
    UITextPosition *start = [self positionFromPosition:self.selectedTextRange.start offset:-1];
    UITextRange *range = [self textRangeFromPosition:start toPosition:self.selectedTextRange.end];
    if ([self shouldChangeTextInRange:range replacementText:@""]) {
        [super deleteBackward];
    }
}

@end
