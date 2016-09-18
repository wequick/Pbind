//
//  UIView+PBLayout.m
//  Pbind
//
//  Created by galen on 15/3/8.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "UIView+PBLayout.h"
#import "PBLayoutParser.h"
#import "PBMutableExpression.h"
#import "PBValueParser.h"
#import "PBCompat.h"
#import "UIView+Pbind.h"

NSString *const PBViewWillRemoveFromSuperviewNotification = @"PBViewWillRemoveFromSuperview";
NSString *const PBViewDidChangeSizeNotification = @"PBViewDidChangeSize";

static NSInteger const kMaxTagCount = 32;

@implementation UIView (PBLayout)

DEF_UNDEFINED_PROPERTY(NSDictionary *, PBConstantProperties)
DEF_UNDEFINED_PROPERTY(NSDictionary *, PBDynamicProperties)
DEF_UNDEFINED_PROPERTY(NSNumber *, PBAutoheightSubviewMaxDepth)
DEF_UNDEFINED_PROPERTY(NSMutableDictionary *, PBAutoheightSubviews)
DEF_UNDEFINED_PROPERTY(NSArray *, PBBindingKeyPaths)

DEF_UNDEFINED_PROPERTY2(NSArray *, visualFormats, setVisualFormats)

+ (UIView *)viewWithLayout:(NSString *)layout bundle:(NSBundle *)bundle
{
    return [[PBLayoutParser sharedParser] viewFromLayout:layout bundle:bundle];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview == nil) {
        // Notify for observers to unobserved
        [[NSNotificationCenter defaultCenter] postNotificationName:PBViewWillRemoveFromSuperviewNotification object:self];
    }
}

- (void)didMoveToWindow
{
    if (self.superview != nil) {
        // Add visual formats
        if (self.visualFormats != nil) {
            [self setTranslatesAutoresizingMaskIntoConstraints:NO];
            NSMutableDictionary *views = [[NSMutableDictionary alloc] init];
            views[@"self"] = self;
            for (int tag = 1; tag <= kMaxTagCount; tag++) {
                UIView *tagView = [self.superview viewWithTag:tag];
                if (tagView == nil) {
                    break;
                }
                NSString *tagString = [NSString stringWithFormat:@"t%i", tag];
                views[tagString] = tagView;
            }
            NSArray *parentViews = [self.superview subviews];
            NSInteger subviewIndex = [parentViews indexOfObject:self];
            if (subviewIndex > 0) {
                views[@"prev"] = [parentViews objectAtIndex:subviewIndex - 1];
            }
            if (subviewIndex + 1 < [[self.superview subviews] count]) {
                views[@"next"] = [parentViews objectAtIndex:subviewIndex + 1];
            }
            for (NSString *format in self.visualFormats) {
                [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:views]];
            }
        }
    }
}

- (void)pb_initData
{
    NSDictionary *properties = [self PBConstantProperties];
    for (NSString *key in properties) {
        id value = [properties objectForKey:key];
        value = [PBValueParser valueWithString:value];
        [self setValue:value forKey:key];
    }
    // Recursive
    if ([self respondsToSelector:@selector(reloadData)]) {
        
    } else {
        for (UIView *subview in [self subviews]) {
            [subview pb_initData];
        }
    }
    
    if (self.data == nil && (self.client != nil || self.clients != nil)) {
        if (self.window == nil) {
            // Cause the plist value may be specify with expression `@xx', which requires the view's super controller. If window is nil, it means the super controller is also not yet ready.
            return;
        }
        
        [self pb_mapData:nil];
    } else if ([self respondsToSelector:@selector(reloadData)]) {
        [(id)self reloadData];
    }
}

- (void)pb_mapData:(id)data
{
    NSDictionary *properties = [self PBDynamicProperties];
    for (NSString *key in properties) {
        if ([self mappableForKeyPath:key]) {
            PBExpression *exp = [properties objectForKey:key];
            [exp mapData:data toTarget:self forKeyPath:key inContext:self];
        }
    }
    // Recursive
    if ([self respondsToSelector:@selector(reloadData)]) {
        
    } else {
        for (UIView *subview in [self subviews]) {
            [subview pb_mapData:data];
        }
    }
    
    if (self.data == nil && (self.client != nil || self.clients != nil)) {
        [self pb_pullData];
    } else {
        if ([self respondsToSelector:@selector(reloadData)]) {
            [(id)self reloadData];
        }
    }
}

