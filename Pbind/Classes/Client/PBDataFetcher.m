//
//  PBDataFetcher.m
//  Pods
//
//  Created by Galen Lin on 02/01/2017.
//
//

#import "PBDataFetcher.h"
#import "PBDataFetching.h"
#import "PBArray.h"
#import "UIView+Pbind.h"

NSString *const PBViewDidStartLoadNotification = @"PBViewDidStartLoadNotification";
NSString *const PBViewDidFinishLoadNotification = @"PBViewDidFinishLoadNotification";
NSString *const PBViewHasHandledLoadErrorKey = @"PBViewHasHandledLoadError";

@interface PBClient (Private)

- (void)_loadRequest:(PBRequest *)request mapper:(PBClientMapper *)mapper notifys:(BOOL)notifys complection:(void (^)(PBResponse *))complection;

@end

@implementation PBDataFetcher

- (void)fetchData {
    [self fetchDataWithTransformation:nil];
}

- (void)fetchDataWithTransformation:(id (^)(id data, NSError *error))transformation {
    if ([_owner isFetching] || _owner.clients == nil) {
        return;
    }
    
    _owner.fetching = YES;
    
    // Init clients
    NSInteger clientCount = _owner.clients.count;
    if (self.clientMappers == nil) {
        NSMutableArray *mappers = [NSMutableArray arrayWithCapacity:clientCount];
        NSMutableArray *clients = [NSMutableArray arrayWithCapacity:clientCount];
        
        for (NSDictionary *info in _owner.clients) {
            PBClientMapper *mapper = [PBClientMapper mapperWithDictionary:info owner:nil];
            [mappers addObject:mapper];
            
            PBClient *client = [PBClient clientWithName:mapper.clazz];
            client.delegate = self;
            [clients addObject:client];
        }
        
        self.clientMappers = mappers;
        self.clients = clients;
    }
    
    // Notify loading start
    [[NSNotificationCenter defaultCenter] postNotificationName:PBViewDidStartLoadNotification object:self];
    
    // Unbind
    [_owner pb_unbindAll];
    
    // Init null data
    if (_owner.data == nil) {
        _owner.data = [PBArray arrayWithCapacity:self.clients.count];
        for (NSInteger i = 0; i < clientCount; i++) {
            [_owner.data addObject:[NSNull null]];
        }
    }
    
    // Fetch data parallelly
    __block NSInteger fetchingCount = clientCount;
    for (NSInteger i = 0; i < clientCount; i++) {
        PBClient *client = [self.clients objectAtIndex:i];
        [client cancel];
        
        PBClientMapper *mapper = [self.clientMappers objectAtIndex:i];
        [mapper updateWithData:_owner.data andView:_owner];
        
        Class requestClass = [client.class requestClass];
        PBRequest *request = [[requestClass alloc] init];
        request.action = mapper.action;
        request.params = mapper.params;
        request.requiresMutableResponse = mapper.mutable;
        
        if ([_owner respondsToSelector:@selector(view:shouldLoadRequest:)]) {
            BOOL flag = [_owner view:self shouldLoadRequest:request];
            if (!flag) {
                continue;
            }
        }
        
        if ([_owner.loadingDelegate respondsToSelector:@selector(view:shouldLoadRequest:)]) {
            BOOL flag = [_owner.loadingDelegate view:self shouldLoadRequest:request];
            if (!flag) {
                continue;
            }
        }
        
        [client _loadRequest:request mapper:nil notifys:NO complection:^(PBResponse *response) {
            BOOL handledError = NO;
            if ([_owner respondsToSelector:@selector(view:didFinishLoading:handledError:)]) {
                [_owner view:self didFinishLoading:response handledError:&handledError];
            }
            if ([_owner.loadingDelegate respondsToSelector:@selector(view:didFinishLoading:handledError:)]) {
                [_owner.loadingDelegate view:self didFinishLoading:response handledError:&handledError];
            }
            NSDictionary *userInfo = nil;
            if (response != nil) {
                userInfo = @{PBResponseKey:response, PBViewHasHandledLoadErrorKey:@(handledError)};
            } else {
                userInfo = @{PBViewHasHandledLoadErrorKey:@(handledError)};
            }
            
            id data = response.data;
            if (transformation) {
                data = transformation(data, response.error);
            }
            if (data == nil) {
                data = [NSNull null];
            }
            
            _owner.data[i] = data;
            _owner.dataUpdated = YES;
            
            // Map data
            [_owner pb_mapData:_owner.rootData underType:PBMapToData dataTag:i];
            [_owner layoutIfNeeded];
            
            fetchingCount--;
            if (fetchingCount == 0) {
                _owner.fetching = NO;
                
                // Notify loading finish
                [[NSNotificationCenter defaultCenter] postNotificationName:PBViewDidFinishLoadNotification object:self userInfo:userInfo];
            }
        }];
    }
}

- (void)refetchData {
    [self fetchData];
}

- (void)cancel {
    if (self.clients == nil) {
        return;
    }
    
    for (PBClient *client in self.clients) {
        [client cancel];
    }
    self.owner.fetching = NO;
}

@end
