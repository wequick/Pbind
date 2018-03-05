//
//  PBCollectionViewFlowLayout.h
//  Pbind
//
//  Created by galen on 2018/3/4.
//

#import <UIKit/UIKit.h>

@class PBCollectionViewFlowLayout;

@protocol PBCollectionViewFlowLayoutDelegate <NSObject>

@optional
- (NSTextAlignment)collectionViewFlowLayout:(PBCollectionViewFlowLayout *)layout alignmentForSectionAtIndex:(NSUInteger)sectionIndex;

@end

@interface PBCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id<PBCollectionViewFlowLayoutDelegate> layoutDelegate;

@end
