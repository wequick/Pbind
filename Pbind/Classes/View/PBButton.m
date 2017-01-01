//
//  PBButton.m
//  Pods
//
//  Created by Galen Lin on 2016/12/21.
//
//

#import "PBButton.h"
#import "UIView+Pbind.h"
#import "PBActionStore.h"
#import "Pbind+API.h"

@implementation PBButton
{
    UIColor *_backgroundColor;
    PBActionMapper *_actionMapper;
}

#pragma mark - PBInput

@synthesize type, name, value, required, requiredTips;

- (void)reset {
    
}

#pragma mark -

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    [super setBackgroundColor:backgroundColor];
}

- (void)setAction:(NSDictionary *)action {
    _actionMapper = [PBActionMapper mapperWithDictionary:action owner:nil];
    [self addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)handleAction:(id)sender {
    [[PBActionStore defaultStore] dispatchActionWithActionMapper:_actionMapper context:self];
}

#pragma mark - State changing

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        [super setBackgroundColor:[_backgroundColor colorWithAlphaComponent:.8]];
    } else {
        [super setBackgroundColor:_backgroundColor];
    }
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    if (enabled) {
        [super setBackgroundColor:_backgroundColor];
    } else {
        [super setBackgroundColor:[_backgroundColor colorWithAlphaComponent:.2]];
    }
}

#pragma mark - PBInput

- (void)setText:(NSString *)text {
    [self setTitle:text forState:UIControlStateNormal];
}

- (NSString *)text {
    return [self titleForState:UIControlStateNormal];
}

#pragma mark - Configurable state

- (void)setTitle:(NSString *)title {
    [self setTitle:title forState:UIControlStateNormal];
}

- (NSString *)title {
    return [self titleForState:UIControlStateNormal];
}

- (void)setDisabledTitle:(NSString *)disabledTitle {
    [self setTitle:disabledTitle forState:UIControlStateDisabled];
}

- (NSString *)disabledTitle {
    return [self titleForState:UIControlStateDisabled];
}

- (void)setHighlightedTitle:(NSString *)highlightedTitle {
    [self setTitle:highlightedTitle forState:UIControlStateHighlighted];
}

- (NSString *)highlightedTitle {
    return [self titleForState:UIControlStateHighlighted];
}

- (void)setSelectedTitle:(NSString *)selectedTitle {
    [self setTitle:selectedTitle forState:UIControlStateSelected];
}

- (NSString *)selectedTitle {
    return [self titleForState:UIControlStateSelected];
}

- (void)setImage:(NSString *)image {
    _image = image;
    [self setImage:PBImage(image) forState:UIControlStateNormal];
}

- (void)setDisabledImage:(NSString *)disabledImage {
    _disabledImage = disabledImage;
    [self setImage:PBImage(disabledImage) forState:UIControlStateDisabled];
}

- (void)setHighlightedImage:(NSString *)highlightedImage {
    [self setImage:PBImage(highlightedImage) forState:UIControlStateHighlighted];
}

- (void)setSelectedImage:(NSString *)selectedImage {
    _selectedImage = selectedImage;
    [self setImage:PBImage(selectedImage) forState:UIControlStateSelected];
}

@end
