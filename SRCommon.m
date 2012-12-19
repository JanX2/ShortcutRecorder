//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim
//      Ilya Kulakov

#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"


NSString *SRReadableStringForCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, NSInteger aKeyCode)
{
    return [NSString stringWithFormat:@"%@%@%@%@%@",
                                      (aModifierFlags & NSCommandKeyMask ? SRLoc(@"Command-") : @""),
                                      (aModifierFlags & NSAlternateKeyMask ? SRLoc(@"Option-") : @""),
                                      (aModifierFlags & NSControlKeyMask ? SRLoc(@"Control-") : @""),
                                      (aModifierFlags & NSShiftKeyMask ? SRLoc(@"Shift-") : @""),
                                      [[[SRKeyCodeTransformer sharedPlainTransformer] transformedValue:@(aKeyCode)] uppercaseString]];
}


NSString *SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, NSInteger aKeyCode)
{
    return [NSString stringWithFormat:@"%@%@%@%@%@",
                                      (aModifierFlags & NSCommandKeyMask ? SRLoc(@"Command-") : @""),
                                      (aModifierFlags & NSAlternateKeyMask ? SRLoc(@"Option-") : @""),
                                      (aModifierFlags & NSControlKeyMask ? SRLoc(@"Control-") : @""),
                                      (aModifierFlags & NSShiftKeyMask ? SRLoc(@"Shift-") : @""),
                                      [[[SRKeyCodeTransformer sharedPlainASCIITransformer] transformedValue:@(aKeyCode)] uppercaseString]];
}
