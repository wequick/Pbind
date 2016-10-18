//
//  PBCollectionViewController.m
//  Pods
//
//  Created by Galen Lin on 2016/10/18.
//
//

#import "PBCollectionViewController.h"

@interface PBCollectionViewController ()

@end

@implementation PBCollectionViewController

- (void)viewDidLoad {
    _collectionView = [[PBCollectionView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    self.view = _collectionView;
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
