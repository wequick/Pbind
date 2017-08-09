//
//  UINavigationItem+Pbind.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/18.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UINavigationItem+Pbind.h"
#import "PBAction.h"
#import "PBRowMapper.h"
#import "PBInline.h"
#import "PBValueParser.h"
#import "PBActionStore.h"
#import "PBPropertyUtils.h"

#pragma mark -
#pragma mark - _PBBarButtonItemSpec

@interface _PBBarButtonItemSpec : NSObject

@property (nonatomic, assign) UIBarButtonSystemItem type;
@property (nonatomic, assign) UIBarButtonItemStyle style;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSDictionary *action;
@property (nonatomic, strong) NSDictionary *customView;

@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) BOOL enabled;

@end

@implementation _PBBarButtonItemSpec

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.enabled = YES;
        [PBPropertyUtils setValuesForKeysWithDictionary:dictionary toObject:self failure:nil];
        if (dictionary[@"type"] == nil) {
            self.type = -1;
        }
    }
    return self;
}

@end

#pragma mark -
#pragma mark - _PBBarButtonItem

@interface _PBBarButtonItem : UIBarButtonItem

@property (nonatomic, strong) PBActionMapper *actionMapper;

@end

@implementation _PBBarButtonItem

+ (instancetype)itemWithDictionary:(NSDictionary *)dictionary {
    _PBBarButtonItemSpec *spec = [[_PBBarButtonItemSpec alloc] initWithDictionary:dictionary];
    if (spec.hidden) {
        return nil;
    }
    
    return [[self alloc] initWithSpec:spec];
}

- (instancetype)initWithSpec:(_PBBarButtonItemSpec *)spec {
    do {
        if (spec.type >= 0) {
            self = [super initWithBarButtonSystemItem:spec.type target:nil action:nil];
            break;
        }
        
        NSString *imageName = spec.image;
        UIImage *image = nil;
        if (imageName != nil) {
            image = PBImage(imageName);
        }
        if (image != nil) {
            self = [super initWithImage:image style:spec.style target:nil action:nil];
            break;
        }
        
        NSDictionary *customViewInfo = spec.customView;
        if (customViewInfo != nil) {
            PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:customViewInfo];
            UIView *customView = [mapper createView];
            self = [super initWithCustomView:customView];
            
            // Initilize constants and expressions for the view.
            // FIXME: the context was not ready now, maybe we should do it later.
            [mapper initPropertiesForTarget:customView];
            break;
        }
        
        self = [super initWithTitle:spec.title style:spec.style target:nil action:nil];
    } while (false);
    
    if (self == nil) {
        return nil;
    }
    
    if (spec.action != nil) {
        PBActionMapper *mapper = [PBActionMapper mapperWithDictionary:spec.action];
        [self setActionMapper:mapper];
        [self setTarget:self];
        [self setAction:@selector(handleAction:)];
    } else {
        [self setActionMapper:nil];
    }
    
    self.enabled = spec.enabled;
    return self;
}

- (void)handleAction:(_PBBarButtonItem *)item {
    // FIXME: Using the private API of `_view'
    UIView *context = [self valueForKey:@"view"];
    [[PBActionStore defaultStore] dispatchActionWithActionMapper:self.actionMapper context:context];
}

@end

#pragma mark -
#pragma mark - UINavigationItem+Pbind

@implementation UINavigationItem (Pbind)

- (void)setRight:(NSDictionary *)right {
    if (right == nil || right.count == 0) {
        self.rightBarButtonItem = nil;
        return;
    }
    
    self.rightBarButtonItem = [_PBBarButtonItem itemWithDictionary:right];
}

- (NSDictionary *)right {
    return nil;
}

- (void)setRights:(NSArray *)rights {
    if (rights == nil || rights.count == 0) {
        self.rightBarButtonItems = nil;
        return;
    }
    
    NSMutableArray *rightBarButtonItems = [NSMutableArray arrayWithCapacity:rights.count];
    for (NSDictionary *info in rights) {
        _PBBarButtonItem *item = [_PBBarButtonItem itemWithDictionary:info];
        if (item == nil) {
            continue;
        }
        [rightBarButtonItems addObject:item];
    }
    self.rightBarButtonItems = rightBarButtonItems;
}

- (void)setLeft:(NSDictionary *)left {
    if (left == nil || left.count == 0) {
        self.leftBarButtonItem = nil;
        return;
    }
    
    self.leftBarButtonItem = [_PBBarButtonItem itemWithDictionary:left];
}

- (NSDictionary *)left {
    return nil;
}

- (void)setLefts:(NSArray *)lefts {
    if (lefts == nil || lefts.count == 0) {
        self.leftBarButtonItems = nil;
        return;
    }
    
    NSMutableArray *leftBarButtonItems = [NSMutableArray arrayWithCapacity:lefts.count];
    for (NSDictionary *info in lefts) {
        _PBBarButtonItem *item = [_PBBarButtonItem itemWithDictionary:info];
        if (item == nil) {
            continue;
        }
        [leftBarButtonItems addObject:item];
    }
    self.leftBarButtonItems = leftBarButtonItems;
}

@end
