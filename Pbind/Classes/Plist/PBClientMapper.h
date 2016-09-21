//
//  PBClientMapper.h
//  Pbind
//
//  Created by Galen Lin on 16/9/2.
//  Copyright © 2016年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBMapper.h"

@class PBClient;

/**
 This class stores the properties of a PBClient.
 
 @discussion Used for mapping the `clients` in Plist:
 
     <key>clients</key>
     <array>
        <dict>
            <key>clazz</key>
             <string>PBExampleClient</string>
             <key>action</key>
             <string>GetGroupInfo</string>
             <key>params</key>
             <string>@groupParams</string>
        </dict>
        <dict>
             <key>clazz</key>
             <string>PBExampleClient</string>
             <key>action</key>
             <string>GetGroupMembers</string>
             <key>params</key>
             <string>@groupParams</string>
        </dict>
     </array>

 */
@interface PBClientMapper : PBMapper

#pragma mark - Creating
///=============================================================================
/// @name Creating
///=============================================================================

/** The class name of the PBClient. */
@property (nonatomic, strong) NSString *clazz;

/** The action of the PBRequest which will be loaded by the PBClient. */
@property (nonatomic, strong) NSString *action;

/** The parameters of the PBRequest which will be loaded by the PBClient. */
@property (nonatomic, strong) NSDictionary *params;

/** Load the request in parallel mode. Default is YES. */
@property (nonatomic, assign) BOOL parallel;

#pragma mark - Resulting
///=============================================================================
/// @name Resulting
///=============================================================================

/**
 The presenting tips on request succeed.
 
 @discussion This tips will be passed to PBClientDidLoadRequestNotification as `PBResponse.tips`.
 
 Example:
 
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientDidLoadRequest:) name:PBClientDidLoadRequestNotification object:nil];
     
     + (void)clientDidLoadRequest:(NSNotification *)note {
         PBResponse *response = note.userInfo[PBResponseKey];
         NSString *tips = response.tips;
         if (response.error != nil) {
             if (tips == nil) {
                 tips = [response.error localizedDescription];
             }
         }
         
         // Displays the tips with HUD.
     }
 */
@property (nonatomic, strong) NSString *successTips;

/**
 The presenting tips on request failed.
 
 @see successTips
 */
@property (nonatomic, strong) NSString *failureTips;

/**
 The href will be triggered after the PBClient succeed.
 
 @discussion Triggered by the built-in action `[view pb_clickHref:successHref]`.
 */
@property (nonatomic, strong) NSString *successHref;

/**
 The client will be called on request succeed.
 
 @discussion This will provide the nested loading ability.
 */
@property (nonatomic, strong) PBClient *nextClient;

+ (instancetype)constMapperWithDictionary:(NSDictionary *)dictionary;

@end
