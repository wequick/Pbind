//
//  PBViewResizing.h
//  Pods
//
//  Created by galen on 17/6/19.
//
//

#import <Foundation/Foundation.h>
#import "PBViewResizingDelegate.h"

@protocol PBViewResizing <NSObject>

#pragma mark - AutoResizing
///=============================================================================
/// @name AutoResizing
///=============================================================================

/**
 Whether resizes frame by content automatically.
 
 @discussion Default is NO. If set to YES will reset the frame on content size changed.
 */
@property (nonatomic, assign, getter=isAutoResize) BOOL autoResize;

/** The delegate used to notify frame changes */
@property (nonatomic, weak) id<PBViewResizingDelegate> resizingDelegate;

@end
