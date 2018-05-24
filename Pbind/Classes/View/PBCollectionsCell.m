//
//  PBCollectionsCell.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/8/30.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBCollectionsCell.h"
#import "PBCollectionView.h"
#import "UIView+Pbind.h"

@interface PBCollectionsCell () <PBViewResizingDelegate>

@end

@implementation PBCollectionsCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _collectionView = [[PBCollectionView alloc] init];
        [_collectionView setTag:1];
        [_collectionView setAutoResize:YES];
        _collectionView.resizingDelegate = self;
        [self.contentView addSubview:_collectionView];
        [_collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSDictionary *views = @{@"c": _collectionView, @"ct": self.contentView};
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[c(==ct)]-0-|" options:0 metrics:nil views:views];
        [self.contentView addConstraints:constraints];
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[c(==ct)]-0-|" options:0 metrics:nil views:views];
        [self.contentView addConstraints:constraints];
    }
    return self;
}

- (void)viewDidChangeFrame:(UIView *)view {
    UITableView *tableView = [self superviewWithClass:[UITableView class]];
    if (tableView == nil) {
        return;
    }
    
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    if (indexPath == nil) {
        return;
    }
    
    [tableView reloadData];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
