//
//  PBButton.h
//  Pods
//
//  Created by Galen Lin on 2016/12/21.
//
//

#import <UIKit/UIKit.h>
#import "PBInput.h"

@interface PBButton : UIButton<PBInput>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *disabledTitle; // title:disabled
@property (nonatomic, strong) NSString *selectedTitle; // title:selected
@property (nonatomic, strong) NSString *highlightedTitle; // image:selected

@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSString *disabledImage;
@property (nonatomic, strong) NSString *selectedImage;
@property (nonatomic, strong) NSString *highlightedImage;

@end
