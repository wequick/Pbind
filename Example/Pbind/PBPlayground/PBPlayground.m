//
//  PBPlayground.m
//  Pbind
//
//  Created by Galen Lin on 16/9/22.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "PBPlayground.h"
#import "SGDirWatchdog.h"
#import <Pbind/Pbind.h>

@implementation PBPlayground

static SGDirWatchdog *kWatchdog;

+ (void)load {
    [super load];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)applicationDidFinishLaunching:(id)note {
    NSString *watchPath = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PBWatchPath"];
    if (watchPath == nil) {
        NSLog(@"PBPlayground: Please define PBWatchPath in Info.plist with value '$(SRCROOT)/[path-to-watch]'!");
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:watchPath]) {
        NSLog(@"PBPlayground: PBWatchPath is not exists! (%@)", watchPath);
        return;
    }
    
    NSBundle *bundle = [NSBundle bundleWithPath:watchPath];
    [Pbind addResourcesBundle:bundle];
    
    kWatchdog = [[SGDirWatchdog alloc] initWithPath:watchPath update:^{
        UIViewController *controller = [[[UIApplication sharedApplication].delegate window] rootViewController];
        controller = [self topcontroller:controller];
        [controller.view pb_reloadPlist];
//        NSLog(@"updated!!!");
//        NSDate *modify = [self getLastModifyOfFilePath:watchPlist];
//        
//        if (![modify isEqualToDate:lastModify]) {
//            NSLog(@"!!! Modified");
//            [self updatePlist:watchPlist];
//        }
    }];
    [kWatchdog start];
}

+ (UIViewController *)topcontroller:(UIViewController *)controller
{
    UIViewController *presentedController = [controller presentedViewController];
    if (presentedController != nil) {
        return [self topcontroller:presentedController];
    }
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return [self topcontroller:[(id)controller topViewController]];
    }
    
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return [self topcontroller:[(id)controller selectedViewController]];
    }
    
    return controller;
}

+ (void)search {
    NSString *baseDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSFileManager *defFM = [NSFileManager defaultManager];
    BOOL isDir = YES;
    
    NSArray *fileTypes = [[NSArray alloc] initWithObjects:@"plist", nil];
    NSMutableArray *mediaFiles = [self searchfiles:baseDir ofTypes:fileTypes];
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [docDir stringByAppendingPathComponent:@"playlist.plist"];
    if(![defFM fileExistsAtPath:filePath isDirectory:&isDir]){
        [defFM createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    NSMutableDictionary *playlistDict = [[NSMutableDictionary alloc]init];
    for(NSString *path in mediaFiles){
        NSLog(@"%@",path);
        [playlistDict setValue:[NSNumber numberWithBool:YES] forKey:path];
    }
    
    [playlistDict writeToFile:filePath atomically:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshplaylist" object:nil];
}

+ (NSMutableArray*)searchfiles:(NSString*)basePath ofTypes:(NSArray*)fileTypes{
    NSMutableArray *files = [[NSMutableArray alloc]init];
    NSFileManager *defFM = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *dirPath = [defFM contentsOfDirectoryAtPath:basePath error:&error];
    for(NSString *path in dirPath){
        BOOL isDir;
        NSString *_path = [basePath stringByAppendingPathComponent:path];
        if([defFM fileExistsAtPath:path isDirectory:&isDir] && isDir){
            [files addObjectsFromArray:[self searchfiles:_path ofTypes:fileTypes]];
        }
    }
    
    
    NSArray *mediaFiles = [dirPath pathsMatchingExtensions:fileTypes];
    for(NSString *fileName in mediaFiles){
        NSString *_fileName = [basePath stringByAppendingPathComponent:fileName];
        [files addObject:_fileName];
    }
    
    return files;
}

@end
