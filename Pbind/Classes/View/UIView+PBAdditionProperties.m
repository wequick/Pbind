//
//  UIView+PBAdditionProperties.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/10/26.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBDictionary.h"
#import <objc/runtime.h>

@implementation UIView (PBAdditionProperties)

#pragma mark - Addition properties

static const NSString *kAdditionPropertiesKey;

- (void)setAdditionProperties:(PBDictionary *)properties {
    objc_setAssociatedObject(self, &kAdditionPropertiesKey, properties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (PBDictionary *)additionProperties {
    return objc_getAssociatedObject(self, &kAdditionPropertiesKey);
}

- (void)setValue:(id)value forAdditionKey:(NSString *)key
{
    PBDictionary *properties = [self additionProperties];
    if (value == nil) {
        if (properties != nil) {
            [properties removeObjectForKey:key];
        }
    } else {
        if (properties == nil) {
            properties = [[PBDictionary alloc] init];
            properties.owner = self;
            [self setAdditionProperties:properties];
        }
        [properties setObject:value forKey:key];
    }
}

- (id)valueForAdditionKey:(NSString *)key
{
    PBDictionary *properties = [self additionProperties];
    if (properties == nil) {
        return nil;
    }
    return [properties objectForKey:key];
}

@end
