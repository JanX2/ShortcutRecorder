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


NSString *SRReadableStringForCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, unsigned short aKeyCode)
{
    SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedPlainTransformer];
    NSString *c = [t transformedValue:@(aKeyCode)];

    return [NSString stringWithFormat:@"%@%@%@%@%@",
                                      (aModifierFlags & NSCommandKeyMask ? SRLoc(@"Command-") : @""),
                                      (aModifierFlags & NSAlternateKeyMask ? SRLoc(@"Option-") : @""),
                                      (aModifierFlags & NSControlKeyMask ? SRLoc(@"Control-") : @""),
                                      (aModifierFlags & NSShiftKeyMask ? SRLoc(@"Shift-") : @""),
                                      c];
}


NSString *SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, unsigned short aKeyCode)
{
    SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedPlainASCIITransformer];
    NSString *c = [t transformedValue:@(aKeyCode)];

    return [NSString stringWithFormat:@"%@%@%@%@%@",
            (aModifierFlags & NSCommandKeyMask ? SRLoc(@"Command-") : @""),
            (aModifierFlags & NSAlternateKeyMask ? SRLoc(@"Option-") : @""),
            (aModifierFlags & NSControlKeyMask ? SRLoc(@"Control-") : @""),
            (aModifierFlags & NSShiftKeyMask ? SRLoc(@"Shift-") : @""),
            c];
}


BOOL SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(unsigned short aKeyCode,
                                                     NSUInteger aKeyCodeFlags,
                                                     NSString *aKeyEquivalent,
                                                     NSUInteger aKeyEquivalentModifierFlags)
{
    if (!aKeyEquivalent)
        return NO;

    aKeyCodeFlags &= SRCocoaModifierFlagsMask;
    aKeyEquivalentModifierFlags &= SRCocoaModifierFlagsMask;

    if (aKeyCodeFlags == aKeyEquivalentModifierFlags)
    {
        NSString *keyCodeASCIIRepresentation = [[SRKeyCodeTransformer sharedASCIITransformer] transformedValue:@(aKeyCode)
                                                                                     withImplicitModifierFlags:nil
                                                                                         explicitModifierFlags:@(aKeyCodeFlags)];

        if ([keyCodeASCIIRepresentation isEqual:aKeyEquivalent])
            return YES;
        else
        {
            // Developer can set key equivalet to unicode using native layout (e.g. Russian).
            NSString *keyCodeCurrentLayoutRepresentation = [[SRKeyCodeTransformer sharedTransformer] transformedValue:@(aKeyCode)
                                                                                            withImplicitModifierFlags:nil
                                                                                                explicitModifierFlags:@(aKeyCodeFlags)];
            return [keyCodeCurrentLayoutRepresentation isEqual:aKeyEquivalent];
        }
    }
    else if (!aKeyEquivalentModifierFlags ||
             (aKeyCodeFlags & aKeyEquivalentModifierFlags) == aKeyEquivalentModifierFlags)
    {
        // Some key equivalent modifier flags can be implicitly set by using special unicode characters. E.g. Œ insetead of opt-a.
        // Only check aKeyCodeFlags is equal to aKeyEquivalentModifierFlags, aKeyEquivalentModifierFlags is not set
        // or aKeyCodeFlags contains aKeyEquivalentModifierFlags.
        // E.g. ctrl-Œ/ctrl-opt-a and Œ/opt-a match this condition, but cmd-Œ/ctrl-opt-a doesn't.
        NSUInteger possiblyImplicitFlags = aKeyCodeFlags & ~aKeyEquivalentModifierFlags;
        NSString *keyCodeASCIIRepresentation = [[SRKeyCodeTransformer sharedASCIITransformer] transformedValue:@(aKeyCode)
                                                                                     withImplicitModifierFlags:@(possiblyImplicitFlags)
                                                                                         explicitModifierFlags:@(aKeyEquivalentModifierFlags)];

        if ([keyCodeASCIIRepresentation isEqual:aKeyEquivalent])
            return YES;
        else
        {
            NSString *keyCodeCurrentLayoutRepresentation = [[SRKeyCodeTransformer sharedTransformer] transformedValue:@(aKeyCode)
                                                                                            withImplicitModifierFlags:@(possiblyImplicitFlags)
                                                                                                explicitModifierFlags:@(aKeyEquivalentModifierFlags)];
            return [keyCodeCurrentLayoutRepresentation isEqual:aKeyEquivalent];
        }
    }
    else
        return NO;
}
