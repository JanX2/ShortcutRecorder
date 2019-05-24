//
//  SRShortcut.m
//  ShortcutRecorder.framework
//
//  Copyright 2018 Contributors. All rights reserved.
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"

#import "SRShortcut.h"


SRShortcutKey const SRShortcutKeyKeyCode = @"keyCode";
SRShortcutKey const SRShortcutKeyModifierFlags = @"modifierFlags";
SRShortcutKey const SRShortcutKeyCharacters = @"characters";
SRShortcutKey const SRShortcutKeyCharactersIgnoringModifiers = @"charactersIgnoringModifiers";

NSString *const SRShortcutKeyCode = SRShortcutKeyKeyCode;
NSString *const SRShortcutModifierFlagsKey = SRShortcutKeyModifierFlags;
NSString *const SRShortcutCharacters = SRShortcutKeyCharacters;
NSString *const SRShortcutCharactersIgnoringModifiers = SRShortcutKeyCharactersIgnoringModifiers;


@implementation SRShortcut

+ (instancetype)shortcutWithCode:(unsigned short)aKeyCode
                   modifierFlags:(NSEventModifierFlags)aModifierFlags
                      characters:(NSString *)aCharacters
     charactersIgnoringModifiers:(NSString *)aCharactersIgnoringModifiers
{
    return [[self alloc] initWithCode:aKeyCode
                        modifierFlags:aModifierFlags
                            characters:aCharacters
           charactersIgnoringModifiers:aCharactersIgnoringModifiers];
}

+ (instancetype)shortcutWithEvent:(NSEvent *)aKeyboardEvent
{
    if (((1 << aKeyboardEvent.type) & (NSEventMaskKeyDown | NSEventMaskKeyUp)) == 0)
        [NSException raise:NSInvalidArgumentException format:@"aKeyboardEvent must be either NSEventTypeKeyUp or NSEventTypeKeyDown, got %lu", aKeyboardEvent.type, nil];

    return [self shortcutWithCode:aKeyboardEvent.keyCode
                    modifierFlags:aKeyboardEvent.modifierFlags
                       characters:aKeyboardEvent.characters
      charactersIgnoringModifiers:aKeyboardEvent.charactersIgnoringModifiers];
}

+ (instancetype)shortcutWithDictionary:(NSDictionary *)aDictionary
{
    NSNumber *keyCode = aDictionary[SRShortcutKeyKeyCode];

    if (![keyCode isKindOfClass:NSNumber.class])
        [NSException raise:NSInvalidArgumentException format:@"aDictionary must contain a key code", nil];

    unsigned short keyCodeValue = keyCode.unsignedShortValue;
    NSUInteger modifierFlagsValue = 0;
    NSString *charactersValue = nil;
    NSString *charactersIgnoringModifiersValue = nil;

    NSNumber *modifierFlags = aDictionary[SRShortcutKeyModifierFlags];
    if ((NSNull *)modifierFlags != NSNull.null)
        modifierFlagsValue = modifierFlags.unsignedIntegerValue;

    NSString *characters = aDictionary[SRShortcutKeyCharacters];
    if ((NSNull *)characters != NSNull.null)
        charactersValue = characters;

    NSString *charactersIgnoringModifiers = aDictionary[SRShortcutKeyCharactersIgnoringModifiers];
    if ((NSNull *)charactersIgnoringModifiers != NSNull.null)
        charactersIgnoringModifiersValue = charactersIgnoringModifiers;

    return [self shortcutWithCode:keyCodeValue
                    modifierFlags:modifierFlagsValue
                       characters:charactersValue
      charactersIgnoringModifiers:charactersIgnoringModifiersValue];
}

- (instancetype)initWithCode:(unsigned short)aKeyCode
               modifierFlags:(NSEventModifierFlags)aModifierFlags
                  characters:(NSString *)aCharacters
 charactersIgnoringModifiers:(NSString *)aCharactersIgnoringModifiers
{
    self = [super init];

    if (self)
    {
        _keyCode = aKeyCode;
        _modifierFlags = aModifierFlags & SRCocoaModifierFlagsMask;
        _characters = aCharacters.copy;
        _charactersIgnoringModifiers = aCharactersIgnoringModifiers.copy;
    }

    return self;
}


