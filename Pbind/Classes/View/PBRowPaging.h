//
//  PBRowPaging.h
//  Pbind
//
//  Created by Galen Lin on 22/12/2016.
//
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

/**
 Whether needs to load more page.
 
 @discussion This needs binding an expression by:
 
 - setting `needsLoadMore=$expression` in your plist or
 - call [self setExpression:@"$expression" forKey:@"needsLoadMore"]
 
 The default expression is nil and the value will be always YES. If an expression was set, then
 while pulling up to load more, the expression will be re-calculated and set to this property.
 */
@property (nonatomic, assign) BOOL needsLoadMore;

/**
 Re-fetch data with the initial paging parameters and reload the table view.
 */
- (void)refresh;

/**
 Reload the data to display new list
 */
- (void)reloadData;

@end
