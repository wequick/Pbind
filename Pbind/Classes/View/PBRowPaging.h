//
//  PBRowPaging.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 22/12/2016.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBDictionary.h"
#import "PBRowMapping.h"

@protocol PBRowPaging <PBRowMapping, NSObject>

@required

/**
 The params used to paging, usually as {page: .page+1, pageSize: 10} or {offset: .page*10, limit: 10}.
 If was set, will automatically add a `_refreshControl` for `pull-down-to-refresh`
 and a `_pullupControl` for `pull-up-to-load-more`.
 */
@property (nonatomic, strong) PBDictionary *pagingParams;

/**
 The loading page count, default is 0.
 While `_pullupControl` released, the value will be increased by 1.
 */
@property (nonatomic, assign) NSInteger page;

/** The dictionary to be parsed as a `PBRowControlMapper' to map the data for pulled-down-to-refresh control */
@property (nonatomic, strong) NSDictionary *refresh;

/** The dictionary to be parsed as a `PBRowControlMapper' to map the data for pulled-up-to-load-more control */
@property (nonatomic, strong) NSDictionary *more;

/**
 Re-fetch data with the initial paging parameters and reload the table view.
 */
- (void)refreshData;

/**
 Reload the data to display new list
 */
- (void)reloadData;

@end
