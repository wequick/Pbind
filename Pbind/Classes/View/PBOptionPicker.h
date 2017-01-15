//
//  PBOptionPicker.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBInput.h"

@interface PBOptionPicker : UIControl<PBTextInput, UIPickerViewDataSource, UIPickerViewDelegate>
{
    UIPickerView *_picker;
    CGFloat _componentWidth;
}

+ (instancetype)sharedOptionPicker;

+ (UIFont *)labelFont;

@property (nonatomic, strong) NSArray *options; // one-demension array components of NSDictionary with `text' and `value' key.
@property (nonatomic, strong) NSString *text; // selected text.
@property (nonatomic, strong) id value; // selected value.

- (void)setValue:(id)value animated:(BOOL)animated;

@end
