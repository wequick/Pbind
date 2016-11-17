//
//  UIButton+PBForm.m
//  Pbind
//
//  Created by galen on 15/4/10.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "UIButton+PBForm.h"
#import "PBForm.h"
#import "UIView+Pbind.h"

#define COVER_USE_BLUR (0)

NSString *const PBPopdownCoverWillShowNotification = @"PBPopdownCoverWillShow";
NSString *const PBPopdownCoverDidShowNotification = @"PBPopdownCoverDidShow";
NSString *const PBPopdownCoverWillHideNotification = @"PBPopdownCoverWillHide";
NSString *const PBPopdownCoverDidHideNotification = @"PBPopdownCoverDidHide";
NSString *const PBPopdownCoverViewKey = @"PBPopdownCoverView";

@implementation UIButton (PBForm)

NSString *const kPopdownViewKey = @"__popdownView";
NSString *const kPopdownViewFrameKey = @"__popdownViewFrame";
NSString *const kPopdownButtonFrameKey = @"__popdownButtonFrame";
NSString *const kPopdownCoverKey = @"__popdownCover";
NSString *const kPopdownTargetKey = @"__popdownTarget";

- (void)setName:(NSString *)value {
    [self setValue:value forAdditionKey:@"name"];
}

- (NSString *)name {
    return [self valueForAdditionKey:@"name"];
}

- (void)setAction:(NSString *)value {
    [self setValue:value forAdditionKey:@"action"];
}

- (NSString *)action {
    return [self valueForAdditionKey:@"action"];
}

- (void)setRequiredTips:(NSString *)value {
    [self setValue:value forAdditionKey:@"requiredTips"];
}

- (NSString *)requiredTips {
    return [self valueForAdditionKey:@"requiredTips"];
}

- (void)setActionProperties:(NSDictionary *)value {
    [self setValue:value forAdditionKey:@"actionProperties"];
}

- (NSDictionary *)actionProperties {
    return [self valueForAdditionKey:@"actionProperties"];
}

- (void)setPlaceholderLabel:(UILabel *)value {
    [self setValue:value forAdditionKey:@"placeholderLabel"];
}

- (UILabel *)placeholderLabel {
    return [self valueForAdditionKey:@"placeholderLabel"];
}

- (void)setRequired:(BOOL)required {
    [self setValue:(required ? @(required) : nil) forAdditionKey:@"required"];
}

- (BOOL)isRequired {
    return [[self valueForAdditionKey:@"required"] boolValue];
}

- (void)setTitle:(NSString *)title {
    [self setText:title];
}

- (void)setText:(NSString *)text {
    [self setTitle:text forState:UIControlStateNormal];
    if (text.length == 0) {
        self.placeholderLabel.hidden = NO;
    } else {
        self.placeholderLabel.hidden = YES;
    }
}

- (NSString *)text {
    return [self titleForState:UIControlStateNormal];
}

- (void)setType:(NSString *)type {
    [self addTarget:self action:@selector(onTypedInputClick:) forControlEvents:UIControlEventTouchUpInside];
    [self setValue:type forAdditionKey:@"type"];
}

- (NSString *)type {
    return [self valueForAdditionKey:@"type"];
}

- (id)value {
    if ([[self type] isEqualToString:@"radio"] && !self.selected) {
        return nil;
    }
    return [self valueForAdditionKey:@"value"];
}

- (void)setValue:(id)value {
    [self setValue:value forAdditionKey:@"value"];
    if (value == nil) {
        [self setTitle:nil];
    }
}

- (void)reset {
}

#pragma mark -
#pragma mark - Placeholder

- (void)initPlaceholder {
    if (self.placeholderLabel == nil) {
        CGRect labelRect = [self.titleLabel convertRect:self.titleLabel.frame toView:self];
        self.placeholderLabel = [[UILabel alloc] initWithFrame:labelRect];
        [self.placeholderLabel setBackgroundColor:[UIColor clearColor]];
        [self.placeholderLabel setFont:self.titleLabel.font];
        [self.placeholderLabel setTextColor:[UIColor lightGrayColor]];
        [self.placeholderLabel setNumberOfLines:1];
        [self.placeholderLabel setTextAlignment:self.titleLabel.textAlignment];
        [self.placeholderLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:self.placeholderLabel];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    }
}

- (NSString *)placeholder {
    return [self valueForAdditionKey:@"placeholder"];
}

- (void)setPlaceholder:(NSString *)placeholder {
    [self initPlaceholder];
    [self.placeholderLabel setText:placeholder];
    [self.placeholderLabel sizeToFit];
    [self setValue:placeholder forAdditionKey:@"placeholder"];
}

- (UIColor *)placeholderColor {
    return [self valueForAdditionKey:@"placeholderColor"];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    [self initPlaceholder];
    [self.placeholderLabel setTextColor:placeholderColor];
    [self setValue:placeholderColor forAdditionKey:@"placeholderColor"];
}

