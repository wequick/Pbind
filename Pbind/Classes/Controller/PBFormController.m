//
//  PBFormController.m
//  Pbind
//
//  Created by galen on 15/4/11.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBFormController.h"

@implementation PBFormController

- (void)viewDidLoad {
    [super viewDidLoad];
    _form = [[PBForm alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = _form;
}

@end