#pragma mark Properties

- (NSDictionary<SRShortcutKey, id> *)dictionaryRepresentation
{
    return @{
        SRShortcutKeyKeyCode: @(self.keyCode),
        SRShortcutKeyModifierFlags: @(self.modifierFlags),
        SRShortcutKeyCharacters: self.characters ? self.characters : @"",
        SRShortcutKeyCharactersIgnoringModifiers: self.charactersIgnoringModifiers ? self.charactersIgnoringModifiers : @""
    };
}


#pragma mark Methods

- (NSString *)readableStringRepresentation:(BOOL)isASCII
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (isASCII)
        return SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(self.modifierFlags, self.keyCode);
    else
        return SRReadableStringForCocoaModifierFlagsAndKeyCode(self.modifierFlags, self.keyCode);
#pragma clang diagnostic pop
}


#pragma mark Equality

- (BOOL)isEqualToShortcut:(SRShortcut *)aShortcut
{
    if (aShortcut == self)
        return YES;
    else if (![aShortcut isKindOfClass:SRShortcut.class])
        return NO;
    else
        return (aShortcut.keyCode == self.keyCode && aShortcut.modifierFlags == self.modifierFlags);
}

- (BOOL)isEqualToDictionary:(NSDictionary<SRShortcutKey, id> *)aDictionary
{
    if ([aDictionary[SRShortcutKeyKeyCode] isKindOfClass:NSNumber.class])
        return [aDictionary[SRShortcutKeyKeyCode] unsignedShortValue] == self.keyCode && ([aDictionary[SRShortcutKeyModifierFlags] unsignedIntegerValue] & SRCocoaModifierFlagsMask) == self.modifierFlags;
    else
        return NO;
}

- (BOOL)isEqualToKeyEquivalent:(nullable NSString *)aKeyEquivalent withModifierFlags:(NSEventModifierFlags)aModifierFlags
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(self.keyCode, self.modifierFlags, aKeyEquivalent, aModifierFlags);
#pragma clang diagnostic pop
}


#pragma mark Subscript

- (nullable id)objectForKeyedSubscript:(SRShortcutKey)aKey
{
    if ([aKey isEqualToString:SRShortcutKeyKeyCode])
        return @(self.keyCode);
    else if ([aKey isEqualToString:SRShortcutKeyModifierFlags])
        return @(self.modifierFlags);
    else if ([aKey isEqualToString:SRShortcutKeyCharacters])
        return self.characters;
    else if ([aKey isEqualToString:SRShortcutKeyCharactersIgnoringModifiers])
        return self.charactersIgnoringModifiers;
    else
        return nil;
}


#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)aZone
{
    // SRShortcut is immutable.
    return self;
}


#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithCode:[[aDecoder decodeObjectOfClass:NSNumber.class forKey:SRShortcutKeyKeyCode] unsignedShortValue]
                modifierFlags:[[aDecoder decodeObjectOfClass:NSNumber.class forKey:SRShortcutKeyModifierFlags] unsignedIntegerValue]
                   characters:[aDecoder decodeObjectOfClass:NSString.class forKey:SRShortcutKeyCharacters]
  charactersIgnoringModifiers:[aDecoder decodeObjectOfClass:NSString.class forKey:SRShortcutKeyCharactersIgnoringModifiers]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:SRBundle().infoDictionary[(__bridge NSString *)kCFBundleVersionKey] forKey:@"version"];
    [aCoder encodeObject:@(self.keyCode) forKey:SRShortcutKeyKeyCode];
    [aCoder encodeObject:@(self.modifierFlags) forKey:SRShortcutKeyModifierFlags];
    [aCoder encodeObject:self.characters forKey:SRShortcutKeyCharacters];
    [aCoder encodeObject:self.charactersIgnoringModifiers forKey:SRShortcutKeyCharactersIgnoringModifiers];
}


#pragma mark NSObject

