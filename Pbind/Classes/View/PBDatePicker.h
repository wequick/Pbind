//
//  PBDatePicker.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/28.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBInput.h"

typedef NS_ENUM(NSInteger, PBDatePickerMode) {
    PBDatePickerModeMonth = UIDatePickerModeCountDownTimer + 1
};

/**
 An instance of PBDatePicker displays a date picker for it's owner PBInput.
 
 @discussion Supports picker modes:
 
 - UIDatePickerModeDate, 3 components with year, month and day
 - UIDatePickerModeTime, 3 components with hour, miniute and second
 - UIDatePickerModeDateAndTime, 6 components with year, month, day, hour, minute and secont
 
 Futhermore, we supports the month picker:
 
 - PBDatePickerModeMonth, 2 components with year and month
 */
@interface PBDatePicker : UIDatePicker <PBTextInput>
{
    struct {
        unsigned int pickerMode:3;
    } _pbFlags;
}

+ (instancetype)sharedDatePicker;

@end
