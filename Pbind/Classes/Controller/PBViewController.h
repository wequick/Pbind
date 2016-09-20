//
//  PBViewController.h
//  Pods
//
//  Created by Galen Lin on 16/9/20.
//
//

#import <UIKit/UIKit.h>

@interface PBViewController : UIViewController

/**
 The plist file name, will be set to the content view.
 */
@property (nonatomic, strong) NSString *plist;

/**
 The data, will be set the content view.
 */
@property (nonatomic, strong) id data;

@end
