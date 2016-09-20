//
//  PBViewController.m
//  Pbind
//
//  Created by galenlin on 09/07/2016.
//  Copyright (c) 2016 galenlin. All rights reserved.
//

#import "PBGroupInfoController.h"

@interface PBGroupInfoController ()

@property (nonatomic, strong) NSDictionary *groupParams;

@end

@implementation PBGroupInfoController

- (UITableViewStyle)preferredTableViewStyle {
    return UITableViewStyleGrouped;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _groupId = @"111";
    _groupParams = @{@"group": @"1"};
    [self.tableView setPlist:@"PBExample"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)joinGroup:(id)sender {
    [self.navigationController pushViewController:[[NSClassFromString(@"PBCreateGroupController") alloc] init] animated:YES];
}

- (void)clearChat:(id)sender {
    
}

- (void)quitGroup:(id)sender {
    
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self.tableView pb_repullData];
}

@end
