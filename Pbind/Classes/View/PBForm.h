//
//  PBForm.h
//  Pbind
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015年 galen. All rights reserved.
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

@interface PBForm : PBScrollView
{
    struct {
        unsigned int validating:4;
        unsigned int isWaitingForKeyboardShow:1;
        unsigned int isWaitingForAutomaticAdjustOffset:1;
        unsigned int hasScrollToInput:1;
        unsigned int needsInitParams:1;
    } _formFlags;
    PBClient *_submitClient;
    NSString *_submitClientAction;
    PBClient *_resetClient;
    NSString *_resetClientAction;
    NSDictionary *_initialParams;
    id _initialData;
    NSMutableDictionary *_radioGroups;
}

@property (nonatomic, strong) NSString *action; // submit action, accepts client://{PBClient}/$action
@property (nonatomic, strong) NSString *resetAction; // accepts client://{PBClient}/$action
@property (nonatomic, assign) id<PBFormDelegate> formDelegate;

@property (nonatomic, strong, readonly) NSDictionary *params;
@property (nonatomic, strong, readonly) NSDictionary *submitParams; // params to submit

@property (readonly, getter=isInvalid) BOOL invalid;

@property (nonatomic, assign) PBFormValidating validating;
@property (nonatomic, assign) PBFormIndicating indicating;

@property (nonatomic, assign) PBFormMode mode;
@property (readonly, getter=isChanged) BOOL changed; // any input value changed

- (id<PBInput>)inputForName:(NSString *)name;
- (BOOL)isInvalidForName:(NSString *)name;

- (NSDictionary *)verifiedParamsForSubmit;
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

