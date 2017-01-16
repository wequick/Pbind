//
//  PBDirectoryWatcher.m
//  Pbind
//
//  Created by Galen Lin on 2016/12/9.
//

#import "PBDirectoryWatcher.h"

#if (DEBUG && TARGET_IPHONE_SIMULATOR)

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/event.h>

typedef void(^file_handler)(const char *dir, const char *file, const char *name, BOOL isDir);
static int walk_dir(const char *path, int depth_limit, file_handler handler);

//

@interface _PBMonitorFile : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) NSTimeInterval lastModified;

- (instancetype)initWithPath:(NSString *)path;
- (BOOL)updateLastModified;

@end

//

@class _PBDirWatcher;
@protocol _PBDirWatcherDelegate <NSObject>

- (void)directoryDidChange:(_PBDirWatcher *)watcher;

@end

//

@interface _PBDirWatcher : NSObject

@property (nonatomic, readonly) NSString *path;
@property (copy, nonatomic) void (^update)(void);

- (instancetype)initWithDir:(NSString *)dir file:(NSString *)file delegate:(id<_PBDirWatcherDelegate>)delegate;

- (void)addSubdir:(NSString *)dir;
- (void)addFile:(NSString *)file;
- (_PBMonitorFile *)fileForPath:(NSString *)path;
- (NSArray<NSString *> *)updateSubdirs:(NSArray<NSString *> *)subdirs;
- (NSArray<NSString *> *)updateFiles:(NSArray<NSString *> *)subdirs;

- (void)invalidate;

@end


@interface PBDirectoryWatcher () <_PBDirWatcherDelegate>
{
    NSMutableArray<_PBDirWatcher *> *_dirWatchers;
    NSArray<NSString *> *_extensions;
    void (^_handler)(NSString *path, BOOL initial, PBDirEvent event);
}

@end

@implementation PBDirectoryWatcher

- (void)watchDir:(NSString *)dir
         handler:(void (^)(NSString *path, BOOL initial, PBDirEvent event))handler
{
    _dirWatchers = [[NSMutableArray alloc] init];
    _handler = handler;
    [self scan:dir watcher:nil];
}

