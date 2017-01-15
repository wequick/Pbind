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

@interface PBDatePicker : UIDatePicker <PBTextInput>
{
    struct {
        unsigned int pickerMode:3;
    } _pbFlags;
}

+ (instancetype)sharedDatePicker;

@end
