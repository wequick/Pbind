//
//  PBLiveLoader.m
//  Pbind
//
//  Created by Galen Lin on 2016/12/9.
//

#import "PBLiveLoader.h"

#if (DEBUG && TARGET_IPHONE_SIMULATOR)

#import "PBDirectoryWatcher.h"
#import <Pbind/Pbind.h>

@implementation PBLiveLoader

static NSString *const kPlistSuffix = @".plist";
static NSString *const kJSONSuffix = @".json";
static NSString *const kIgnoresFile = @"ignore.h";

static NSString *const kDebugJSONRedirectKey = @"$redirect";
static NSString *const kDebugJSONStatusKey = @"$status";

static NSArray<NSString *> *kIgnoreAPIs;
static PBDirectoryWatcher  *kResWatcher;
static PBDirectoryWatcher  *kAPIWatcher;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)applicationDidFinishLaunching:(id)note {
    [self watchPlist];
    [self watchAPI];
}

+ (void)watchPlist {
    NSString *resPath = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PBResourcesPath"];
    if (resPath == nil) {
        NSLog(@"PBLiveLoader: Please define PBResourcesPath in Info.plist with value '$(SRCROOT)/[path-to-resources]'!");
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:resPath]) {
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
}

+ (void)watchAPI {
    NSString *serverPath = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PBLocalhost"];
    if (serverPath == nil) {
        NSLog(@"PBLiveLoader: Please define PBLocalhost in Info.plist with value '$(SRCROOT)/[path-to-api]'!");
        return;
    }
    
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
    
    [PBClient registerDebugServer:^id(PBClient *client, PBRequest *request) {
        NSString *action = request.action;
        if ([action characterAtIndex:0] == '/') {
            action = [action substringFromIndex:1]; // bypass '/'
        }
        
        NSString *method = request.method;
        if (method != nil && ![method isEqualToString:@"GET"]) {
            action = [action stringByAppendingFormat:@"@%@", [method lowercaseString]];
        }
        action = [action stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        if (kIgnoreAPIs != nil && [kIgnoreAPIs containsObject:action]) {
            return nil;
        }
        
        NSString *jsonName = [NSString stringWithFormat:@"%@/%@.json", [[client class] description], action];
        NSString *jsonPath = [serverPath stringByAppendingPathComponent:jsonName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:jsonPath]) {
            NSLog(@"PBLiveLoader: Missing '%@', ignores!", jsonName);
            return nil;
        }
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        NSError *error = nil;
        
        PBResponse *response = [[PBResponse alloc] init];
        response.data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error != nil) {
            NSLog(@"PBLiveLoader: Invalid '%@', ignores! The file format should be pure JSON style.", jsonName);
            return nil;
        }
        
        if ([response.data isKindOfClass:[NSDictionary class]]) {
            NSString *redirect = [response.data objectForKey:kDebugJSONRedirectKey];
            if (redirect != nil) {
                PBExpression *expression = [PBExpression expressionWithString:redirect];
                if (expression != nil) {
                    response.data = [expression valueWithData:nil];
                }
            } else {
                NSString *statusString = [response.data objectForKey:kDebugJSONStatusKey];
                if (statusString != nil) {
                    response.status = [statusString intValue];
                }
                NSMutableDictionary *filteredDict = [NSMutableDictionary dictionaryWithDictionary:response.data];
                [filteredDict removeObjectForKey:kDebugJSONStatusKey];
                if (filteredDict.count == 0) {
                    response.data = nil;
                } else {
                    response.data = filteredDict;
                }
            }
        }
        
        return response;
    }];
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

@end

#endif
