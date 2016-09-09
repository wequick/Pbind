//
//  PBDatePicker.h
//  Pbind
//
//  Created by galen on 15/2/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBCompat.h"
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

AS_SINGLETON(sharedDatePicker)

@end
