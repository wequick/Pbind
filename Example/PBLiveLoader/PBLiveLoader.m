//
//  PBLiveLoader.m
//  Pbind
//
//  Created by Galen Lin on 2016/12/9.
//

#import "PBLiveLoader.h"

#if (PBLIVE_ENABLED)

#include <targetconditionals.h>
#import "PBDirectoryWatcher.h"
#import <Pbind/Pbind.h>

#import "PBSimulatorEnviroment.h"

#if !(TARGET_IPHONE_SIMULATOR)

#import "PBLLRemoteWatcher.h"
#import "PBLLInspector.h"

@interface PBLiveLoader () <PBLLRemoteWatcherDelegate>
{
    void (^apiComplection)(PBResponse *);
    NSData *apiReqData;
    NSString *tempResourcesPath;
    NSMutableDictionary *cacheResponseData;
}

@end

#endif

@implementation PBLiveLoader

static NSString *const kPlistSuffix = @".plist";
static NSString *const kJSONSuffix = @".json";
static NSString *const kIgnoresFile = @"ignore.h";

static NSString *const kDebugJSONRedirectKey = @"$redirect";
static NSString *const kDebugJSONStatusKey = @"$status";

static NSArray<NSString *> *kIgnoreAPIs;

#if (TARGET_IPHONE_SIMULATOR)
static PBDirectoryWatcher  *kResWatcher;
static PBDirectoryWatcher  *kAPIWatcher;
#endif

static BOOL HasSuffix(NSString *src, NSString *tail)
{
    NSInteger loc = [src rangeOfString:tail].location;
    if (loc == NSNotFound) {
        return NO;
    }
    
    return loc == src.length - tail.length;
}

+ (void)load {
    [super load];
    [self watchPlist];
    [self watchAPI];
}

+ (void)watchPlist {
#if (TARGET_IPHONE_SIMULATOR)
    NSString *resPath = PBLLMainBundlePath();
    if (resPath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:resPath]) {
        NSLog(@"PBLiveLoader: PBResourcesPath is not exists! (%@)", resPath);
        return;
    }
    
    kResWatcher = [[PBDirectoryWatcher alloc] init];
    [kResWatcher watchDir:resPath handler:^(NSString *path, BOOL initial, PBDirEvent event) {
        switch (event) {
            case PBDirEventNewFile:
                if (HasSuffix(path, kPlistSuffix)) {
                    NSBundle *updatedBundle = [NSBundle bundleWithPath:[path stringByDeletingLastPathComponent]];
                    [Pbind addResourcesBundle:updatedBundle];
                }
                break;
            
            case PBDirEventModifyFile:
                if (HasSuffix(path, kPlistSuffix)) {
                    [Pbind reloadViewsOnPlistUpdate:path];
                }
                break;
            
            case PBDirEventDeleteFile:
                if (HasSuffix(path, kPlistSuffix)) {
                    [Pbind reloadViewsOnPlistUpdate:path];
                }
                break;
            
            default:
                break;
        }
    }];
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = paths.firstObject;
    NSString *tempBundlePath = [documentPath stringByAppendingPathComponent:@".pb_liveload"];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempBundlePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:tempBundlePath error:&error];
        if (error != nil) {
            NSLog(@"PBLiveLoader: Failed to clear cache.");
            return;
        }
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:tempBundlePath withIntermediateDirectories:NO attributes:nil error:&error];
    if (error != nil) {
        NSLog(@"PBLiveLoader: Failed to initialize cache.");
        return;
    }
    
    [self defaultLoader]->tempResourcesPath = tempBundlePath;
    [Pbind addResourcesBundle:[NSBundle bundleWithPath:tempBundlePath]];
#endif
}

