//
//  PBInput.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

//___________________________________________________________________________________________________
@protocol PBTextInput;
@protocol PBInputDelegate <NSObject>

- (void)textInput:(id<PBTextInput>)textInput didInputText:(NSString *)text value:(id)value;

@end

//___________________________________________________________________________________________________

@class PBInput;
@protocol PBTextInput <NSObject>

@optional
+ (instancetype)sharedInput;
@property (nonatomic, assign) id<PBInputDelegate> inputDelegate;
- (NSString *)textForValue:(id)value;
- (void)inputDidBegin:(PBInput *)input;

@end

//___________________________________________________________________________________________________

@protocol PBTextInputValidator <NSObject>

@property (nonatomic, assign) NSInteger maxlength; // maximum text length for text inputs, both character and unicode counts as 1
@property (nonatomic, assign) NSInteger maxchars; // maximum character length for text inputs, character as 1, unicode as 2
@property (nonatomic, strong) NSString *pattern; // character regexp pattern (e.g. '[1-9]'). check for each character typed in, if no match, the typing will be ignored
@property (nonatomic, strong) NSArray *validators; // components of NSDictionary[pattern, tips]. each [pattern] is a sentence-scope regular expression (e.g. '^[1-9]+$') to validate the input's value while form submitting. If mismatched, passing [tips] to `PRFormDidValidateFailedNotification' notification and `form:didValidateFailed:onInput:' delegate of form

@end

//___________________________________________________________________________________________________

@protocol PBInput;

@protocol PBInputValueDelegate <NSObject>

- (BOOL)input:(id<PBInput>)input canChangeValue:(id)value;

@end

//___________________________________________________________________________________________________

@protocol PBInput <NSObject>

@required
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, copy) id value; // parse to `NSString' for text inputs, `NSInteger' for number input, `CGFloat' for decimal input, `NSDate' for date inputs
@property (nonatomic, getter=isRequired) BOOL required; // default is NO. if set to YES, the input value should not be empty
@property (nonatomic, strong) NSString *requiredTips;

- (void)reset;

@optional

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) BOOL acceptsClearOnAccessory;
@property (nonatomic, strong) NSArray *accessoryItems; // UIBarButtonItem
@property (nonatomic, strong) NSDictionary *errorRow; // the row to display validating error tips below current input

- (BOOL)isEmpty; // default returns `value != nil'
- (CGRect)invalidIndicatorRect; // the rect for displaying a red box while validating failed

@property (nonatomic, weak) id<PBInputValueDelegate> valueDelegate;

@property (nonatomic, assign, getter=isEditing) BOOL editing; // Whether the input is first responder

@end

//___________________________________________________________________________________________________

/**
 The PBInput is one of the base components of Pbind. An instance of PBInput provides the ability of inputing various type data.
 */
@interface PBInput : UITextField <PBInput, PBTextInputValidator, UITextFieldDelegate, PBInputDelegate>
{
    UIColor *_originalTextColor;
    NSString *_originalText;
    NSString *_replacingString;
    NSRange _replacingRange;
    UITextRange *_previousMarkedTextRange;
    NSMutableArray *_accessoryItems;
    NSMutableDictionary *_accessoryItemClickHandlers;
    id _minValue;
    id _maxValue;
    id _initialValue;
    struct {
        unsigned int pickerMode:3;
        unsigned int hidesCursor:1;
        unsigned int type:4;
        unsigned int isTextInput:1;
        unsigned int usingSharpFormat:1;
        unsigned int initValueOnRest:1;
        unsigned int hasInitTextByValue:1;
    } _inputFlag;
}

+ (void)registerType:(NSString *)type withInitialization:(void (^)(PBInput *input))initialization;

#pragma mark - Datasource
///=============================================================================
/// @name Datasource
///=============================================================================

/**
 The type for the input.
 
 @discussion Accept types:
 
 - text, input normal text with a text keyboard
 - password, input secret text with a text keyboard
 - number, input an integer with a numeric keyboard
 - decimal, input a float with a numeric keyboard
 - phone, input a phone number with a numeric keyboard
 - url, input an url with a text keyboard
 - email, input an email with a text keyboard
 - date, input a date with a date picker
 - time, input a time with a date picker
 - datetime, input a datetime with a date picker
 - month, input a month with a date picker
 - select, input a custom option with an option picker, requires setting of `options` or `selector`
 */
