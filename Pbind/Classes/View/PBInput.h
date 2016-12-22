//
//  PBInput.h
//  Pbind
//
//  Created by galen on 15/2/27.
//  Copyright (c) 2015年 galen. All rights reserved.
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

- (BOOL)isEmpty; // default returns `value != nil'
- (CGRect)invalidIndicatorRect; // the rect for displaying a red box while validating failed

@end

//___________________________________________________________________________________________________

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

@property (nonatomic, strong) NSString *type; // accepts TEXTs(text, password, number, decimal, phone, url, email), PICKERs(date, time, datetime, month, select). If the type is select, then should follows with `options` or `selector`.
@property (nonatomic, strong) NSString *min; // minimum value. translate to `NSInteger' for number input, `CGfloat' for decimal input, `NSDate' for date inputs(e.g. '2015-2-1', '2015-2')
@property (nonatomic, strong) NSString *max; // maximum value. translate to `NSInteger' for number input, `CGfloat' for decimal input, `NSDate' for date inputs(e.g. '2015-2-1', '2015-2')
@property (nonatomic, assign) NSInteger step; // step value. map to `minuteInterval' for time input

@property (nonatomic, strong) NSString *unit; // default is nil. if set, place a `UILabel' with unit as `rightView' for editable inputs
@property (nonatomic, strong) UIColor *unitColor;
@property (nonatomic, strong) NSArray<NSDictionary<NSString *, id> *> *options; // for select input, as [{text:'a', value:0}, {text:'b', value:1}]

@property (nonatomic, assign) NSString *format; // default is nil. string format for text inputs, supports '#' expression (e.g. "66667777" & "## ## ## ##" = "66 66 77 77")

@property (nonatomic, strong) UIColor *placeholderColor;
@property (nonatomic, strong) UIColor *selectedTextColor; // default is view's tintColor

@property (nonatomic, strong) NSString *selector; // for select input. selector is the class name for the view which is a subclass of `PBInputView'

@property (nonatomic, assign) BOOL hidesCursor; //

@property (nonatomic, strong) NSArray<UIBarButtonItem *> *accessoryItems;

/* Handlers */
@property (nonatomic, strong) void (^onReset)(PBInput *input);

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
