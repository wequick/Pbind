//
//  PBCreateGroupController.m
//  Pbind
//
//  Created by Galen Lin on 16/9/12.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "PBCreateGroupController.h"

@interface PBCreateGroupController ()

@end

@implementation PBCreateGroupController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.form setPlist:@"PBCreateGroup"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
