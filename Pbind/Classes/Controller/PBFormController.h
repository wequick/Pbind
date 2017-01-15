//
//  PBFormController.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/11.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBForm.h"
#import "PBViewController.h"

@interface PBFormController : PBViewController<PBFormDelegate>

@property (nonatomic, strong) PBForm *form;

@end
