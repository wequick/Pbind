//
//  PBLiveLoader.h
//  Pbind
//
//  Created by Galen Lin on 2016/12/9.
//

#include <targetconditionals.h>

#if (DEBUG && TARGET_IPHONE_SIMULATOR)

#import <Foundation/Foundation.h>

/**
 The live loader for Pbind.
 
 @discussion while the application start, it will watch the project directories
 to detect changes of all the *.plist files and all the *.json files under PBLocalhost
 directory, by what we can instantly reload the related views.
 */
@interface PBLiveLoader : NSObject

@end

#endif
