//
//  SRModifierFlagsTransformer.h
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>


/*!
    @brief  Transforms mask of Cocoa modifier flags to string of unicode characters.
 */
@interface SRModifierFlagsTransformer : NSValueTransformer

/*!
    @brief  Returns the shared transformer.
 */
+ (instancetype)sharedTransformer;

@end
