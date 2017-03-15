//
//  PBLLRemoteWatcher.m
//  Pbind
//
//  Created by Galen Lin on 15/03/2017.
//

#import "PBLLRemoteWatcher.h"

#if (DEBUG && !(TARGET_IPHONE_SIMULATOR))

#import "NSInputStream+Reader.h"

@interface PBLLRemoteWatcher () <NSStreamDelegate>
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    void (^responseBlock)(NSData *);
    BOOL streamOpened;
    NSData *apiReqData;
    NSString *tempResourcesPath;
    NSString *connectedIP;
}

@end

@implementation PBLLRemoteWatcher

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
    
    connectedIP = ip;
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, 8082, &readStream, &writeStream);
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
    NSString *ip = [[NSUserDefaults standardUserDefaults] objectForKey:@"pbind.server.ip"];
    if (ip == nil) {
        ip = @"192.168.1.2";
    }
    [self connect:ip];
}

- (void)requestAPI:(NSString *)api success:(void (^)(NSData *))success failure:(void (^)(NSError *))failure {
    if (inputStream == nil) {
        failure([NSError errorWithDomain:@"PBLLRemoteWatcher"
                                    code:1
                                userInfo:@{NSLocalizedDescriptionKey: @"Watcher wasn't online!"}]);
        return;
    }
    
    responseBlock = success;
    NSData *data = [api dataUsingEncoding:NSUTF8StringEncoding];
    if (streamOpened) {
        [outputStream write:[data bytes] maxLength:[data length]];
    } else {
        apiReqData = data;
    }
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

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    NSLog(@"socket: %i, %@", (int)eventCode, aStream);
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            
            break;
        case NSStreamEventHasSpaceAvailable:
            if (aStream == outputStream) {
                streamOpened = YES;
                if (apiReqData != nil) {
                    [outputStream write:[apiReqData bytes] maxLength:[apiReqData length]];
                    apiReqData = nil;
                }
            }
            break;
        case NSStreamEventHasBytesAvailable:
            if (aStream == inputStream) {
                NSLog(@"inputStream is ready.");
                
                uint8_t type[1];
                [inputStream read:type maxLength:1];
                switch (*type) {
                    case 0xE0: { // Got json
                        NSData *jsonData = [inputStream readData];
                        if (responseBlock != nil) {
                            responseBlock(jsonData);
                        }
                        break;
                    }
                    case 0xF0: { // Create file
                        NSString *fileName = [inputStream readString];
                        [self.delegate remoteWatcher:self didCreateFile:fileName];
                        break;
                    }
                    case 0xF1: { // Update file
                        NSString *fileName = [inputStream readString];
                        NSData *fileData = [inputStream readData];
                        [self.delegate remoteWatcher:self didUpdateFile:fileName withData:fileData];
                        break;
                    }
                    case 0xF2: { // Delete file
                        NSString *fileName = [inputStream readString];
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
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self connect:connectedIP];
                });
            }
            break;
        case NSStreamEventEndEncountered:
            if (aStream == inputStream) {
                [self close];
            }
            break;
        default:
            break;
    }
}

@end

#endif
