//
//  LSOptionPicker.m
//  Less
//
//  Created by galen on 15/4/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSOptionPicker.h"

@implementation LSOptionPicker

DEF_SINGLETON(sharedOptionPicker)

+ (UIFont *)labelFont
{
    static UIFont *font = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        float version = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (version >= 7.0f) {
            font = [UIFont systemFontOfSize:24];
        } else {
            font = [UIFont boldSystemFontOfSize:26];
        }
    });
    return font;
}

- (id)init {
    if (self = [super init]) {
        UIPickerView *picker = [[UIPickerView alloc] init];
        [picker setDelegate:self];
        [picker setDataSource:self];
        [picker setShowsSelectionIndicator:YES];
        [self addSubview:picker];
        [self setFrame:picker.bounds];
        _picker = picker;
    }
    return self;
}

- (void)setValue:(id)value {
    [self setValue:value animated:NO];
}

- (void)setOptions:(NSArray *)options {
    BOOL changed = (_options != nil && ![_options isEqualToArray:options]);
    _options = options;
    // Calculate component width.
    _componentWidth = 0;
    UIFont *font = [[self class] labelFont];
    for (NSDictionary *option in options) {
        NSString *text = option[@"text"];
        NSDictionary *textAttrs = @{NSFontAttributeName: font};
        CGFloat width = [text sizeWithAttributes:textAttrs].width + 21.f;
        _componentWidth = MAX(_componentWidth, width);
    }
    if (changed) {
        [_picker reloadAllComponents];
    }
}

- (void)setValue:(id)value animated:(BOOL)animated {
    _value = value;
    NSInteger index = 0;
    for (; index < [_options count]; index++) {
        NSDictionary *dict = [_options objectAtIndex:index];
        if ([[dict objectForKey:@"value"] intValue] == [value intValue]) {
            break;
        }
    }
    if (index < [_options count]) {
        [_picker selectRow:index inComponent:0 animated:animated];
    }
}

- (NSDictionary *)optionWithValue:(id)value {
    NSInteger index = 0;
    for (; index < [_options count]; index++) {
        NSDictionary *dict = [_options objectAtIndex:index];
        if ([[dict objectForKey:@"value"] intValue] == [value intValue]) {
            return dict;
        }
    }
    return nil;
}

- (NSString *)textForValue:(id)value {
    return [[self optionWithValue:value] objectForKey:@"text"];
}

#pragma mark - UIPickerViewDelegate for `select' input

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_options count];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return _componentWidth;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDictionary *option = [_options objectAtIndex:row];
    return [option objectForKey:@"text"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSDictionary *option = [_options objectAtIndex:row];
    _text = [option objectForKey:@"text"];
    _value = @([[option objectForKey:@"value"] intValue]);
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
