//
//  PBMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PBMapperProperties.h"

@class PBExpression;

/**
 The PBMapper stores all the Plist Key-Value properties and parse them with special format.
 
 @discussion Following reserved keys are used to lazy init:
 
 * properties -> properties for the view
 * tagproperties -> properties for the subview with tag
 * subproperties -> properties for the subview at index
 
 The other keyed values are using to set the properties of the mapper self.
 
 */
@interface PBMapper : NSObject
{
    PBMapperProperties *_properties; // for self
    PBMapperProperties *_viewProperties; // for view
    PBMapperProperties *_navProperties;// for view super controller's navigationItem
    NSMutableArray *_subviewProperties; // for view's subview
    NSMutableDictionary *_aliasProperties; // for view's aliased subview
    NSMutableDictionary *_outletProperties;// for view's outlet subview
}

+ (instancetype)mapperWithContentsOfURL:(NSURL *)url;
+ (instancetype)mapperWithDictionary:(NSDictionary *)dictionary owner:(UIView *)owner;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary;

- (void)initDataForView:(UIView *)view;
- (void)mapData:(id)data forView:(UIView *)view;

- (void)updateWithData:(id)data andView:(UIView *)view;
- (void)updateValueForKey:(NSString *)key withData:(id)data andView:(UIView *)view;

- (void)unbind;

- (void)setExpression:(PBExpression *)expression forKey:(NSString *)key;

@end
