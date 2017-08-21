//
//  PBDirectoryWatcher.h
//  Pbind
//
//  Created by Galen Lin on 2016/12/9.
//

#import "PBLLOptions.h"
#include <targetconditionals.h>

#if (PBLIVE_ENABLED && TARGET_IPHONE_SIMULATOR)

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    PBDirEventNewFolder,
    PBDirEventNewFile,
    PBDirEventDeleteFolder,
    PBDirEventDeleteFile,
    PBDirEventModifyFile
} PBDirEvent;

/**
 A watcher that recursively watch directories|files create|modify|delete events.
 */
@interface PBDirectoryWatcher : NSObject

/**
 Start watching the directory.

 @param dir     the watching directory root.
 @param handler the handler to handle all the events.
 */
- (void)watchDir:(NSString *)dir
         handler:(void (^)(NSString *path, BOOL initial, PBDirEvent event))handler;

@end

#endif
