//
//  PBLLInspectorTipsController.h
//  Pbind
//
//  Created by galen on 17/7/29.
//

#import "PBLLOptions.h"
#include <targetconditionals.h>

#if (PBLIVE_ENABLED)

#import <UIKit/UIKit.h>

@interface PBLLInspectorTipsController : UIViewController

@property (nonatomic, strong) NSString *tips;

@property (nonatomic, strong) NSString *code;

@end

#endif
