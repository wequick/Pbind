//
//  PBLLInspectorController.m
//  Pchat
//
//  Created by Galen Lin on 15/03/2017.
//

#import "PBLLInspectorController.h"

#if (DEBUG && !(TARGET_IPHONE_SIMULATOR))

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
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect frame = self.view.bounds;
    frame.size.height = 44.f;
    frame.origin.y = 16.f;
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:frame];
    searchBar.text = [self defaultIP];
    searchBar.delegate = self;
    searchBar.returnKeyType = UIReturnKeyJoin;
    [self.view addSubview:searchBar];
    _searchBar = searchBar;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [PBLLInspector sharedInspector].hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [PBLLInspector sharedInspector].hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)defaultIP {
    NSString *ip = [[NSUserDefaults standardUserDefaults] objectForKey:@"pbind.server.ip"];
    if (ip == nil) {
        ip = @"192.168.1.10";
    }
    return ip;
}

- (void)setDefaultIP:(NSString *)ip {
    [[NSUserDefaults standardUserDefaults] setObject:ip forKey:@"pbind.server.ip"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *ip = searchBar.text;
    if (ip.length == 0) {
        return;
    }
    
    [self setDefaultIP:ip];
    [[PBLLRemoteWatcher globalWatcher] connect:ip];
    [self.navigationController popViewControllerAnimated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [PBTopController().view pb_reloadClient];
    });
}

#pragma mark - Gesture

- (void)didTap:(id)sender {
    [_searchBar resignFirstResponder];
}

@end

#endif
