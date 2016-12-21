//
//  PBViewController.m
//  Pods
//
//  Created by Galen Lin on 16/9/20.
//
//

#import "PBViewController.h"
#import "UIView+Pbind.h"

@interface PBViewController ()

@end

@implementation PBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.plist != nil) {
        [self.view setPlist:self.plist];
    }
    if (self.data != nil) {
        [self.view setData:self.data];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    if (![self isViewLoaded]) {
        return;
    }
    [self.view pb_unbindAll];
}

@end
