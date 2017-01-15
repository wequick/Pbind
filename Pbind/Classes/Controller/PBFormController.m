//
//  PBFormController.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/11.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBFormController.h"

@implementation PBFormController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _form = [[PBForm alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _form.formDelegate = self;
    
    self.view = _form;
}

@end
