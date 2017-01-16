//
//  PBViewController.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/9/20.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBViewController.h"
#import "UIView+Pbind.h"
#import "PBDataFetcher.h"
#import "PBDataFetching.h"

@interface PBViewController ()
{
    struct {
        unsigned int initializedViewData: 1;
    } _pbFlags;
}

@end

@implementation PBViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.data != nil) {
        [self.view setData:self.data];
        self.data = nil;
    }
    
    BOOL needsFetch = NO;
    UIView<PBDataFetching> *fetchingView = nil;
    if ([self.view conformsToProtocol:@protocol(PBDataFetching)]) {
        fetchingView = (id) self.view;
    }
    
    // Map properties
    if (!_pbFlags.initializedViewData) {
        _pbFlags.initializedViewData = 1;
        if (self.plist != nil) {
            [self.view setPlist:self.plist];
            self.plist = nil;
        }
        if (self.view.plist != nil) {
            // Init fetcher
            if (fetchingView != nil && fetchingView.clients != nil) {
                PBDataFetcher *fetcher = [[PBDataFetcher alloc] init];
                fetcher.owner = fetchingView;
                fetchingView.fetcher = fetcher;
                needsFetch = YES;
            }
        }
    }
    
    // Fetch data
    if (fetchingView != nil) {
        if (!needsFetch && fetchingView.interrupted) {
            needsFetch = YES;
        }
        if (needsFetch) {
            [fetchingView.fetcher fetchData];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.view conformsToProtocol:@protocol(PBDataFetching)]) {
        UIView<PBDataFetching> *fetchingView = (id) self.view;
        if ([fetchingView isFetching]) {
            // If super controller is neither a singleton nor a child of `UITabBarController', mark interrupted flag to reload at next appearance
            if (![[self.navigationController parentViewController] isKindOfClass:[UITabBarController class]]) {
                fetchingView.interrupted = YES;
                [fetchingView.fetcher cancel];
            }
        }
    }
}

- (void)dealloc {
    if (![self isViewLoaded]) {
        return;
    }
    [self.view pb_unbindAll];
}

@end
