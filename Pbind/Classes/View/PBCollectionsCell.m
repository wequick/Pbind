//
//  PBCollectionsCell.m
//  Pbind
//
//  Created by Galen Lin on 16/8/30.
//  Copyright © 2016年 galen. All rights reserved.
//

#import "PBCollectionsCell.h"
#import "PBCollectionView.h"

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
        [_collectionView setScrollEnabled:NO];
        [_collectionView setAutoResize:YES];
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

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
