//
//  LSViewController.m
//  Less
//
//  Created by galenlin on 09/07/2016.
//  Copyright (c) 2016 galenlin. All rights reserved.
//

#import "LSViewController.h"

@interface LSViewController ()

@property (nonatomic, strong) NSDictionary *groupParams;

@end

@implementation LSViewController

- (UITableViewStyle)preferredTableViewStyle {
    return UITableViewStyleGrouped;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _groupId = @"111";
    [self.tableView setPlist:@"LSExample"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)clearChat:(id)sender {
    
}

- (void)quitGroup:(id)sender {
    
}

@end
