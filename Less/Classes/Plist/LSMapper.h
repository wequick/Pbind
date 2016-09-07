//
//  LSMapper.h
//  Less
//
//  Created by galen on 15/2/15.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LSMapperProperties.h"

@interface LSMapper : NSObject
{
    LSMapperProperties *_lsoperties; // for self
    LSMapperProperties *_viewProperties; // for view
    NSMutableArray *_subviewProperties; // for view's subview
    NSMutableArray *_tagviewProperties; // for view's tagged subview
}

+ (instancetype)mapperWithContentsOfURL:(NSURL *)url;
+ (instancetype)mapperWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, strong, readonly) NSArray *tagProperties;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (void)initDataForView:(UIView *)view;
- (void)mapData:(id)data forView:(UIView *)view;

- (void)updateWithData:(id)data andView:(UIView *)view;

@end
