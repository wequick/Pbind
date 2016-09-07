//
//  LSFormController.m
//  Less
//
//  Created by galen on 15/4/11.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSFormController.h"

@implementation LSFormController

- (void)viewDidLoad {
    [super viewDidLoad];
    _form = [[LSForm alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = _form;
}

@end
