//
//  PBLLInspectorController.h
//  Pchat
//
//  Created by Galen Lin on 15/03/2017.
//  Copyright © 2017 galen. All rights reserved.
//

#import "PBLLOptions.h"
#include <targetconditionals.h>

#if (PBLIVE_ENABLED && !(TARGET_IPHONE_SIMULATOR))

#import <UIKit/UIKit.h>

@interface PBLLInspectorController : UIViewController

@end

#endif
