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
#import "PBInline.h"
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
    
    view.pb_layoutName = self.plist;
    view.pb_layoutMapper = self;
    
    // Check if any view be removed.
    NSArray *aliases = [self.views allKeys];
    NSArray *renderedAliases = self.renderedAliases;
    NSArray *removedAliases = [renderedAliases filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", aliases]];
    if (removedAliases.count > 0) {
        for (NSString *alias in removedAliases) {
            UIView *subview = [view viewWithAlias:alias];
            [subview removeFromSuperview];
        }
    }
    self.renderedAliases = aliases;
    
    NSMutableDictionary<NSString *, UIView *> *views = [NSMutableDictionary dictionaryWithCapacity:viewCount];
    [views setObject:view forKey:@"super"];
    NSMutableArray<UIView *> *originalViews = [NSMutableArray arrayWithCapacity:viewCount];
    NSMutableArray<NSString *> *nestedViewParents = [NSMutableArray arrayWithCapacity:viewCount];
    NSMutableArray<UIView *> *nestedViews = [NSMutableArray arrayWithCapacity:viewCount];
    BOOL needsReset = NO;
    
    // Sort the views by order
    NSMutableArray *orderedMappers = [[NSMutableArray alloc] initWithCapacity:viewCount];
    for (NSString *alias in self.views) {
        NSDictionary *properties = [self.views objectForKey:alias];
        PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:properties];
        mapper.alias = alias;
        [orderedMappers addObject:mapper];
    }
    [orderedMappers sortUsingComparator:^NSComparisonResult(PBRowMapper *obj1, PBRowMapper *obj2) {
        NSInteger diff = obj2.order - obj1.order;
        return diff == 0 ? NSOrderedSame : (diff > 0 ? NSOrderedAscending : NSOrderedDescending);
    }];
    
    for (PBRowMapper *mapper in orderedMappers) {
        NSString *alias = mapper.alias;
        UIView *subview = [view viewWithAlias:alias];
        
        // Support for instant updating.
        BOOL needsCreate = NO;
        if (subview == nil) {
            needsCreate = YES;
        } else {
            if (subview.class != mapper.viewClass) {
                // view class changed
                needsCreate = YES;
            } else {
                // view parent changed
                UIView *parentView = [subview superview];
                if (mapper.parent == nil) {
                    if (parentView != view) {
                        if ([[[parentView class] description] isEqualToString:@"_PBMergedWrapperView"]) {
                            // do nothing if has been merged
                        } else {
                            needsCreate = YES;
                        }
                    }
                } else {
                    needsCreate = (parentView == view) || ![mapper.parent isEqualToString:parentView.alias];
                }
            }
            
            if (needsCreate) {
                [subview removeFromSuperview];
            }
        }
        
        if (needsCreate) {
            subview = [[mapper.viewClass alloc] init];
            subview.translatesAutoresizingMaskIntoConstraints = NO;
            subview.alias = alias;
            if (mapper.parent != nil) {
                [nestedViews addObject:subview];
                [nestedViewParents addObject:mapper.parent];
            } else {
                [view addSubview:subview];
            }
            
            needsReset = YES;
        } else {
            [originalViews addObject:subview];
        }
        
        [mapper initDataForView:subview];
        [mapper mapData:nil forView:subview];
        [views setObject:subview forKey:alias];
    }
    
    if (nestedViews.count != 0) {
        for (NSInteger index = 0; index < nestedViews.count; index++) {
            UIView *subview = nestedViews[index];
            NSString *parent = nestedViewParents[index];
            UIView *parentView = [view viewWithAlias:parent];
            [parentView addSubview:subview];
        }
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
            [temp setObject:@(PBPixelFromString(self.metrics[key])) forKey:key];
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

- (void)reload {
    [self unbind];
    [self setPropertiesWithDictionary:PBPlist(self.plist)];
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