- (void)pb_mapData:(id)data forKey:(NSString *)key
{
    PBExpression *exp = [[self PBDynamicProperties] objectForKey:key];
    [exp mapData:data toTarget:self forKeyPath:key inContext:self];
    // Recursive
    for (UIView *subview in [self subviews]) {
        [subview pb_mapData:data forKey:key];
    }
}

- (void)pb_initConstraintForAutoheight
{
    NSInteger maxDepth = [[self PBAutoheightSubviewMaxDepth] integerValue];
    if (maxDepth == 0) {
        return;
    }
    // Find uppest view of `autoHeight'
    NSMutableDictionary *uppestViews = [[NSMutableDictionary alloc] initWithCapacity:maxDepth];
    for (NSInteger depth = maxDepth; depth >= 0; depth--) {
        NSMutableArray *resizingViews = [[self PBAutoheightSubviews] objectForKey:@(depth)];
        if (resizingViews != nil) {
            UIView *view = [resizingViews firstObject];
            UIView *deepView = [uppestViews objectForKey:@(depth + 1)];
            if (deepView != nil) {
                if (deepView.superview.frame.origin.y < view.frame.origin.y) {
                    [uppestViews setObject:deepView.superview forKey:@(depth)];
                } else {
                    [uppestViews setObject:view forKey:@(depth)];
                }
            } else {
                [uppestViews setObject:view forKey:@(depth)];
            }
        } else {
            UIView *view = [uppestViews objectForKey:@(depth + 1)];
            if (view != nil && view.superview != nil) {
                [uppestViews setObject:view.superview forKey:@(depth)];
            }
        }
    }
    for (NSInteger depth = maxDepth; depth >= 0; depth--) {
        UIView *upView = [uppestViews objectForKey:@(depth)];
        if (upView == nil) {
            continue;
        }
        UIView *deeperUpView = [uppestViews objectForKey:@(depth+1)];
        if (deeperUpView != nil) {
//            [self pb_addConstraintWithView:[deeperUpView superview]toView:upView];
        }
        // Add constraints for lower views
        NSArray *lowerViews = [self pb_lowerSubviewsForView:upView];
        if ([lowerViews count] > 1) {
            [self pb_addConstraintWithView:[lowerViews firstObject] toView:upView];
            for (NSInteger i = 0; i < lowerViews.count - 1; i++) {
                [self pb_addConstraintWithView:[lowerViews objectAtIndex:i+1] toView:[lowerViews objectAtIndex:i]];
            }
        }
    }
}

- (NSArray *)pb_lowerSubviewsForView:(UIView *)view
{
    NSMutableArray *views = [[NSMutableArray alloc] init];
    for (UIView *lowerView in view.superview.subviews) {
        CGFloat d = lowerView.frame.origin.y - view.frame.origin.y;
        if (d > 0) {
            [views addObject:lowerView];
        }
    }
    [views sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CGFloat d = [obj1 frame].origin.y - [obj2 frame].origin.y;
        if (d < 0) {
            return NSOrderedAscending;
        } else if (d > 0) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    return views;
}

- (void)pb_addConstraintWithView:(UIView *)fromView toView:(UIView *)toView
{
    UIView *superview = [toView superview];
    NSLog(@"constraint from %i(%.2f) to %i(%.2f)", (int)fromView.tag, fromView.frame.origin.y, (int)toView.tag, toView.frame.origin.y);
    // Constraint for `top'
    fromView.translatesAutoresizingMaskIntoConstraints = NO;
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:fromView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:toView attribute:NSLayoutAttributeBottom multiplier:1 constant:fromView.frame.origin.y - toView.frame.origin.y - toView.frame.size.height]];
    if ([fromView isKindOfClass:[UILabel class]]) {
        UILabel *label = (id)fromView;
        label.preferredMaxLayoutWidth = [label alignmentRectForFrame:label.frame].size.width;
    }
    // Keep original `left'
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:fromView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1 constant:fromView.frame.origin.x]];
    if ([[fromView valueForKey:@"autoHeight"] boolValue]) {
        return;
    }
//    NSLog(@"keep size: %@", fromView);
    // Keep original `width' and `height'
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:fromView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:fromView.frame.size.width]];
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:fromView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:fromView.frame.size.height]];
}

@end
