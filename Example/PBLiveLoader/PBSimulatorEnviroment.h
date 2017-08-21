//
//  PBSimulatorEnviroment.h
//  Pbind
//
//  Created by Galen Lin on 13/03/2017.
//

#if (DEBUG)

#include <targetconditionals.h>
#import <Foundation/Foundation.h>

#if (TARGET_IPHONE_SIMULATOR)

FOUNDATION_STATIC_INLINE NSString *PBLLProjectPath() {
    return [[@(__FILE__) stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
}

FOUNDATION_STATIC_INLINE NSString *PBLLMainBundlePath() {
    NSString *projectPath = PBLLProjectPath();
    NSString *bundlePath = [projectPath stringByAppendingPathComponent:[projectPath lastPathComponent]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
        return bundlePath;
    }
    
    NSArray *subdirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:projectPath error:nil];
    for (NSString *subdir in subdirs) {
        bundlePath = [projectPath stringByAppendingPathComponent:subdir];
        NSString *mainFile = [bundlePath stringByAppendingPathComponent:@"main.m"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:mainFile]) {
            return bundlePath;
        }
    }
    return nil;
}

FOUNDATION_STATIC_INLINE NSString *PBLLMockingAPIPath() {
    return [PBLLProjectPath() stringByAppendingPathComponent:@"PBLocalhost"];
}

#endif

#endif
