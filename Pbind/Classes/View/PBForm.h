//
//  PBForm.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBScrollView.h"
#import "PBClient.h"
#import "PBInput.h"

//______________________________________________________________________________

typedef NS_OPTIONS(NSUInteger, PBFormValidating)
{
    PBFormValidatingInitialized = 0,
    PBFormValidatingSubmitting = 1, // on form submitting
    PBFormValidatingEndEditing = 1 << 1, // on text end editing
    PBFormValidatingChanged = 1 << 2, // on text changed
};

typedef NS_OPTIONS(NSUInteger, PBFormIndicating)
{
    PBFormIndicatingMaskNone = 0,
    PBFormIndicatingMaskInputFocus = 1, // show indicator on the first responder input
    PBFormIndicatingMaskInputInvalid = 1 << 1, // show indicator on the invalid input
};

typedef NS_ENUM(NSInteger, PBFormMode) {
    PBFormModeInsert = 0, // insert data to `submitClient'
    PBFormModeUpdate = 1 // update data to `submitClient'. in this mode, we store `_initialParams' at beginning for passing changed-parameters while submitting
};

@class PBForm;

@protocol PBFormDelegate <NSObject>

@optional
// Submit
- (BOOL)formShouldSubmit:(PBForm *)form parameters:(NSDictionary *)parameters;
- (void)formWillSubmit:(PBForm *)form;
- (void)form:(PBForm *)form didSubmit:(PBResponse *)response handledError:(BOOL *)handledError;
// Reset
- (BOOL)formShouldReset:(PBForm *)form;
- (void)formWillReset:(PBForm *)form;
- (void)form:(PBForm *)form didReset:(PBResponse *)response;
// Validate
- (BOOL)form:(PBForm *)form validateInput:(id<PBInput>)input tips:(NSString * __autoreleasing*)tips forState:(PBFormValidating)state;
- (void)form:(PBForm *)form didValidateInput:(id<PBInput>)input passed:(BOOL)passed tips:(NSString *)tips forState:(PBFormValidating)state;
- (void)form:(PBForm *)form didEndEditingOnInput:(id<PBInput>)input;
- (void)formDidInvalidChanged:(PBForm *)form;
@end

//______________________________________________________________________________

/**
 The PBForm is one of the base components of Pbind. An instance of PBForm manages
 a group of inputs just like the behavior of web form.
 */
@interface PBForm : PBScrollView
{
    struct {
        unsigned int validating:4;
        unsigned int isWaitingForKeyboardShow:1;
        unsigned int isWaitingForAutomaticAdjustOffset:1;
        unsigned int hasScrollToInput:1;
        unsigned int needsInitParams:1;
    } _formFlags;
    NSDictionary *_initialParams;
    id _initialData;
}

#pragma mark - Styling
///=============================================================================
/// @name Styling
///=============================================================================

/**
 The behavior of the indicator (a rectangle covers on the input).
 
 @discussion Default to add following behavior:
 
 - PBFormIndicatingMaskInputFocus, displays the indicator with normal color while the input is focus.
 - PBFormIndicatingMaskInputInvalid, displays the indicator with red color while the input is invalid.
 
 @see PBFormIndicating
 */
@property (nonatomic, assign) PBFormIndicating indicating;

#pragma mark - Resulting
///=============================================================================
/// @name Resulting
///=============================================================================

/** 
 The invalid state for the form 
 
 @discussion Turns to be invalid if any of the input is invalid.
 */
@property (readonly, getter=isInvalid) BOOL invalid;

/**
 The changed state for the form
 
 @discussion Turns to be changed if any of the input has changed it's value.
 */
@property (readonly, getter=isChanged) BOOL changed;

#pragma mark - Incubating
///=============================================================================
/// @name Incubating
///=============================================================================

/** 
 The mode for the form 
 
 @see PBFormMode
 */
@property (nonatomic, assign) PBFormMode mode;

/**
 The time to validate the form.
 
 @see PBFormValidating
 */
@property (nonatomic, assign) PBFormValidating validating;

/** The delegate for the form */
@property (nonatomic, assign) id<PBFormDelegate> formDelegate;

/**
 Find the input with the name

 @param name the name of an input
 @return the input for the name
 */
- (id<PBInput>)inputForName:(NSString *)name;

/**
 Check if the named input is invalid

 @param name the name of an input
 @return YES if the input is invalid
 */
- (BOOL)isInvalidForName:(NSString *)name;

/**
 Verify the form

 @param complection the handler to do stuff after verified
 */
- (void)verify:(void (^)(BOOL passed, NSDictionary *parameters))complection;

/**
 Reset the value for all the inputs
 */
- (void)reset;

@end

FOUNDATION_EXPORT NSString *const PBFormWillSubmitNotification;
FOUNDATION_EXPORT NSString *const PBFormDidSubmitNotification;
FOUNDATION_EXPORT NSString *const PBFormWillResetNotification;
FOUNDATION_EXPORT NSString *const PBFormDidResetNotification;
FOUNDATION_EXPORT NSString *const PBFormDidValidateNotification;

FOUNDATION_EXPORT NSString *const PBFormValidateInputKey;
FOUNDATION_EXPORT NSString *const PBFormValidatingKey;
FOUNDATION_EXPORT NSString *const PBFormValidatePassedKey;
FOUNDATION_EXPORT NSString *const PBFormValidateTipsKey;

FOUNDATION_EXPORT NSString *const PBFormHasHandledSubmitErrorKey;

