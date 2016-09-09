//
//  PBMapperProperties.h
//  Pbind
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PBMapperProperties : NSObject

+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary;

- (void)initPropertiesForOwner:(id)owner; // UIView

- (void)initDataForOwner:(id)owner;
- (void)mapData:(id)data forOwner:(id)owner withView:(id)view;

@end
