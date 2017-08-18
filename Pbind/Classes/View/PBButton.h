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

/**
 An instance of PBButton provides the ability of configuring with Plist.
 
 @discussion Support configure title, image, backgroundImage and backgroundColor for state.
 */
@interface PBButton : UIButton<PBInput>

#pragma mark - Styling
///=============================================================================
/// @name Styling
///=============================================================================

/** The title for the normal state */
@property (nonatomic, strong) NSString *title;
/** The title for the disabled state */
@property (nonatomic, strong) NSString *disabledTitle;
/** The title for the selected state */
@property (nonatomic, strong) NSString *selectedTitle;
/** The title for the highlighted state */
@property (nonatomic, strong) NSString *highlightedTitle;

/** The title color for the normal state */
@property (nonatomic, strong) UIColor *titleColor;
/** The title color for the disabled state */
@property (nonatomic, strong) UIColor *disabledTitleColor;
/** The title color for the selected state */
@property (nonatomic, strong) UIColor *selectedTitleColor;
/** The title color for the highlighted state */
@property (nonatomic, strong) UIColor *highlightedTitleColor;

/** The image name to create the image for the normal state */
@property (nonatomic, strong) NSString *image;
/** The image name to create the image for the disabled state */
@property (nonatomic, strong) NSString *disabledImage;
/** The image name to create the image for the selected state */
@property (nonatomic, strong) NSString *selectedImage;
/** The image name to create the image for the highlighted state */
@property (nonatomic, strong) NSString *highlightedImage;

/** The image name to create the background image for the normal state */
@property (nonatomic, strong) NSString *backgroundImage;
/** The image name to create the background image for the disabled state */
@property (nonatomic, strong) NSString *disabledBackgroundImage;
/** The image name to create the background image for the selected state */
@property (nonatomic, strong) NSString *selectedBackgroundImage;
/** The image name to create the background image for the highlighted state */
@property (nonatomic, strong) NSString *highlightedBackgroundImage;

/** 
 The color for the disabled state
 
 @discussion If not specified, use the background color with 0.2 opacity.
 */
@property (nonatomic, strong) UIColor *disabledBackgroundColor;
/**
 The color for the selected state
 
 @discussion If not specified, use the background color.
 */
@property (nonatomic, strong) UIColor *selectedBackgroundColor;
/**
 The color for the highlighted state
 
 @discussion If not specified, use the background color with 0.8 opacity.
 */
@property (nonatomic, strong) UIColor *highlightedBackgroundColor;

/** The attributed title for the normal state */
@property (nonatomic, strong) NSAttributedString *attributedTitle;
/** The attributed title for the disabled state */
@property (nonatomic, strong) NSAttributedString *disabledAttributedTitle;
/** The attributed title for the selected state */
@property (nonatomic, strong) NSAttributedString *selectedAttributedTitle;
/** The attributed title for the highlighted state */
@property (nonatomic, strong) NSAttributedString *highlightedAttributedTitle;

#pragma mark - Labeling
///=============================================================================
/// @name Labeling
///=============================================================================

/** same to `titleColor' */
@property (nonatomic, strong) UIColor *textColor;

/** same to `attributedTitle' */
@property (nonatomic, strong) NSAttributedString *attributedText;

@end
