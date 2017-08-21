//
//  PBLLRemoteWatcher.h
//  Pchat
//
//  Created by Galen Lin on 15/03/2017.
//  Copyright © 2017 galen. All rights reserved.
//

#import "PBLLOptions.h"
#include <targetconditionals.h>

#if (PBLIVE_ENABLED && !(TARGET_IPHONE_SIMULATOR))

#import <Foundation/Foundation.h>

@class PBLLRemoteWatcher;

@protocol PBLLRemoteWatcherDelegate <NSObject>

- (void)remoteWatcher:(PBLLRemoteWatcher *)watcher didUpdateFile:(NSString *)fileName withData:(NSData *)data;

@optional

- (void)remoteWatcher:(PBLLRemoteWatcher *)watcher didCreateFile:(NSString *)fileName;
- (void)remoteWatcher:(PBLLRemoteWatcher *)watcher didDeleteFile:(NSString *)fileName;

- (void)remoteWatcher:(PBLLRemoteWatcher *)watcher didChangeConnectState:(BOOL)connected;

@end

@interface PBLLRemoteWatcher : NSObject

+ (instancetype)globalWatcher;

- (void)connect:(NSString *)ip;
- (void)connectDefaultIP;

- (void)requestAPI:(NSString *)api success:(void (^)(NSData *))success failure:(void (^)(NSError *))failure;

- (void)sendLog:(NSString *)log;

@property (nonatomic, assign) id<PBLLRemoteWatcherDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *defaultIP;

@end

#endif
