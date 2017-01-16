//
//  PBSwitch.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 17/1/16.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBInput.h"

/**
 An instance of PBSwitch implements the behaviors of an input.
 
 @discussion This is useful for creating a name value pair in which the value is a boolean flag.
 */
@interface PBSwitch : UISwitch <PBInput>

@end
