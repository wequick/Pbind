//
//  _PBFormInputSpec.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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