#pragma mark -
#pragma mark - Click event

- (void)setHref:(NSString *)href {
    [self addTarget:self action:@selector(onHrefClick:) forControlEvents:UIControlEventTouchUpInside];
    [self setValue:href forAdditionKey:@"href"];
}

- (NSString *)href {
    return [self valueForAdditionKey:@"href"];
}

- (void)onHrefClick:(id)sender {
    PBViewClickHref(sender, [sender href]);
}

- (void)onTypedInputClick:(id)sender {
    NSString *type = self.type;
    if ([type isEqualToString:@"present"]
        || [type isEqualToString:@"push"]
        || [type isEqualToString:@"popdown"]) {
        [self showControllerByType:type];
    } else if ([type isEqualToString:@"radio"]) {
        [self setSelected:!self.selected];
    }
}

- (void)showControllerByType:(NSString *)type {
    if (self.action == nil) {
        return;
    }
    
    Class clazz = NSClassFromString(self.action);
    if (clazz == nil) {
        return;
    }
    id supercontroller = [self supercontroller];
    if (supercontroller == nil) {
        return;
    }
    
    id controller = nil;
    @try { // FIXME: [clazz instancesRespondToSelector:@selector(sharedInput)] always return NO?
        controller = [clazz sharedInput];
    } @catch (NSException *e) {
        controller = [[clazz alloc] init];
    }
    if (self.actionProperties != nil) {
        [controller setValuesForKeysWithDictionary:self.actionProperties];
    }
    
    if ([controller conformsToProtocol:@protocol(PBTextInput)]) {
        [(id<PBTextInput>)controller setInputDelegate:self];
    }
    
    if ([type isEqualToString:@"present"]) {
        [supercontroller presentViewController:controller animated:YES completion:nil];
    } else if ([type isEqualToString:@"push"]) {
        [[supercontroller navigationController] pushViewController:controller animated:YES];
    } else if ([type isEqualToString:@"popdown"]) {
        UIWindow *window = self.window;
        UIView *popdownView = [window valueForAdditionKey:kPopdownViewKey];
        UIView *view = [controller view];
        if ([popdownView isEqual:view]) {
            [self hidePopdownView:popdownView fromWindow:window];
        } else {
            if (popdownView != nil) {
                [self switchPopdownView:popdownView toView:view fromWindow:window];
            } else {
                [self showPopdownView:view toWindow:window showsCover:YES];
            }
        }
    }
}

- (void)textInput:(id<PBTextInput>)textInput didInputText:(NSString *)text value:(id)value {
    [self setTitle:text];
    [self setValue:value];
    id form = [self superview];
    while (form) {
        if ([form isKindOfClass:[PBForm class]]) {
            break;
        }
        form = [form superview];
    }
    if ([[form formDelegate] respondsToSelector:@selector(form:didEndEditingOnInput:)]) {
        [[form formDelegate] form:form didEndEditingOnInput:self];
    }
    if ([textInput isKindOfClass:[UIViewController class]]) {
        // Dismiss controller
        UIViewController *controller = (id)textInput;
        if ([self.type isEqualToString:@"present"]) {
            [controller dismissViewControllerAnimated:YES completion:nil];
        } else if ([self.type isEqualToString:@"push"]) {
            [controller.navigationController popViewControllerAnimated:YES];
        } else if ([self.type isEqualToString:@"popdown"]) {
            [self hidePopdownView:controller.view fromWindow:self.window];
        }
    }
}

#pragma mark - Popdown

- (void)hidePopdownView:(UIView *)view fromWindow:(UIWindow *)window {
    [self switchPopdownView:view toView:nil fromWindow:window];
}

- (void)switchPopdownView:(UIView *)view toView:(UIView *)newView fromWindow:(UIWindow *)window {
    CGRect fromRect = [self popdownButtonRect:view];
    UIButton *fromTarget = [view valueForAdditionKey:kPopdownTargetKey];
    [view setValue:nil forAdditionKey:kPopdownTargetKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:PBPopdownCoverWillHideNotification object:self userInfo:@{PBPopdownCoverViewKey:view}];
    if (newView != nil) {
        [UIView animateWithDuration:.15f animations:^{
            [view setFrame:fromRect];
            [fromTarget setSelected:NO];
//            [view setAlpha:0];
        } completion:^(BOOL finished) {
            [window setValue:nil forAdditionKey:kPopdownViewKey];
            [view removeFromSuperview];
            [[NSNotificationCenter defaultCenter] postNotificationName:PBPopdownCoverDidHideNotification object:self userInfo:@{PBPopdownCoverViewKey:view}];
            [self showPopdownView:newView toWindow:window showsCover:NO];
        }];
    } else {
        UIView *cover = [window valueForAdditionKey:kPopdownCoverKey];
        [UIView animateWithDuration:.3f animations:^{
            [view setFrame:fromRect];
            [fromTarget setSelected:NO];
//            [view setAlpha:0];
            [cover setAlpha:0];
        } completion:^(BOOL finished) {
            [window setValue:nil forAdditionKey:kPopdownViewKey];
            [view removeFromSuperview];
            [[NSNotificationCenter defaultCenter] postNotificationName:PBPopdownCoverDidHideNotification object:self userInfo:@{PBPopdownCoverViewKey:view}];
        }];
    }
}

