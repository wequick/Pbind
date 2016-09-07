//
//  LSForm.h
//  Less
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSScrollView.h"
#import "LSClient.h"
#import "LSInput.h"

//______________________________________________________________________________

typedef NS_OPTIONS(NSUInteger, LSFormValidateState)
{
    LSFormValidateStateInitialized = 0,
    LSFormValidateStateSubmitting = 1, // on form submitting
    LSFormValidateStateEndEditing = 1 << 1, // on text end editing
    LSFormValidateStateChanged = 1 << 2, // on text changed
};

typedef NS_OPTIONS(NSUInteger, LSFormIndicating)
{
    LSFormIndicatingMaskNone = 0,
    LSFormIndicatingMaskInputFocus = 1, // show indicator on the first responder input
    LSFormIndicatingMaskInputInvalid = 1 << 1, // show indicator on the invalid input
};

typedef NS_ENUM(NSInteger, LSFormMode) {
    LSFormModeInsert = 0, // insert data to `submitClient'
    LSFormModeUpdate = 1 // update data to `submitClient'. in this mode, we store `_initialParams' at beginning for passing changed-parameters while submitting
};

@class LSForm;

@protocol LSFormDelegate <NSObject>

@optional
// Submit
- (BOOL)formShouldSubmit:(LSForm *)form parameters:(NSDictionary *)parameters;
- (void)formWillSubmit:(LSForm *)form;
- (void)form:(LSForm *)form didSubmit:(LSResponse *)response handledError:(BOOL *)handledError;
// Reset
- (BOOL)formShouldReset:(LSForm *)form;
- (void)formWillReset:(LSForm *)form;
- (void)form:(LSForm *)form didReset:(LSResponse *)response;
// Validate
- (BOOL)form:(LSForm *)form validateInput:(id<LSInput>)input tips:(NSString * __autoreleasing*)tips forState:(LSFormValidateState)state;
- (void)form:(LSForm *)form didValidateInput:(id<LSInput>)input passed:(BOOL)passed tips:(NSString *)tips forState:(LSFormValidateState)state;
- (void)form:(LSForm *)form didEndEditingOnInput:(id<LSInput>)input;
- (void)formDidInvalidChanged:(LSForm *)form;
@end

//______________________________________________________________________________

@interface LSForm : LSScrollView
{
    struct {
        unsigned int validateState:4;
        unsigned int isWaitingForKeyboardShow:1;
        unsigned int isWaitingForAutomaticAdjustOffset:1;
        unsigned int hasScrollToInput:1;
        unsigned int needsReloadAccessoryView:1;
        
        unsigned int needsInitParams:1;
    } _formFlags;
    LSClient *_submitClient;
    NSString *_submitClientAction;
    LSClient *_resetClient;
    NSString *_resetClientAction;
    NSMutableArray *_invalidInputNames;
    NSDictionary *_initialParams;
    id _initialData;
    NSMutableDictionary *_radioGroups;
}

@property (nonatomic, strong) NSString *action; // submit action, accepts client://{LSClient}/$action
@property (nonatomic, strong) NSString *resetAction; // accepts client://{LSClient}/$action
@property (nonatomic, assign) id<LSFormDelegate> formDelegate;

@property (nonatomic, strong, readonly) NSDictionary *params;
@property (nonatomic, strong, readonly) NSDictionary *submitParams; // params to submit
@property (nonatomic, strong, readonly) id<LSInput> submitInput;

@property (nonatomic, assign) LSFormValidateState validateState;
@property (readonly, getter=isInvalid) BOOL invalid;

@property (nonatomic, assign) LSFormIndicating indicating;

@property (nonatomic, assign) LSFormMode mode;
@property (readonly, getter=isChanged) BOOL changed; // any input value changed

- (id<LSInput>)inputForName:(NSString *)name;
- (BOOL)isInvalidForName:(NSString *)name;
- (void)submit;
- (void)reset;

@end

FOUNDATION_EXPORT NSString *const LSFormWillSubmitNotification;
FOUNDATION_EXPORT NSString *const LSFormDidSubmitNotification;
FOUNDATION_EXPORT NSString *const LSFormWillResetNotification;
FOUNDATION_EXPORT NSString *const LSFormDidResetNotification;
FOUNDATION_EXPORT NSString *const LSFormDidValidateNotification;

FOUNDATION_EXPORT NSString *const LSFormValidateInputKey;
FOUNDATION_EXPORT NSString *const LSFormValidateStateKey;
FOUNDATION_EXPORT NSString *const LSFormValidatePassedKey;
FOUNDATION_EXPORT NSString *const LSFormValidateTipsKey;

FOUNDATION_EXPORT NSString *const LSFormHasHandledSubmitErrorKey;

