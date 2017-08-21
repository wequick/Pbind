//
//  PBLLRemoteWatcher.m
//  Pbind
//
//  Created by Galen Lin on 15/03/2017.
//

#import "PBLLRemoteWatcher.h"

#if (PBLIVE_ENABLED && !(TARGET_IPHONE_SIMULATOR))

#import "NSInputStream+Reader.h"
#import <UIKit/UIKit.h>

@interface PBLLRemoteWatcher () <NSStreamDelegate>
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    void (^apiSuccessBlock)(NSData *);
    void (^apiFailureBolck)(NSError *);
    BOOL streamOpened;
    NSData *apiReqData;
    NSString *tempResourcesPath;
    NSString *connectedIP;
    NSInteger retryCount;
}

@end

@implementation PBLLRemoteWatcher

static const NSTimeInterval kTimeoutSeconds = 3.f;
static NSString *const kServerIPUserDefaultsKey = @"pbind.server.ip";
static NSString *const kDefaultServerIP = @"192.168.1.10";
static const NSInteger kServerPort = 8082;
static const NSInteger kMaxRetryCount = 5;

+ (instancetype)globalWatcher {
    static PBLLRemoteWatcher *o;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        o = [[PBLLRemoteWatcher alloc] init];
    });
    return o;
}

- (void)connect:(NSString *)ip {
    [self close];
    
    if (ip == nil) {
        return;
    }
    
    connectedIP = ip;
    [[NSUserDefaults standardUserDefaults] setObject:ip forKey:kServerIPUserDefaultsKey];
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, kServerPort, &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    inputStream.delegate = self;
    outputStream.delegate = self;
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
}

- (void)connectDefaultIP {
    [self connect:self.defaultIP];
}

- (NSString *)defaultIP {
    NSString *ip = [[NSUserDefaults standardUserDefaults] objectForKey:kServerIPUserDefaultsKey];
    if (ip == nil) {
        ip = kDefaultServerIP;
    }
    return ip;
}

- (void)requestAPI:(NSString *)api success:(void (^)(NSData *))success failure:(void (^)(NSError *))failure {
    if (inputStream == nil) {
        failure([NSError errorWithDomain:@"PBLLRemoteWatcher"
                                    code:1
                                userInfo:@{NSLocalizedDescriptionKey: @"Watcher wasn't online!"}]);
        return;
    }
    
    apiSuccessBlock = success;
    apiFailureBolck = failure;
    
    NSData *reqData = [self dataWithMessage:api event:PBLLRemoteEventJsonRequest];
    if (streamOpened) {
        [self sendData:reqData];
    } else {
//        apiReqData = reqData;
        failure(nil);
        return;
    }
    
    NSLog(@"---- perform delay onTimeout");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onTimeout) object:nil];
    [self performSelector:@selector(onTimeout) withObject:nil afterDelay:kTimeoutSeconds];
}

- (void)onTimeout {
    if (apiFailureBolck) {
        apiFailureBolck([NSError errorWithDomain:@"PBLLRemoteWatcher"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: @"Server no response"}]);
        apiFailureBolck = nil;
    }
    apiSuccessBlock = nil;
}

- (void)close {
    if (inputStream != nil) {
        [inputStream close];
        inputStream = nil;
    }
    if (outputStream != nil) {
        [outputStream close];
        outputStream = nil;
    }
    streamOpened = NO;
}

#pragma mark - Communication

typedef NS_ENUM(NSUInteger, PBLLRemoteEvent) {
    // client events
    PBLLRemoteEventConnected    = 0xC0,
    PBLLRemoteEventJsonRequest  = 0xC1,
    PBLLRemoteEventLog          = 0xC2,
    
    // server events - data
    PBLLRemoteEventDataJson     = 0xD0,
    
    // server events - error
    PBLLRemoteEventErrorIgnored = 0xE0,
    
    // server events - file
    PBLLRemoteEventFileCreated  = 0xF0,
    PBLLRemoteEventFileUpdated  = 0xF1,
    PBLLRemoteEventFileDeleted  = 0xF2,
};

- (void)sendMessage:(NSString *)message {
    NSData *msgData = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:msgData];
}

- (void)sendLog:(NSString *)log {
    [self sendMessage:log event:PBLLRemoteEventLog];
}

