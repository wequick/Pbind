//
//  PBLLInspectorController.m
//  Pchat
//
//  Created by Galen Lin on 15/03/2017.
//

#import "PBLLInspectorController.h"

#if (PBLIVE_ENABLED && !(TARGET_IPHONE_SIMULATOR))

#import "PBLLInspector.h"
#import "PBLLRemoteWatcher.h"
#import <Pbind/Pbind.h>

@interface PBLLInspectorController () <UISearchBarDelegate>
{
    UISearchBar *_searchBar;
}

@end

@implementation PBLLInspectorController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Pbind";
    UIColor *primaryColor = PBColorMake(@"5D74E9");
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBarTintColor:primaryColor];
    [navigationBar setTintColor:[UIColor whiteColor]];
    [navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setShadowImage:[UIImage new]];
    [navigationBar setTranslucent:NO];
    [navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect frame = self.view.bounds;
    frame.size.height = 44.f;
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:frame];
    searchBar.barTintColor = primaryColor;
    searchBar.text = [PBLLRemoteWatcher globalWatcher].defaultIP;
    searchBar.delegate = self;
    searchBar.returnKeyType = UIReturnKeyJoin;
    searchBar.barStyle = UISearchBarStyleMinimal;
    [self.view addSubview:searchBar];
    _searchBar = searchBar;
    [searchBar becomeFirstResponder];
    
    // Help label
    UILabel *helpLabel = [[UILabel alloc] init];
    helpLabel.font = [UIFont systemFontOfSize:14.f];
    helpLabel.numberOfLines = 0;
    helpLabel.textColor = PBColorMake(@"666");
    helpLabel.text = @(
    "Input the IP of the pbind server started by:\n"
    "\n"
    "        > gem install pbind"      "\n"
    "        > cd [path-to-xcodeproj]" "\n"
    "        > pbind serv"             "\n"
    "\n"
    "Then click [Join] to start online debugging.");
    [self.view addSubview:helpLabel];
    
    frame.origin.y += frame.size.height + 44.f;
    frame.origin.x = 32.f;
    frame.size.width = frame.size.width - 64.f;
    frame.size.height = [helpLabel sizeThatFits:frame.size].height;
    helpLabel.frame = frame;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [PBLLInspector sharedInspector].hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [PBLLInspector sharedInspector].hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *ip = searchBar.text;
    if (ip.length == 0) {
        return;
    }
    
    [[PBLLRemoteWatcher globalWatcher] connect:ip];
    [self dismiss];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [PBTopController().view pb_reloadClient];
    });
}

#pragma mark - Gesture

- (void)didTap:(id)sender {
    [_searchBar resignFirstResponder];
}

- (void)dismiss {
    [_searchBar resignFirstResponder];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end

#endif