+ (void)watchAPI {
#if (TARGET_IPHONE_SIMULATOR)
    NSString *serverPath = PBLLMockingAPIPath();
    if (![[NSFileManager defaultManager] fileExistsAtPath:serverPath]) {
        NSLog(@"PBLiveLoader: PBLocalhost is not exists! (%@)", serverPath);
        return;
    }
    
    kAPIWatcher = [[PBDirectoryWatcher alloc] init];
    [kAPIWatcher watchDir:serverPath handler:^(NSString *path, BOOL initial, PBDirEvent event) {
        switch (event) {
            case PBDirEventNewFile:
                if (HasSuffix(path, kIgnoresFile)) {
                    kIgnoreAPIs = [self ignoreAPIsWithContentsOfFile:path];
                }
                break;
                
            case PBDirEventModifyFile:
                if (HasSuffix(path, kJSONSuffix)) {
                    [self reloadViewsOnJSONChange:path deleted:NO];
                } else if (HasSuffix(path, kIgnoresFile)) {
                    [self reloadViewsOnIgnoresChange:path deleted:NO];
                }
                break;
                
            case PBDirEventDeleteFile:
                if (HasSuffix(path, kJSONSuffix)) {
                    [self reloadViewsOnJSONChange:path deleted:YES];
                } else if (HasSuffix(path, kIgnoresFile)) {
                    [self reloadViewsOnIgnoresChange:path deleted:YES];
                }
                break;

            default:
                break;
        }
    }];
#endif
    
    [PBClient registerDebugServer:^(PBClient *client, PBRequest *request, void (^complection)(PBResponse *response)) {
        
        NSString *action = request.action;
        if ([action characterAtIndex:0] == '/') {
            action = [action substringFromIndex:1]; // bypass '/'
        }
        
        NSString *method = request.method;
        if (method != nil && ![method isEqualToString:@"GET"]) {
            action = [action stringByAppendingFormat:@"@%@", [method lowercaseString]];
        }
        if (kIgnoreAPIs != nil && [kIgnoreAPIs containsObject:action]) {
            complection(nil);
            return;
        }
        
        action = [action stringByReplacingOccurrencesOfString:@"/" withString:@":"];
        if (kIgnoreAPIs != nil && [kIgnoreAPIs containsObject:action]) {
            complection(nil);
            return;
        }
        
        NSString *clientName = [[client class] alias];
        if (clientName == nil) {
            clientName = [[client class] description];
        }
        NSString *jsonName = [NSString stringWithFormat:@"%@/%@", clientName, action];
        if (kIgnoreAPIs != nil && [kIgnoreAPIs containsObject:jsonName]) {
            complection(nil);
            return;
        }
#if (TARGET_IPHONE_SIMULATOR)
        NSString *jsonPath = [[serverPath stringByAppendingPathComponent:jsonName] stringByAppendingPathExtension:@"json"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:jsonPath]) {
            NSLog(@"PBLiveLoader: Missing '%@', ignores!", jsonName);
            complection(nil);
            return;
        }
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        [self receiveJsonData:jsonData withFile:jsonName complection:complection];
#else
        [[self defaultLoader] requestAPI:jsonName complection:complection];
#endif
    }];
}

+ (void)receiveJsonData:(NSData *)jsonData withFile:(NSString *)jsonName complection:(void (^)(PBResponse *))complection {
    NSError *error = nil;
    id data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (data == nil) {
        NSLog(@"PBLiveLoader: Invalid '%@', ignores! The file format should be pure JSON style.", jsonName);
        complection(nil);
        return;
    }
    
    PBResponse *response = [[PBResponse alloc] init];
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSString *redirect = [data objectForKey:kDebugJSONRedirectKey];
        if (redirect != nil) {
            PBExpression *expression = [PBExpression expressionWithString:redirect];
            if (expression != nil) {
                data = [expression valueWithData:nil];
            }
        } else {
            NSString *statusString = [data objectForKey:kDebugJSONStatusKey];
            if (statusString != nil) {
                response.status = [statusString intValue];
            }
            NSMutableDictionary *filteredDict = [NSMutableDictionary dictionaryWithDictionary:data];
            [filteredDict removeObjectForKey:kDebugJSONStatusKey];
            if (filteredDict.count == 0) {
                data = nil;
            } else {
                data = filteredDict;
            }
        }
    }
    
    response.data = data;
    complection(response);
}

+ (NSArray *)ignoreAPIsWithContentsOfFile:(NSString *)path {
    NSString *content = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding];
    return [[content componentsSeparatedByString:@"\n"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF BEGINSWITH '//') AND NOT (SELF == '')"]];
}

