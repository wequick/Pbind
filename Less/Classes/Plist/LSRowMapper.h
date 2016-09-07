//
//  LSRowMapper.h
//  Less
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSMapper.h"

//______________________________________________________________________________
// LSRowMapperDelegate
@class LSRowMapper;
@protocol LSRowMapperDelegate <NSObject>

- (void)rowMapper:(LSRowMapper *)mapper didChangeValue:(id)value forKey:(NSString *)key;

@end

//______________________________________________________________________________

typedef NS_ENUM(NSUInteger, LSRowFloating)
{
    LSRowFloatingNone = 0,
    LSRowFloatingTop,       // :ft
    LSRowFloatingLeft,      // :fl
    LSRowFloatingBottom,    // :fb
    LSRowFloatingRight      // :fr
};

@interface LSRowMapper : LSMapper
{
    struct {
        unsigned int mapping:1;
    } _lsFlags;
}

@property (nonatomic, strong) NSString *nib;
@property (nonatomic, strong) NSString *clazz;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) UIEdgeInsets margin;
@property (nonatomic, assign) UIEdgeInsets padding;

@property (nonatomic, assign) UITableViewCellStyle style;

@property (nonatomic, assign) LSRowFloating floating;

@property (nonatomic, strong) NSString *layout;

@property (nonatomic, assign) Class viewClass;

@property (nonatomic, assign) id<LSRowMapperDelegate> delegate;

- (BOOL)hiddenForView:(id)view withData:(id)data;
- (CGFloat)heightForView:(id)view withData:(id)data;

@end
