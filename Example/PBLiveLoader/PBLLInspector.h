//
//  PBLLInspector.h
//  Pchat
//
//  Created by Galen Lin on 15/03/2017.
//  Copyright © 2017 galen. All rights reserved.
//

#import "PBLLOptions.h"
#include <targetconditionals.h>

#if (PBLIVE_ENABLED)

#import <UIKit/UIKit.h>

@interface PBLLInspector : UIButton

+ (instancetype)sharedInspector;

- (void)updateConnectState:(BOOL)connected;

@end

#endif
