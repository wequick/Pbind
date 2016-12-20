//
//  PBClientAction.m
//  Pbind
//
//  Created by Galen Lin on 2016/12/15.
//
//

#import "PBClientAction.h"
#import "PBClient.h"

@interface PBClient (Private)

- (void)_loadRequest:(PBRequest *)request mapper:(PBClientMapper *)mapper notifys:(BOOL)notifys complection:(void (^)(PBResponse *))complection;

@end

@implementation PBClientAction

@compatibility_alias _PBAction PBAction;

@pbactions(@"get",
           @"post",
           @"put",
           @"patch",
           @"delete",
           @"head")
- (void)run:(PBActionState *)state {
    PBClient *client = [PBClient clientWithName:self.target];
    if (client == nil) {
        return;
    }
    
    PBRequest *request = [[PBRequest alloc] init];
    request.method = [self.type uppercaseString];
    request.params = [state mergedParams:self.params];
    request.action = self.name;
    
    [client _loadRequest:request mapper:nil notifys:YES complection:^(PBResponse *response) {
        if (response.error != nil) {
            state.error = response.error;
            [self dispatchNext:@"failure"];
        } else {
            state.data = response.data;
            [self dispatchNext:@"success"];
        }
    }];
}

@end
