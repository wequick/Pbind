//
//  PBScrollViewController.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 26/03/2017.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBScrollViewController.h"

@interface PBScrollViewController ()

@end

@implementation PBScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _scrollView = [[PBScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = _scrollView;
}

@end