- (void)sendConnectedMessage {
    NSString *osModel = [[UIDevice currentDevice] name];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    NSString *deviceName = [NSString stringWithFormat:@"%@(%@)", osModel, osVersion];
    [self sendMessage:deviceName event:PBLLRemoteEventConnected];
}

- (void)sendMessage:(NSString *)message event:(PBLLRemoteEvent)event {
    NSData *data = [self dataWithMessage:message event:event];
    [self sendData:data];
}

- (void)sendData:(NSData *)data {
    if (!streamOpened) {
        return;
    }
    
    [outputStream write:[data bytes] maxLength:[data length]];
}

- (NSData *)dataWithMessage:(NSString *)message event:(PBLLRemoteEvent)event {
    NSData *msgData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger len = msgData.length + 1;
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:len];
    [data appendBytes:&event length:1];
    [data appendData:msgData];
    return data;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasSpaceAvailable:
            if (aStream == outputStream) {
                if (!streamOpened) {
                    streamOpened = YES;
                    
                    [self sendConnectedMessage];
                    
                    if ([self.delegate respondsToSelector:@selector(remoteWatcher:didChangeConnectState:)]) {
                        [self.delegate remoteWatcher:self didChangeConnectState:YES];
                    }
                }
                
//                if (apiReqData != nil) {
//                    [self sendData:apiReqData];
//                    apiReqData = nil;
//                }
            }
            break;
        case NSStreamEventHasBytesAvailable:
            if (aStream == inputStream) {
                uint8_t type[1];
                [inputStream read:type maxLength:1];
                PBLLRemoteEvent event = *type;
                switch (event) {
                    case PBLLRemoteEventDataJson: { // Got json
                        NSString *jsonName = [inputStream readString];
                        NSData *jsonData = [inputStream readData];
                        NSLog(@"---- cancel onTimeout");
                        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onTimeout) object:nil];
                        if (apiSuccessBlock != nil) {
                            apiSuccessBlock(jsonData);
                            apiSuccessBlock = nil;
                        }
                        apiFailureBolck = nil;
                        [self sendMessage:jsonName event:PBLLRemoteEventDataJson];
                        break;
                    }
                    case PBLLRemoteEventErrorIgnored: { // Ingores API
                        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onTimeout) object:nil];
                        if (apiFailureBolck != nil) {
                            apiFailureBolck([NSError errorWithDomain:@"PBLLRemoteWatcher" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"User ignores the API"}]);
                        }
                        apiSuccessBlock = nil;
                        break;
                    }
                    case PBLLRemoteEventFileCreated: { // Create file
                        NSString *fileName = [inputStream readString];
                        if (fileName == nil) {
                            break;
                        }
                        [self sendMessage:fileName event:event];
                        [self.delegate remoteWatcher:self didCreateFile:fileName];
                        break;
                    }
                    case PBLLRemoteEventFileUpdated: { // Update file
                        NSString *fileName = [inputStream readString];
                        if (fileName == nil) {
                            break;
                        }
                        NSData *fileData = [inputStream readData];
                        [self sendMessage:fileName event:event];
                        [self.delegate remoteWatcher:self didUpdateFile:fileName withData:fileData];
                        break;
                    }
                    case PBLLRemoteEventFileDeleted: { // Delete file
                        NSString *fileName = [inputStream readString];
                        if (fileName == nil) {
                            break;
                        }
                        [self sendMessage:fileName event:event];
                        [self.delegate remoteWatcher:self didDeleteFile:fileName];
                        break;
                    }
                    default:
                        break;
                }
            }
            break;
        case NSStreamEventErrorOccurred:
            if (aStream == outputStream) {
                retryCount++;
                if (retryCount >= kMaxRetryCount) {
                    retryCount = 0;
                    break;
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self connect:connectedIP];
                });
            }
            NSLog(@"[PBLLRemoteWatcher] %@", [aStream streamError]);
            break;
        case NSStreamEventEndEncountered:
            if (aStream == inputStream) {
                [self close];
                if ([self.delegate respondsToSelector:@selector(remoteWatcher:didChangeConnectState:)]) {
                    [self.delegate remoteWatcher:self didChangeConnectState:NO];
                }
            }
            break;
        default:
            break;
    }
}

@end

#endif
