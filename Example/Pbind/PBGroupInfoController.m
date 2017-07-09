//
//  PBViewController.m
//  Pbind
//
//  Created by galenlin on 09/07/2016.
//  Copyright (c) 2016 galenlin. All rights reserved.
//

#import "PBGroupInfoController.h"

@interface PBGroupInfoController () <UINavigationControllerDelegate>

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
    _groupParams = @{@"group": @"@TGS"};
    [self setPlist:@"table.group"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)clearChat:(id)sender {
    NSLog(@"!! clearChat");
}

- (void)quitGroup:(id)sender {
    
}

- (BOOL)editNicknameForGroup:(id)sender params:(NSDictionary *)params {
    NSLog(@"%@, %@", sender, params);
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self.tableView.fetcher refetchData];
}

@end
