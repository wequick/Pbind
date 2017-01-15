//
//  PBLayoutMapper.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/11/1.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBLayoutMapper.h"
#import "PBRowMapper.h"
#import "UIView+Pbind.h"
#import "Pbind+API.h"
#import "PBValueParser.h"
#import "PBLayoutConstraint.h"

#pragma mark -
#pragma mark - PBLayoutMapper

@implementation PBLayoutMapper

- (void)renderToView:(UIView *)view {
    NSInteger viewCount = self.views.count;
    if (viewCount == 0) {
        return;
    }
    
    if ([view isKindOfClass:[UITableViewCell class]] || [view isKindOfClass:[UICollectionViewCell class]]) {
        view = [(id)view contentView];
    }
    
    // Check if any view be removed.
    NSArray *aliases = [self.views allKeys];
    NSMutableArray *addedAliases = [NSMutableArray arrayWithCapacity:aliases.count];
    [self collectSubviewAliases:addedAliases ofView:view];
    NSArray *removedAliases = [addedAliases filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", aliases]];
    if (removedAliases.count > 0) {
        for (NSString *alias in removedAliases) {
            UIView *subview = [view viewWithAlias:alias];
            [subview removeFromSuperview];
        }
    }
    
    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithCapacity:viewCount];
    [views setObject:view forKey:@"super"];
    NSMutableArray *originalViews = [NSMutableArray arrayWithCapacity:viewCount];
    BOOL needsReset = NO;
    
    for (NSString *alias in self.views) {
        NSDictionary *properties = [self.views objectForKey:alias];
        PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:properties owner:nil];
        UIView *subview = [view viewWithAlias:alias];
        
        // Support for instant updating.
        BOOL needsCreate = NO;
        if (subview == nil) {
            needsCreate = YES;
        } else if (subview.class != mapper.viewClass) {
            needsCreate = YES;
            [subview removeFromSuperview];
        }
        
        if (needsCreate) {
            subview = [[mapper.viewClass alloc] init];
            subview.translatesAutoresizingMaskIntoConstraints = NO;
            subview.alias = alias;
            [view addSubview:subview];
            
            needsReset = YES;
        } else {
            [originalViews addObject:subview];
        }
        
        [mapper initDataForView:subview];
        [views setObject:subview forKey:alias];
    }
    
    // Remove the related constraints if needed.
    if (originalViews.count > 0) {
        for (UIView *subview in originalViews) {
            [PBLayoutConstraint removeAllConstraintsOfSubview:subview fromParentView:view];
        }
    }
    
    // Calculate metrics.
    NSDictionary *metrics = nil;
    if (self.metrics != nil) {
        NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithCapacity:self.metrics.count];
        for (NSString *key in self.metrics) {
            [temp setObject:@(PBValue([self.metrics[key] floatValue])) forKey:key];
        }
        metrics = temp;
    }
    
    // VFL (Official Visual Format Language)
    for (NSString *format in self.formats) {
        @try {
            NSArray *constraints = [PBLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:views];
            [view addConstraints:constraints];
        } @catch (NSException *exception) {
            NSLog(@"Pbind: %@", exception);
            continue;
        }
    }
    
    // PVFL (Pbind Visual Format Language)
    [PBLayoutConstraint addConstraintsWithPbindFormats:self.constraints metrics:metrics views:views forParentView:view];
}

#pragma mark - Helper

- (void)collectSubviewAliases:(NSMutableArray *)aliases ofView:(UIView *)view {
    NSString *alias = view.alias;
    if (alias != nil) {
        [aliases addObject:alias];
    }
    
    // Recursively
    NSArray *subviews = view.subviews;
    for (UIView *subview in subviews) {
        [self collectSubviewAliases:aliases ofView:subview];
    }
}

@end
