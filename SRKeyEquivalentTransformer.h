//
//  SRKeyEquivalentTransformer.h
//  ShortcutRecorder
//
//  Copyright 2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

#import <Foundation/Foundation.h>


/*!
    @brief  Transform dictionary representation of shortcut into string suitable
            for -setKeyEquivalent: of various Cocoa classes (e.g. NSButton).
 */
@interface SRKeyEquivalentTransformer : NSValueTransformer

@end
