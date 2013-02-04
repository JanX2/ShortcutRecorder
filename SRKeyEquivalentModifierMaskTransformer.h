//
//  SRKeyEquivalentModifierMaskTransformer.h
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
    @brief      Transform dictionary representation of shortcut into string suitable
                for -setKeyEquivalentModifierMask: of various Cocoa classes (e.g. NSButton).

    @discussion If shortcut's key code is special, returned mask will contain NSShiftKeyMask.
                Otherwise it's responsibility of key code -> key equivalent transformer to return uppercased string.
 */
@interface SRKeyEquivalentModifierMaskTransformer : NSValueTransformer

@end
