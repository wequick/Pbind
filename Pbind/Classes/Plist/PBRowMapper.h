//
//  PBRowMapper.h
//  Pbind
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBMapper.h"

//______________________________________________________________________________
// PBRowMapperDelegate
@class PBRowMapper;
@protocol PBRowMapperDelegate <NSObject>

- (void)rowMapper:(PBRowMapper *)mapper didChangeValue:(id)value forKey:(NSString *)key;

@end

//______________________________________________________________________________

typedef NS_ENUM(NSUInteger, PBRowFloating)
{
    PBRowFloatingNone = 0,
    PBRowFloatingTop,       // :ft
    PBRowFloatingLeft,      // :fl
    PBRowFloatingBottom,    // :fb
    PBRowFloatingRight      // :fr
};

@interface PBRowMapper : PBMapper
{
    struct {
        unsigned int mapping:1;
    } _pbFlags;
}

@property (nonatomic, strong) NSString *nib;
@property (nonatomic, strong) NSString *clazz;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, assign) CGFloat estimatedHeight;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) UIEdgeInsets margin;
@property (nonatomic, assign) UIEdgeInsets padding;

@property (nonatomic, assign) UITableViewCellStyle style;

@property (nonatomic, assign) PBRowFloating floating;

@property (nonatomic, strong) NSString *layout;

@property (nonatomic, assign) Class viewClass;

@property (nonatomic, assign) id<PBRowMapperDelegate> delegate;

/**
 Whether the height is defined by an expression.
 */
@property (nonatomic, assign, readonly, getter=isExpressiveHeight) BOOL expressiveHeight;

- (BOOL)hiddenForView:(id)view withData:(id)data;
- (CGFloat)heightForView:(id)view withData:(id)data;

@end
