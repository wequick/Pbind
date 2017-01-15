//
//  PBClientMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/9/2.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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

#pragma mark - Client Creating
///=============================================================================
/// @name Client Creating
///=============================================================================

/** The class name of the PBClient. */
@property (nonatomic, strong) NSString *clazz;

/** Load the request in parallel mode. Default is YES. */
@property (nonatomic, assign) BOOL parallel;

#pragma mark - Request Creating
///=============================================================================
/// @name Request Creating
///=============================================================================

/** The action of the PBRequest which will be loaded by the PBClient. */
@property (nonatomic, strong) NSString *action;

/** The parameters of the PBRequest which will be loaded by the PBClient. */
@property (nonatomic, strong) NSDictionary *params;

/** The user info for the PBRequest to carry. */
@property (nonatomic, strong) NSDictionary *userInfo;

#pragma mark - Resulting
///=============================================================================
/// @name Resulting
///=============================================================================

/** Whether convert the response dat to be mutable after fetching. Default is NO. */
@property (nonatomic, assign) BOOL mutable;

@end