- (void)scan:(NSString *)path watcher:(_PBDirWatcher *)watcher
{
    BOOL initial = (watcher == nil);
    int walk_depth = initial ? 0 : 1;
    
    NSMutableArray *subdirs;
    NSMutableArray *files;
    if (!initial) {
        subdirs = [[NSMutableArray alloc] init];
        files = [[NSMutableArray alloc] init];
    }
    
    walk_dir([path UTF8String], walk_depth, ^(const char *dir, const char *file, const char *name, BOOL isDir) {
        if (isDir) {
            NSString *resDir = [[NSString alloc] initWithUTF8String:file];
            NSString *parentDir = [[NSString alloc] initWithUTF8String:dir];
            NSArray *filteredWatchers = [_dirWatchers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path == %@", parentDir]];
            if (filteredWatchers.count == 1) {
                _PBDirWatcher *parentWatcher = filteredWatchers[0];
                [parentWatcher addSubdir:resDir];
            }
            
            filteredWatchers = [_dirWatchers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path == %@", resDir]];
            if (filteredWatchers.count == 0) {
                // New dir
                _PBDirWatcher *dirMonitor = [[_PBDirWatcher alloc] initWithDir:resDir file:nil delegate:self];
                [_dirWatchers addObject:dirMonitor];
                _handler(resDir, initial, PBDirEventNewFolder);
            }
            
            if (!initial) {
                [subdirs addObject:resDir];
            }
            
            return;
        }
        
        NSString *resDir = [[NSString alloc] initWithUTF8String:dir];
        NSString *resFilePath = [[NSString alloc] initWithUTF8String:file];
        NSArray *filteredWatchers = [_dirWatchers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path == %@", resDir]];
        _PBDirWatcher *dirWatcher;
        if (filteredWatchers.count == 0) {
            // New dir to watch
            dirWatcher = [[_PBDirWatcher alloc] initWithDir:resDir file:resFilePath delegate:self];
            [_dirWatchers addObject:dirWatcher];
            _handler(resDir, initial, PBDirEventNewFolder);
            _handler(resFilePath, initial, PBDirEventNewFile); // notify change
        } else {
            // Old dir had watch
            dirWatcher = filteredWatchers[0];
            _PBMonitorFile *resFile = [dirWatcher fileForPath:resFilePath];
            if (resFile == nil) {
                // New file
                [dirWatcher addFile:resFilePath];
                
                _handler(resFilePath, initial, PBDirEventNewFile); // notify change
            } else {
                // Old file
                if ([resFile updateLastModified]) {
                    // Modified
                    
                    _handler(resFilePath, initial, PBDirEventModifyFile); // notify change
                }
            }
        }
        
        if (!initial) {
            [files addObject:resFilePath];
        }
    });
    
    if (!initial) {
        // Check if any directory be deleted.
        NSArray *deletedDirs = [watcher updateSubdirs:subdirs];
        if (deletedDirs != nil) {
            // Unwatch
            NSArray *filters = [_dirWatchers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path in %@", deletedDirs]];
            for (_PBDirWatcher *watcher in filters) {
                [watcher invalidate];
            }
            [_dirWatchers removeObjectsInArray:filters];
            
            // Notify change
            for (NSString *dir in deletedDirs) {
                _handler(dir, initial, PBDirEventDeleteFolder);
            }
        }
        
        // Check if any file be deleted.
        NSArray *deletedFiles = [watcher updateFiles:files];
        if (deletedFiles != nil) {
            for (NSString *file in deletedFiles) {
                _handler(file, initial, PBDirEventDeleteFile);
            }
        }
    }
}

- (void)directoryDidChange:(_PBDirWatcher *)watcher {
    [self scan:watcher.path watcher:watcher];
}

- (void)dealloc
{
    _dirWatchers = nil;
    _handler = nil;
}

@end

//

@implementation _PBMonitorFile

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        _path = path;
        _lastModified = [self currentLastModified];
    }
    return self;
}

- (BOOL)updateLastModified
{
    NSTimeInterval currentLastModified = [self currentLastModified];
    if (_lastModified != currentLastModified) {
        _lastModified = currentLastModified;
        return YES;
    }
    return NO;
}

- (NSTimeInterval)currentLastModified
{
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:_path error:&error];
    NSTimeInterval lastModified = 0;
    if (error == nil) {
        lastModified = [[attrs fileModificationDate] timeIntervalSince1970];
    }
    return lastModified;
}

@end

// Directory watcher
// @see https://developer.apple.com/library/content/samplecode/DocInteraction/Listings/Classes_DirectoryWatcher_m.html

@implementation _PBDirWatcher {
    int                 kq;
    int                 dirFD;
    CFFileDescriptorRef dirKQRef;
    __weak id<_PBDirWatcherDelegate> delegate;
    NSMutableArray<NSString *>       *subdirs;
    NSMutableArray<_PBMonitorFile *> *files;
}

static void KQCallback(CFFileDescriptorRef kqRef, CFOptionFlags callBackTypes, void *info) {
    _PBDirWatcher* obj = (__bridge _PBDirWatcher*) info;
    
    assert([obj isKindOfClass:[_PBDirWatcher class]]);
    assert(kqRef == obj->dirKQRef);
    assert(callBackTypes == kCFFileDescriptorReadCallBack);
    
    [obj kqueueFired];
}

- (instancetype)initWithDir:(NSString *)dir file:(NSString *)file delegate:(id<_PBDirWatcherDelegate>)aDelegate
{
    if (self = [super init]) {
        kq = -1;
        dirFD = -1;
        delegate = aDelegate;
        
        _path = dir;
        files = [[NSMutableArray alloc] init];
        if (file != nil) {
            _PBMonitorFile *resFile = [[_PBMonitorFile alloc] initWithPath:file];
            [files addObject:resFile];
        }
        [self start];
    }
    return self;
}

- (void)addSubdir:(NSString *)dir
{
    if (subdirs == nil) {
        subdirs = [[NSMutableArray alloc] init];
    }
    [subdirs addObject:dir];
}

- (void)addFile:(NSString *)file
{
    _PBMonitorFile *resFile = [[_PBMonitorFile alloc] initWithPath:file];
    [files addObject:resFile];
}

- (_PBMonitorFile *)fileForPath:(NSString *)path
{
    NSArray *filteredFiles = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path==%@", path]];
    if (filteredFiles.count == 0) {
        return nil;
    }
    return filteredFiles[0];
}

- (NSArray<NSString *> *)updateSubdirs:(NSArray<NSString *> *)the_subdirs
{
    if (subdirs == nil) return nil;
    
    NSArray *filters = [subdirs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", the_subdirs]];
    if (filters.count > 0) {
        [subdirs removeObjectsInArray:filters];
        return filters;
    }
    
    return nil;
}

- (NSArray<NSString *> *)updateFiles:(NSArray<NSString *> *)the_files
{
    if (files == nil) return nil;
    
    NSArray *filters = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT path IN %@", the_files]];
    if (filters.count > 0) {
        [files removeObjectsInArray:filters];
        return [filters valueForKey:@"path"];
    }
    
    return nil;
}

- (void)dealloc {
    [self invalidate];
}

- (void)kqueueFired {
    assert(kq >= 0);
    
    struct kevent   event;
    struct timespec timeout = {0, 0};
    int             eventCount;
    
    eventCount = kevent(kq, NULL, 0, &event, 1, &timeout);
    assert((eventCount >= 0) && (eventCount < 2));
    
    // call our delegate of the directory change
    [delegate directoryDidChange:self];
    
    CFFileDescriptorEnableCallBacks(dirKQRef, kCFFileDescriptorReadCallBack);
}

- (void)start {
    // Double initializing is not going to work...
    if (dirKQRef != NULL) return;
    if (dirFD != -1) return;
    if (kq != -1) return;
    
    if (_path == nil) return;
    
    // Open the directory we're going to watch
    dirFD = open([_path fileSystemRepresentation], O_EVTONLY);
    if (dirFD < 0) return;
    
    // Create a kqueue for our event messages...
    kq = kqueue();
    if (kq < 0) {
        close(dirFD);
        return;
    }
    
    struct kevent eventToAdd;
    eventToAdd.ident  = dirFD;
    eventToAdd.filter = EVFILT_VNODE;
    eventToAdd.flags  = EV_ADD | EV_CLEAR;
    eventToAdd.fflags = NOTE_WRITE;
    eventToAdd.data   = 0;
    eventToAdd.udata  = NULL;
    
    int errNum = kevent(kq, &eventToAdd, 1, NULL, 0, NULL);
    if (errNum != 0) {
        close(kq);
        close(dirFD);
        return;
    }
    
    // Passing true in the third argument so CFFileDescriptorInvalidate will close kq.
    CFFileDescriptorContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    dirKQRef = CFFileDescriptorCreate(NULL, kq, true, KQCallback, &context);
    if (dirKQRef == NULL) {
        close(kq);
        close(dirFD);
        return;
    }
    
    // Spin out a pluggable run loop source from the CFFileDescriptorRef
    // Add it to the current run loop, then release it
    CFRunLoopSourceRef rls = CFFileDescriptorCreateRunLoopSource(NULL, dirKQRef, 0);
    if (rls == NULL) {
        CFRelease(dirKQRef);
        close(kq);
        close(dirFD);
        dirKQRef = NULL;
        return;
    }
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease(rls);
    CFFileDescriptorEnableCallBacks(dirKQRef, kCFFileDescriptorReadCallBack);
}

- (void)invalidate
{
    if (dirKQRef != NULL) {
        CFFileDescriptorInvalidate(dirKQRef);
        CFRelease(dirKQRef);
        dirKQRef = NULL;
        // We don't need to close the kq, CFFileDescriptorInvalidate closed it instead.
        // Change the value so no one thinks it's still live.
        kq = -1;
    }
    
    if (dirFD != -1) {
        close(dirFD);
        dirFD = -1;
    }
}

@end

#pragma mark -
#pragma mark - Directory walker with pure C.

static int walk_dir_sub(const char *path, int depth_limit, int depth, file_handler handler) {
    DIR *d;
    struct dirent *file;
    struct stat sb;
    char current[256];
    int next_depth = depth + 1;
    
    if (!(d = opendir(path))) {
        NSLog(@"error opendir %s!", path);
        return -1;
    }
    
    while ((file = readdir(d)) != NULL) {
        const char *name = file->d_name;
        if (*name == '.') {
            continue;
        }
        
        sprintf(current, "%s/%s", path, name);
        if (stat(current, &sb) < 0) {
            continue;
        }
        
        if (S_ISDIR(sb.st_mode)) {
            handler(path, current, name, true);
            if (depth_limit == next_depth) {
                continue;
            }
            
            walk_dir_sub(current, depth_limit, next_depth, handler);
            continue;
        }
        
        handler(path, current, name, false);
    }
    
    closedir(d);
    
    return 0;
}

static int walk_dir(const char *path, int depth_limit, file_handler handler) {
    return walk_dir_sub(path, depth_limit, 0, handler);
}

#endif
