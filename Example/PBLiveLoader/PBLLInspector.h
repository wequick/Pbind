//
//  PBLLInspector.h
//  Pchat
//
//  Created by Galen Lin on 15/03/2017.
//  Copyright © 2017 galen. All rights reserved.
//

#include <targetconditionals.h>

#if (DEBUG && !(TARGET_IPHONE_SIMULATOR))

#import <UIKit/UIKit.h>

@interface PBLLInspector : UIButton

+ (instancetype)sharedInspector;

+ (void)addToWindow;

@end

#endif