- (CGRect)popdownViewRect:(UIView *)view {
    CGRect toRect;
    NSValue *viewRectValue = [view valueForAdditionKey:kPopdownViewFrameKey];
    if (viewRectValue == nil) {
        toRect = [self convertRect:self.bounds toView:self.window];
        CGSize winSize = [UIScreen mainScreen].bounds.size;
        toRect.origin.x = 0;
        toRect.origin.y += toRect.size.height;
        toRect.size.width = winSize.width;
        toRect.size.height = MIN(view.frame.size.height, winSize.height - toRect.origin.y);
        [view setValue:[NSValue valueWithCGRect:toRect] forAdditionKey:kPopdownViewFrameKey];
    } else {
        toRect = [viewRectValue CGRectValue];
    }
    return toRect;
}

- (CGRect)popdownButtonRect:(UIView *)view {
    CGRect toRect;
    NSValue *viewRectValue = [view valueForAdditionKey:kPopdownButtonFrameKey];
    if (viewRectValue == nil) {
        toRect = [self convertRect:self.bounds toView:self.window];
        toRect.origin.y += toRect.size.height;
        toRect.size.height = 0;
        //
        toRect.origin.x = 0;
        toRect.size.width = [UIScreen mainScreen].bounds.size.width;
        //
        [view setValue:[NSValue valueWithCGRect:toRect] forAdditionKey:kPopdownButtonFrameKey];
    } else {
        toRect = [viewRectValue CGRectValue];
    }
    return toRect;
}

- (void)popdownCoverClick:(id)sender {
    UIView *popdownView = [self.window valueForAdditionKey:kPopdownViewKey];
    [self hidePopdownView:popdownView fromWindow:self.window];
}

- (void)showPopdownView:(UIView *)view toWindow:(UIWindow *)window showsCover:(BOOL)showsCover {
    [view setValue:self forAdditionKey:kPopdownTargetKey];
    CGRect toRect = [self popdownViewRect:view];
    UIButton *cover = nil;
    if (showsCover) {
        cover = [window valueForAdditionKey:kPopdownCoverKey];
        CGRect coverRect = CGRectMake(toRect.origin.x, toRect.origin.y, toRect.size.width, [UIScreen mainScreen].bounds.size.height - toRect.origin.y);
        if (cover == nil) {
            cover = [[UIButton alloc] init];
            [cover addTarget:self action:@selector(popdownCoverClick:) forControlEvents:UIControlEventTouchUpInside];
#if COVER_USE_BLUR
            // Blur effect for iOS 8.0+
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                [blurView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
                [blurView setFrame:CGRectMake(0, 0, coverRect.size.width, coverRect.size.height)];
                [cover insertSubview:blurView atIndex:0];
                [cover setBackgroundColor:[UIColor clearColor]];
            } else
#endif
            {
                [cover setBackgroundColor:[UIColor colorWithWhite:0 alpha:.5]];
            }
            [window setValue:cover forAdditionKey:kPopdownCoverKey];
            [window addSubview:cover];
        }
        [cover setFrame:coverRect];
        [cover setAlpha:0];
    }
    
#if COVER_USE_BLUR
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [view setBackgroundColor:[UIColor clearColor]];
        [view setValue:@(YES) forAdditionKey:@"__blur"];
        for (UIView *subview in [view subviews]) {
            [subview setBackgroundColor:[UIColor clearColor]];
            [subview setValue:@(YES) forAdditionKey:@"__blur"];
        }
    }
#endif
    [view setFrame:toRect];
    [window addSubview:view];
    [window setValue:view forAdditionKey:kPopdownViewKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PBPopdownCoverWillShowNotification object:self userInfo:@{PBPopdownCoverViewKey:view}];
    CGRect fromRect = [self popdownButtonRect:view];
    [view setFrame:fromRect];
//    [view setAlpha:0];
//    NSLog(@"from %@ to %@", [NSValue valueWithCGRect:fromRect], [NSValue valueWithCGRect:toRect]);
    [UIView animateWithDuration:.3f animations:^{
        [view setFrame:toRect];
        [self setSelected:YES];
//        [view setAlpha:1];
        if (showsCover) {
            [cover setAlpha:1];
        }
    } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PBPopdownCoverDidShowNotification object:self userInfo:@{PBPopdownCoverViewKey:view}];
    }];
}

@end