@property (nonatomic, strong) NSString *type;

/**
 The options for the `select` input
 
 @discussion Each option is a dictionay and should contains key of 'text' and 'value'.
 The 'text' is used for displaying and the 'value' for model. As example:
 
        [{text:'a', value:0}, {text:'b', value:1}]
 
 */
@property (nonatomic, strong) NSArray<NSDictionary<NSString *, id> *> *options;

/**
 The input view class name for the `select` input
 
 @discussion The class should be a subclass of `PBInputView`
 */
@property (nonatomic, strong) NSString *selector;

#pragma mark - Validating
///=============================================================================
/// @name Validating
///=============================================================================

/**
 The minimum value for the input
 
 @discussion Accepts value by the type:
 
 - number, integer
 - decimal, float
 - date, string with format as '2015-2-1'
 - month, string with format as '2015-2'
 */
@property (nonatomic, strong) NSString *min;

/**
 The maximum value for the input
 
 @discussion Accepts value by the type:
 
 - number, integer
 - decimal, float
 - date, string with format as '2015-2-1'
 - month, string with format as '2015-2'
 */
@property (nonatomic, strong) NSString *max;

#pragma mark - Styling
///=============================================================================
/// @name Styling
///=============================================================================

/**
 The unit text for the input.
 
 @discussion Default is nil. If set will place an `UILabel' as the `rightView' of the input to display the unit text.
 */
@property (nonatomic, strong) NSString *unit;

/** The text color for the unit label */
@property (nonatomic, strong) UIColor *unitColor;

/** The text color for the placeholder label */
@property (nonatomic, strong) UIColor *placeholderColor;

/** The text color for the input in the selected state. Default is the tint color of the input */
@property (nonatomic, strong) UIColor *selectedTextColor;

/** Whether hides the cursor while editing. Default is NO */
@property (nonatomic, assign) BOOL hidesCursor;

#pragma mark - Formating
///=============================================================================
/// @name Formating
///=============================================================================

/**
 The format for the input text. Default is nil means no format.
 
 @discussion Support format by type:
 
 - number, a string format which contains "%lld" such as "%lld pieces"
 - decimal, a string format which contains "%lf" such as "%.2lf"
 - any type, a sharp format to separate the word (e.g. "66667777" & "## ## ## ##" => "66 66 77 77")
 */
@property (nonatomic, assign) NSString *format;

#pragma mark - Incubating
///=============================================================================
/// @name Incubating
///=============================================================================

/** Step value. map to `minuteInterval' for time input */
@property (nonatomic, assign) NSInteger step;

/** The handler for reseting value for the input */
@property (nonatomic, strong) void (^onReset)(PBInput *input);

/** The additional items to display in the form accessory tool bar */
@property (nonatomic, strong) NSArray<UIBarButtonItem *> *accessoryItems;

- (void)config; // call on `initWithFrame' or `awakeFromNib'
- (void)addAccessoryItem:(UIBarButtonItem *)item withClickHandler:(void (^)(UIBarButtonItem *sender, PBInput *input))handler;

@end

UIKIT_EXTERN NSString *const PBInputTypeText;
UIKIT_EXTERN NSString *const PBInputTypePassword;
UIKIT_EXTERN NSString *const PBInputTypeNumber;
UIKIT_EXTERN NSString *const PBInputTypeDecimal;
UIKIT_EXTERN NSString *const PBInputTypePhone;
UIKIT_EXTERN NSString *const PBInputTypeUrl;
UIKIT_EXTERN NSString *const PBInputTypeEmail;
UIKIT_EXTERN NSString *const PBInputTypeDate;
UIKIT_EXTERN NSString *const PBInputTypeTime;
UIKIT_EXTERN NSString *const PBInputTypeDateAndTime;
UIKIT_EXTERN NSString *const PBInputTypeMonth;
UIKIT_EXTERN NSString *const PBInputTypeSelect;
UIKIT_EXTERN NSString *const PBInputTypeCustom;

UIKIT_EXTERN NSNotificationName const PBInputTextWillBeginEditingNotification;
