//
//  SRValidator.h
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
//      Silvio Rizzi
//      Ilya Kulakov

#import "SRValidator.h"
#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"


@implementation SRValidator

- (instancetype)initWithDelegate:(NSObject<SRValidatorDelegate> *)aDelegate;
{
    self = [super init];

    if (self != nil)
    {
        _delegate = aDelegate;
    }

    return self;
}

- (instancetype)init
{
    return [self initWithDelegate:nil];
}


#pragma mark Methods

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagsTaken:(NSUInteger)aFlags error:(NSError **)outError;
{
    if ([self isKeyCode:aKeyCode andFlagTakenInDelegate:aFlags error:outError])
        return YES;

    if ((![self.delegate respondsToSelector:@selector(shortcutValidatorShouldCheckSystemShortcuts:)] ||
         [self.delegate shortcutValidatorShouldCheckSystemShortcuts:self]) &&
        [self isKeyCode:aKeyCode andFlagsTakenInSystemShortcuts:aFlags error:outError])
    {
        return YES;
    }

    if ((![self.delegate respondsToSelector:@selector(shortcutValidatorShouldCheckMenu:)] ||
         [self.delegate shortcutValidatorShouldCheckMenu:self]) &&
        [self isKeyCode:aKeyCode andFlags:aFlags takenInMenu:[NSApp mainMenu] error:outError])
    {
        return YES;
    }

    return NO;
}

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagTakenInDelegate:(NSUInteger)aFlags error:(NSError **)outError
{
    if (self.delegate != nil)
    {
        NSString *delegateReason = nil;
        if ([self.delegate respondsToSelector:@selector(shortcutValidator:isKeyCode:andFlagsTaken:reason:)] &&
            [self.delegate shortcutValidator:self
                                   isKeyCode:aKeyCode
                               andFlagsTaken:aFlags
                                      reason:&delegateReason])
        {
            if (outError != NULL)
            {
                BOOL isASCIIOnly = NO;

                if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                    isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode) : SRReadableStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode);
                NSString *description = [NSString stringWithFormat:
                                         SRLoc(@"The key combination %@ can't be used!"),
                                         shortcut];
                NSString *recoverySuggestion = [NSString stringWithFormat:
                                                SRLoc(@"The key combination \"%@\" can't be used because %@."),
                                                shortcut,
                                                [delegateReason length] ? delegateReason : @"it's already used"];
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey : description,
                    NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
                    NSLocalizedRecoveryOptionsErrorKey: @[@"OK"]
                };
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
            }

            return YES;
        }
    }

    return NO;
}

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagsTakenInSystemShortcuts:(NSUInteger)aFlags error:(NSError **)outError
{
    CFArrayRef s = NULL;
    OSStatus err = CopySymbolicHotKeys(&s);

    if (err != noErr)
        return YES;

    NSArray *symbolicHotKeys = (NSArray *)CFBridgingRelease(s);
    aFlags &= SRCocoaModifierFlagsMask;

    for (NSDictionary *symbolicHotKey in symbolicHotKeys)
    {
        if ((__bridge CFBooleanRef)[symbolicHotKey objectForKey:(__bridge NSString *)kHISymbolicHotKeyEnabled] != kCFBooleanTrue)
            continue;

        unsigned short symbolicHotKeyCode = [[symbolicHotKey objectForKey:(__bridge NSString *)kHISymbolicHotKeyCode] integerValue];

        if (symbolicHotKeyCode == aKeyCode)
        {
            NSUInteger symbolicHotKeyFlags = [[symbolicHotKey objectForKey:(__bridge NSString *)kHISymbolicHotKeyModifiers] unsignedIntegerValue];
            symbolicHotKeyFlags &= SRCarbonModifierFlagsMask;

            if (SRCarbonToCocoaFlags(symbolicHotKeyFlags) == aFlags)
            {
                if (outError != NULL)
                {
                    BOOL isASCIIOnly = NO;

                    if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                        isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                    NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode) : SRReadableStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode);
                    NSString *description = [NSString stringWithFormat:
                                             SRLoc(@"The key combination %@ can't be used!"),
                                             shortcut];
                    NSString *recoverySuggestion = [NSString stringWithFormat:
                                                    SRLoc(@"The key combination \"%@\" can't be used because it's already used by a system-wide keyboard shortcut. (If you really want to use this key combination, most shortcuts can be changed in the Keyboard panel in System Preferences.)"),
                                                    shortcut];
                    NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey: description,
                        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
                        NSLocalizedRecoveryOptionsErrorKey: @[@"OK"]
                    };
                    *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
                }

                return YES;
            }
        }
    }

    return NO;
}

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlags:(NSUInteger)aFlags takenInMenu:(NSMenu *)aMenu error:(NSError **)outError
{
    aFlags &= SRCocoaModifierFlagsMask;

    for (NSMenuItem *menuItem in [aMenu itemArray])
    {
        if (menuItem.hasSubmenu && [self isKeyCode:aKeyCode andFlags:aFlags takenInMenu:menuItem.submenu error:outError])
            return YES;

        NSString *keyEquivalent = menuItem.keyEquivalent;

        if ([keyEquivalent length] == 0)
            continue;

        NSUInteger keyEquivalentModifierMask = menuItem.keyEquivalentModifierMask;

        // Shift flag may be set implicitly if key equivalent is uppercased character.
        if (![[keyEquivalent lowercaseString] isEqualToString:[keyEquivalent uppercaseString]] &&
            [[keyEquivalent uppercaseString] isEqualToString:keyEquivalent])
        {
            keyEquivalent = [keyEquivalent lowercaseString];
            keyEquivalentModifierMask |= NSShiftKeyMask;
        }

        if ((keyEquivalentModifierMask & SRCocoaModifierFlagsMask) == aFlags)
        {
            NSString *keyCodeASCIIRepresentation = [[SRKeyCodeTransformer sharedASCIITransformer] transformedValue:@(aKeyCode)];
            NSString *keyCodeCurrentLayoutRepresentation = [[SRKeyCodeTransformer sharedTransformer] transformedValue:@(aKeyCode)];

            if ([keyEquivalent isEqual:keyCodeASCIIRepresentation] ||
                [keyEquivalent isEqualToString:keyCodeCurrentLayoutRepresentation])
            {
                if (outError != NULL)
                {
                    BOOL isASCIIOnly = NO;

                    if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                        isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                    NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode) : SRReadableStringForCocoaModifierFlagsAndKeyCode(aFlags, aKeyCode);
                    NSString *description = [NSString stringWithFormat:
                                             SRLoc(@"The key combination %@ can't be used!"),
                                             shortcut];
                    NSString *recoverySuggestion = [NSString stringWithFormat:
                                                    SRLoc(@"The key combination \"%@\" can't be used because it's already used by the menu item \"%@\"."),
                                                    shortcut,
                                                    menuItem.title];
                    NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey: description,
                        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
                        NSLocalizedRecoveryOptionsErrorKey: @[@"OK"]
                    };
                    *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
                }

                return YES;
            }
        }
    }

    return NO;
}

@end
