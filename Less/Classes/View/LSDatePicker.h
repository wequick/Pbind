//
//  LSDatePicker.h
//  Less
//
//  Created by galen on 15/2/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSCompat.h"
#import "LSInput.h"

typedef NS_ENUM(NSInteger, LSDatePickerMode) {
    LSDatePickerModeMonth = UIDatePickerModeCountDownTimer + 1
};

@interface LSDatePicker : UIDatePicker <LSTextInput>
{
    struct {
        unsigned int pickerMode:3;
    } _lsFlags;
}

AS_SINGLETON(sharedDatePicker)

@end
