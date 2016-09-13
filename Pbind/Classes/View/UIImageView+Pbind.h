//
//  UIImageView+Pbind.h
//  Pods
//
//  Created by Galen Lin on 16/9/13.
//
//

#import <UIKit/UIKit.h>

@interface UIImageView (Pbind)

/**
 The image name used to locate the image in preferred bundles.
 
 @discussion Where the preferred bundles are:
 
 * 1. The bundle of the image view's super controller class
 * 2. The main bundle
 * 3. The patch bundle
 
 */
- (void)setImageName:(NSString *)imageName;

@end
