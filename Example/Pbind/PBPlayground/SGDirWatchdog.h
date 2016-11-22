//
//  SGDirObserver.h
//  DirectoryObserver
//
//  Copyright (c) 2011 Simon Grätzer.
//

#if (DEBUG && TARGET_IPHONE_SIMULATOR)

#import <Foundation/Foundation.h>

@interface SGDirWatchdog : NSObject

@property (readonly, nonatomic) NSString *path;
@property (copy, nonatomic) void (^update)(void);

+ (NSString *)documentsPath;
+ (id)watchtdogOnDocumentsDir:(void (^)(void))update;

- (id)initWithPath:(NSString *)path update:(void (^)(void))update;

- (void)start;
- (void)stop;

@end

#endif
