//
//  PBLLResource.h
//  Pbind
//
//  Created by galen on 17/7/30.
//

#import "PBLLOptions.h"
#include <targetconditionals.h>

#if (PBLIVE_ENABLED)

#import <Foundation/Foundation.h>

@interface PBLLResource : NSObject

+ (UIImage *)logoImage;

+ (UIImage *)copyImage;

@end

#endif
