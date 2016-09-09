//
//  _PBFormInputSpec.h
//  Pbind
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface _PBFormInputSpec : NSObject

@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) UIView *input;

@property (nonatomic, strong) id typeValue;
@property (nonatomic, strong) NSString *type;

@property (nonatomic, strong) id nameValue;
@property (nonatomic, strong) NSString *name;

@end
