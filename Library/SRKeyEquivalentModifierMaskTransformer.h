//
//  SRKeyEquivalentModifierMaskTransformer.h
//  ShortcutRecorder
//
//  Copyright 2012-2018 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

#import <Foundation/Foundation.h>


/*!
    Transform dictionary representation of a shortcut into a string suitable
    for -setKeyEquivalentModifierMask: of Cocoa objects such as NSButton and NSMenuItem.
 */
NS_SWIFT_NAME(KeyEquivalentModifierMaskTransformer)
@interface SRKeyEquivalentModifierMaskTransformer : NSValueTransformer

/*!
    Shared transformer.
 */
@property (class, readonly) SRKeyEquivalentModifierMaskTransformer *sharedTransformer;

@end
