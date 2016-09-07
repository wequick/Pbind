//
//  LSOptionPicker.h
//  Less
//
//  Created by galen on 15/4/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSCompat.h"
#import "LSInput.h"

@interface LSOptionPicker : UIControl<LSTextInput, UIPickerViewDataSource, UIPickerViewDelegate>
{
    UIPickerView *_picker;
    CGFloat _componentWidth;
}

AS_SINGLETON(sharedOptionPicker)

+ (UIFont *)labelFont;

@property (nonatomic, strong) NSArray *options; // one-demension array components of NSDictionary with `text' and `value' key.
@property (nonatomic, strong) NSString *text; // selected text.
@property (nonatomic, strong) id value; // selected value.

- (void)setValue:(id)value animated:(BOOL)animated;

@end