+ (void)reloadViewsOnJSONChange:(NSString *)path deleted:(BOOL)deleted {
    NSArray *components = [path componentsSeparatedByString:@"/"];
    NSString *name = [components lastObject];
    components = [name componentsSeparatedByString:@"."];
    name = [components firstObject];
    [Pbind reloadViewsOnAPIUpdate:name];
}

+ (void)reloadViewsOnIgnoresChange:(NSString *)path deleted:(BOOL)deleted {
    BOOL clear = deleted;
    NSArray *oldIgnores = kIgnoreAPIs;
    NSArray *newIgnores = [self ignoreAPIsWithContentsOfFile:path];
    if (newIgnores.count == 0) {
        clear = YES;
    }
    if (clear) {
        kIgnoreAPIs = nil;
        for (NSString *action in oldIgnores) {
            [Pbind reloadViewsOnAPIUpdate:action];
        }
        return;
    }
    
    NSArray *changedIgnores;
    if (oldIgnores != nil) {
        NSArray *deletedIgnores = [oldIgnores filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", newIgnores]];
        NSArray *addedIgnores = [newIgnores filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", oldIgnores]];
        changedIgnores = [deletedIgnores arrayByAddingObjectsFromArray:addedIgnores];
    } else {
        changedIgnores = newIgnores;
    }
    
    kIgnoreAPIs = newIgnores;
    if (changedIgnores.count > 0) {
        for (NSString *action in changedIgnores) {
            [Pbind reloadViewsOnAPIUpdate:action];
        }
    }
}

#if !(TARGET_IPHONE_SIMULATOR)

+ (PBLiveLoader *)defaultLoader {
    static PBLiveLoader *loader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loader = [[self alloc] init];
        [PBLLRemoteWatcher globalWatcher].delegate = loader;
    });
    return loader;
}

- (void)requestAPI:(NSString *)api complection:(void (^)(PBResponse *))complection {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[PBLLRemoteWatcher globalWatcher] connectDefaultIP];
    });
    
    NSString *key = [api lastPathComponent];
    NSData *cacheData = cacheResponseData[key];
    if (cacheData != nil) {
        [[self class] receiveJsonData:cacheData withFile:nil complection:complection];
        [cacheResponseData removeObjectForKey:key];
        return;
    }
    
    [[PBLLRemoteWatcher globalWatcher] requestAPI:api success:^(NSData *data) {
        [[self class] receiveJsonData:data withFile:nil complection:complection];
    } failure:^(NSError *error) {
        complection(nil);
    }];
}

#pragma mark - PBLLRemoteWatcherDelegate

- (void)remoteWatcher:(PBLLRemoteWatcher *)watcher didChangeConnectState:(BOOL)connected {
    [[PBLLInspector sharedInspector] updateConnectState:connected];
}

- (void)remoteWatcher:(PBLLRemoteWatcher *)watcher didReceiveResponse:(NSData *)jsonData {
    [[self class] receiveJsonData:jsonData withFile:nil complection:apiComplection];
}

- (void)remoteWatcher:(PBLLRemoteWatcher *)watcher didUpdateFile:(NSString *)fileName withData:(NSData *)data {
    if (HasSuffix(fileName, @".plist")) {
        NSError *error;
        NSPropertyListFormat format;
        NSDictionary *dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:&error];
        if (!dict){
            NSLog(@"PBLiveLoader: Got a invalid plist. (error: %@)", error);
            return;
        }
        
        NSString *plistPath = [tempResourcesPath stringByAppendingPathComponent:fileName];
        [data writeToFile:plistPath atomically:NO];
        
        [Pbind reloadViewsOnPlistUpdate:fileName];
    } else if (HasSuffix(fileName, @".json")) {
        if (cacheResponseData == nil) {
            cacheResponseData = [[NSMutableDictionary alloc] init];
        }
        cacheResponseData[fileName] = data;
        [Pbind reloadViewsOnAPIUpdate:fileName];
    }
}

#endif

@end

#endif
