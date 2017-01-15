//
//  PBFormAccessory.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBFormAccessory.h"

@interface PBFormAccessory ()
{
    UIToolbar           *_toolbar;
    UIBarButtonItem     *_pbevItem;
    UIBarButtonItem     *_nextItem;
    NSArray             *_defaultItems;
    NSInteger            _doneButtonIndex;
}

@end

@implementation PBFormAccessory

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        [self initAccessoryView];
    }
    return self;
}

- (void)initAccessoryView
{
    CGRect frame = [UIScreen mainScreen].bounds;
    frame.size.height = 44;
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:frame];
    UIBarButtonItem *prevItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:105 target:self action:@selector(previousItemClick:)];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [spaceItem setWidth:24];
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:106 target:self action:@selector(nextItemClick:)];
    UIBarButtonItem *flexiableItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneItemClick:)];
    [toolbar setItems:@[prevItem, spaceItem, nextItem, flexiableItem, doneItem]];
    [self addSubview:toolbar];
    [self setFrame:frame];
    // Autolayout
    [toolbar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
    // Save navigation control
    _toolbar = toolbar;
    _pbevItem = prevItem;
    _nextItem = nextItem;
    _defaultItems = [toolbar items];
    _doneButtonIndex = [[toolbar items] count] - 1;
    _toggledIndex = -1;
}

- (void)didMoveToWindow {
    if ([self respondsToSelector:@selector(tintColor)]) {
        [self setTintColor:[[[UIApplication sharedApplication] delegate] window].tintColor];
    }
}

- (void)dealloc
{
    _toolbar = nil;
    _pbevItem = nil;
    _nextItem = nil;
    _defaultItems = nil;
}

#pragma mark -
#pragma mark - 按钮

- (void)setPreviousEnabled:(BOOL)enabled
{
    [_pbevItem setEnabled:enabled];
}

- (void)setNextEnabled:(BOOL)enabled
{
    [_nextItem setEnabled:enabled];
}

- (void)reloadData {
    BOOL hasPrev = _toggledIndex > 0;
    BOOL hasNext = _toggledIndex + 1 < [self.dataSource responderCountForAccessory:self];
    [self setPreviousEnabled:hasPrev];
    [self setNextEnabled:hasNext];
    
    // Customize right items
    NSMutableArray *items = [NSMutableArray arrayWithArray:_defaultItems];
    if ([self.dataSource respondsToSelector:@selector(accessory:barButtonItemsForResponderAtIndex:)]) {
        NSArray *customItems = [self.dataSource accessory:self barButtonItemsForResponderAtIndex:_toggledIndex];
        if ([customItems count] > 0) {
            NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
            for (NSInteger index = _doneButtonIndex; index < _doneButtonIndex + [customItems count]; index++) {
                [set addIndex:index];
            }
            [items insertObjects:customItems atIndexes:set];
        }
    }
    [_toolbar setItems:items];
}

- (void)previousItemClick:(id)sender
{
    [self goPrev];
}

- (void)nextItemClick:(id)sender
{
    [self goNext];
}

- (void)doneItemClick:(id)sender
{
    [self done];
}

- (void)segmentSwitched:(UISegmentedControl *)segment
{
    if (segment.selectedSegmentIndex == 0) {
        [self goPrev];
    } else {
        [self goNext];
    }
}

- (void)goPrev
{
    _toggledIndex--;
    [[self.dataSource accessory:self responderForToggleAtIndex:_toggledIndex] becomeFirstResponder];
}

- (void)goNext
{
    _toggledIndex++;
    [[self.dataSource accessory:self responderForToggleAtIndex:_toggledIndex] becomeFirstResponder];
}

- (void)done
{
    if ([self.delegate respondsToSelector:@selector(accessoryShouldReturn:)]) {
        BOOL shouldReturn = [self.delegate accessoryShouldReturn:self];
        if (!shouldReturn) {
            return;
        }
    }
    
    [[self.dataSource accessory:self responderForToggleAtIndex:_toggledIndex] resignFirstResponder];
}

@end
