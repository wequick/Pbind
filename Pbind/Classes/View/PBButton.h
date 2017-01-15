//
//  PBButton.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/21.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBInput.h"

@interface PBButton : UIButton<PBInput>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *disabledTitle; // title:disabled
@property (nonatomic, strong) NSString *selectedTitle; // title:selected
@property (nonatomic, strong) NSString *highlightedTitle; // image:selected

@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSString *disabledImage;
@property (nonatomic, strong) NSString *selectedImage;
@property (nonatomic, strong) NSString *highlightedImage;

@property (nonatomic, strong) NSString *backgroundImage;
@property (nonatomic, strong) NSString *disabledBackgroundImage;
@property (nonatomic, strong) NSString *selectedBackgroundImage;
@property (nonatomic, strong) NSString *highlightedBackgroundImage;

@property (nonatomic, strong) UIColor *disabledBackgroundColor;
@property (nonatomic, strong) UIColor *selectedBackgroundColor;
@property (nonatomic, strong) UIColor *highlightedBackgroundColor;

@end