- (BOOL)isEqual:(NSObject *)anObject
{
    if ([super isEqual:anObject])
        return YES;
    else if (!anObject)
        return NO;
    else if ([self isKindOfClass:anObject.class] && [anObject isKindOfClass:SRShortcut.class])
        return [self isEqualToShortcut:(SRShortcut *)anObject];
    else
        return [self SR_isMostSpecializedEqual:anObject];
}

- (NSUInteger)hash
{
    // SRCocoaModifierFlagsMask leaves enough bits for key code
    return (self.modifierFlags & SRCocoaModifierFlagsMask) | self.keyCode;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@>", self.className, self, self.dictionaryRepresentation.description];
}

@end



NSString *SRReadableStringForCocoaModifierFlagsAndKeyCode(NSEventModifierFlags aModifierFlags, unsigned short aKeyCode)
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


NSString *SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(NSEventModifierFlags aModifierFlags, unsigned short aKeyCode)
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


static BOOL _SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(unsigned short aKeyCode,
                                                             NSEventModifierFlags aKeyCodeFlags,
                                                             NSString * _Nullable aKeyEquivalent,
                                                             NSEventModifierFlags aKeyEquivalentModifierFlags,
                                                             SRKeyCodeTransformer * _Nonnull aTransformer)
{
    if (![aKeyEquivalent length])
        return NO;

    aKeyCodeFlags &= SRCocoaModifierFlagsMask;
    aKeyEquivalentModifierFlags &= SRCocoaModifierFlagsMask;

    if (aKeyCodeFlags == aKeyEquivalentModifierFlags)
    {
        NSString *keyCodeRepresentation = [aTransformer transformedValue:@(aKeyCode)
                                               withImplicitModifierFlags:nil
                                                   explicitModifierFlags:@(aKeyCodeFlags)];
        return [keyCodeRepresentation isEqual:aKeyEquivalent];
    }
    else if (!aKeyEquivalentModifierFlags ||
             (aKeyCodeFlags & aKeyEquivalentModifierFlags) == aKeyEquivalentModifierFlags)
    {
        // Some key equivalent modifier flags can be implicitly set via special unicode characters. E.g. å instead of opt-a.
        // However all modifier flags explictily set in key equivalent MUST be also set in key code flags.
        // E.g. ctrl-å/ctrl-opt-a and å/opt-a match this condition, but cmd-å/ctrl-opt-a doesn't.
        NSString *keyCodeRepresentation = [aTransformer transformedValue:@(aKeyCode)
                                               withImplicitModifierFlags:nil
                                                   explicitModifierFlags:@(aKeyCodeFlags)];

        if ([keyCodeRepresentation isEqual:aKeyEquivalent])
        {
            // Key code and key equivalent are not equal if key code representation matches key equivalent, but modifier flags are not.
            return NO;
        }
        else
        {
            NSEventModifierFlags possiblyImplicitFlags = aKeyCodeFlags & ~aKeyEquivalentModifierFlags;
            keyCodeRepresentation = [aTransformer transformedValue:@(aKeyCode)
                                         withImplicitModifierFlags:@(possiblyImplicitFlags)
                                             explicitModifierFlags:@(aKeyEquivalentModifierFlags)];
            return [keyCodeRepresentation isEqual:aKeyEquivalent];
        }
    }
    else
        return NO;
}


BOOL SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(unsigned short aKeyCode,
                                                     NSEventModifierFlags aKeyCodeFlags,
                                                     NSString *aKeyEquivalent,
                                                     NSEventModifierFlags aKeyEquivalentModifierFlags)
{
    BOOL isEqual = _SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(aKeyCode,
                                                                    aKeyCodeFlags,
                                                                    aKeyEquivalent,
                                                                    aKeyEquivalentModifierFlags,
                                                                    [SRKeyCodeTransformer sharedASCIITransformer]);

    if (!isEqual)
    {
        isEqual = _SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(aKeyCode,
                                                                   aKeyCodeFlags,
                                                                   aKeyEquivalent,
                                                                   aKeyEquivalentModifierFlags,
                                                                   [SRKeyCodeTransformer sharedTransformer]);
    }

    return isEqual;
}
