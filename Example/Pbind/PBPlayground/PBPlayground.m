//
//  PBPlayground.m
//  Pbind
//
//  Created by Galen Lin on 16/9/22.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#if (DEBUG && TARGET_IPHONE_SIMULATOR)

#import "PBPlayground.h"
#import "SGDirWatchdog.h"
#import <Pbind/Pbind.h>

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>

typedef void(^file_handler)(const char *parent, const char *current, const char *name);

int walk_dir(const char *path, int depth, file_handler handler) {
    DIR *d;
    struct dirent *file;
    struct stat sb;
    char subdir[256];
    
    if (!(d = opendir(path))) {
        NSLog(@"error opendir %s!", path);
        return -1;
    }
    
    while ((file = readdir(d)) != NULL) {
        const char *name = file->d_name;
        if (*name == '.') {
            continue;
        }
        
        sprintf(subdir, "%s/%s", path, name);
        if (stat(subdir, &sb) < 0) {
            continue;
        }
        
        if (S_ISDIR(sb.st_mode)) {
            walk_dir(subdir, depth + 1, handler);
            continue;
        }
        
        handler(path, subdir, name);
    }
    
    closedir(d);
    
    return 0;
}

UIViewController *topcontroller(UIViewController *controller)
{
    UIViewController *presentedController = [controller presentedViewController];
    if (presentedController != nil) {
        return topcontroller(presentedController);
    }
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return topcontroller([(id)controller topViewController]);
    }
    
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return topcontroller([(id)controller selectedViewController]);
    }
    
    return controller;
}

@implementation PBPlayground

static NSMutableDictionary<NSString *, SGDirWatchdog *> *kPlistWatchdogs;
static NSMutableDictionary<NSString *, SGDirWatchdog *> *kJsonWatchdogs;

static SGDirWatchdog *kIgnoreAPIWatchdog;
static NSArray *kIgnoreAPIs;
static NSString *kIgnoresFile;

static dispatch_block_t onPlistUpdate = ^{
    UIViewController *controller = [[[UIApplication sharedApplication].delegate window] rootViewController];
    controller = topcontroller(controller);
    [controller.view pb_reloadPlist];
};

static dispatch_block_t onJsonUpdate = ^{
    UIViewController *controller = [[[UIApplication sharedApplication].delegate window] rootViewController];
    controller = topcontroller(controller);
    [controller.view pb_reloadClient];
};

static dispatch_block_t onIgnoresUpdate = ^{
    if (![[NSFileManager defaultManager] fileExistsAtPath:kIgnoresFile]) {
        return;
    }
    
    NSString *content = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:kIgnoresFile] encoding:NSUTF8StringEncoding];
    kIgnoreAPIs = [[content componentsSeparatedByString:@"\n"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF BEGINSWITH '//')"]];
    onJsonUpdate();
};


+ (void)load {
    [super load];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)applicationDidFinishLaunching:(id)note {
    [self watchPlist];
    [self watchAPI];
}

+ (void)watchPlist {
    NSString *resPath = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PBResourcesPath"];
    if (resPath == nil) {
        NSLog(@"PBPlayground: Please define PBResourcesPath in Info.plist with value '$(SRCROOT)/[path-to-resources]'!");
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:resPath]) {
        NSLog(@"PBPlayground: PBResourcesPath is not exists! (%@)", resPath);
        return;
    }
    
    NSMutableArray *resPaths = [[NSMutableArray alloc] init];
    
    walk_dir([resPath UTF8String], 0, ^(const char *parent, const char *current, const char *name) {
        size_t len = strlen(name);
        if (len < 7) return;
        
        char *p = (char *)name + len - 6;
        if (strcmp(p, ".plist") != 0) return;
        
        NSString *parentPath = [[NSString alloc] initWithUTF8String:parent];
        if (![resPaths containsObject:parentPath]) {
            [resPaths addObject:parentPath];
        }
    });
    
    if (resPaths.count == 0) {
        NSLog(@"PBPlayground: Could not found any *.plist!");
        return;
    }
    
    kPlistWatchdogs = [NSMutableDictionary dictionaryWithCapacity:resPaths.count];
    
    for (NSString *path in resPaths) {
        [Pbind addResourcesBundle:[NSBundle bundleWithPath:path]];
        
        SGDirWatchdog *watchdog = [[SGDirWatchdog alloc] initWithPath:path update:onPlistUpdate];
        [kPlistWatchdogs setValue:watchdog forKey:path];
        [watchdog start];
    }
}

+ (void)watchAPI {
    NSString *serverPath = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PBLocalhost"];
    if (serverPath == nil) {
        NSLog(@"PBPlayground: Please define PBLocalhost in Info.plist with value '$(SRCROOT)/[path-to-api]'!");
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:serverPath]) {
        NSLog(@"PBPlayground: PBLocalhost is not exists! (%@)", serverPath);
        return;
    }
    
    kIgnoreAPIWatchdog = [[SGDirWatchdog alloc] initWithPath:serverPath update:onIgnoresUpdate];
    kIgnoresFile = [serverPath stringByAppendingPathComponent:@"ignore.h"];
    onIgnoresUpdate();
    [kIgnoreAPIWatchdog start];
    
    NSMutableArray *jsonPaths = [[NSMutableArray alloc] init];
    
    walk_dir([serverPath UTF8String], 0, ^(const char *parent, const char *current, const char *name) {
        size_t len = strlen(name);
        if (len < 6) return;
        
        char *p = (char *)name + len - 5;
        if (strcmp(p, ".json") != 0) return;
        
        NSString *parentPath = [[NSString alloc] initWithUTF8String:parent];
        if (![jsonPaths containsObject:parentPath]) {
            [jsonPaths addObject:parentPath];
        }
    });
    
    if (jsonPaths.count == 0) {
        NSLog(@"PBPlayground: Could not found any *.json!");
        return;
    }
    
    kJsonWatchdogs = [NSMutableDictionary dictionaryWithCapacity:jsonPaths.count];
    
    for (NSString *path in jsonPaths) {
        SGDirWatchdog *watchdog = [[SGDirWatchdog alloc] initWithPath:path update:onJsonUpdate];
        [kPlistWatchdogs setValue:watchdog forKey:path];
        [watchdog start];
    }

    [PBClient registerDebugServer:^id(PBClient *client, PBRequest *request) {
        NSString *action = request.action;
        if ([action characterAtIndex:0] == '/') {
            action = [action substringFromIndex:1]; // bypass '/'
        }
        
        if (kIgnoreAPIs != nil && [kIgnoreAPIs containsObject:action]) {
            return nil;
        }
        
        NSString *jsonName = [NSString stringWithFormat:@"%@/%@.json", [[client class] description], action];
        NSString *jsonPath = [serverPath stringByAppendingPathComponent:jsonName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:jsonPath]) {
            NSLog(@"PBPlayground: Missing '%@', ignores!", jsonName);
            return nil;
        }
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        NSError *error = nil;
        id response = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error != nil) {
            NSLog(@"PBPlayground: Invalid '%@', ignores!", jsonName);
            return nil;
        }
        
        return response;
    }];
}

@end

#endif
