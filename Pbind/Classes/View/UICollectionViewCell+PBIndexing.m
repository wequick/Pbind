//
//  UICollectionViewCell+PBIndexing.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 17/7/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UICollectionViewCell+PBIndexing.h"
#import "UIView+Pbind.h"

@implementation UICollectionViewCell (PBIndexing)

- (void)setIndexPath:(NSIndexPath *)indexPath {
    [self setValue:indexPath forAdditionKey:@"pb_indexPath"];
}

- (NSIndexPath *)indexPath {
    return [self valueForAdditionKey:@"pb_indexPath"];
}

@end
