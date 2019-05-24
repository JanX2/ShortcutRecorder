//
//  SRShortcut.h
//  ShortcutRecorder.framework
//
//  Copyright 2018 Contributors. All rights reserved.
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

/*!
    @enum SRShortcutKey

    @discussion Keys of the dictionary that represents shortcut.
 */
typedef NSString *SRShortcutKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ShortcutKey);

/*!
    @seealso SRShortcut/code
 */
extern SRShortcutKey const SRShortcutKeyKeyCode;

/*!
    @seealso SRShortcut/modifierFlags
 */
extern SRShortcutKey const SRShortcutKeyModifierFlags;

/*!
    @seealso SRShortcut/characters
 */
extern SRShortcutKey const SRShortcutKeyCharacters;

/*!
    @seealso SRShortcut/charactersIgnoringModifiers
 */
extern SRShortcutKey const SRShortcutKeyCharactersIgnoringModifiers;

extern NSString *const SRShortcutKeyCode __attribute__((deprecated("", "SRShortcutKeyKeyCode")));
extern NSString *const SRShortcutModifierFlagsKey __attribute__((deprecated("", "SRShortcutKeyModifierFlags")));
extern NSString *const SRShortcutCharacters __attribute__((deprecated("", "SRShortcutKeyCharacters")));
extern NSString *const SRShortcutCharactersIgnoringModifiers __attribute__((deprecated("", "SRShortcutKeyCharactersIgnoringModifiers")));

/*!
    Combination of a key code, modifier flags and optionally their characters
    representation at the time of recording.

    @note KVC access is compatible with ShortcutRecorder 2

    @note Two shortcuts are considered equal if their code and modifier flags match.
 */
NS_SWIFT_NAME(Shortcut)
@interface SRShortcut : NSObject <NSCopying, NSSecureCoding>

/*!
    @seealso SRShortcut/initWithCode:modifierFlags:characters:charactersIgnoringModifiers:
 */
+ (instancetype)shortcutWithCode:(unsigned short)aKeyCode
                   modifierFlags:(NSEventModifierFlags)aModifierFlags
                      characters:(nullable NSString *)aCharacters
     charactersIgnoringModifiers:(nullable NSString *)aCharactersIgnoringModifiers;

/*!
    Initialize the shortcut with a keyboard event.

    @throws NSInvalidArgumentException

    @discussion NSInvalidArgumentException is thrown if event is not related to keyboard.
 */
+ (instancetype)shortcutWithEvent:(NSEvent *)aKeyboardEvent;

/*!
    Initialize the shortcut with a dictionary.

    @note Compatible with Shortcut Recorder 2 shortcuts.

    @seealso SRShortcutKey
 */
+ (instancetype)shortcutWithDictionary:(NSDictionary *)aDictionary;

+ (instancetype)new NS_UNAVAILABLE;

/*!
    Designated initializer.

    @param aKeyCode A key code such as 0 ('a').

    @param aModifierFlags Modifier flags such as NSEventModifierFlagCommand.

    @param aCharacters Representation of the key code with modifier flags.

    @param aCharactersIgnoringModifiers Representation of the key code without modifier flags.
 */
- (instancetype)initWithCode:(unsigned short)aKeyCode
               modifierFlags:(NSEventModifierFlags)aModifierFlags
                  characters:(nullable NSString *)aCharacters
 charactersIgnoringModifiers:(nullable NSString *)aCharactersIgnoringModifiers NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/*!
    A key code such as 0 ('a').
 */
@property (readonly) unsigned short keyCode;

/*!
    Modifier flags such as NSEventModifierFlagCommand | NSEventModifierFlagOption.
 */
@property (readonly) NSEventModifierFlags modifierFlags;

/*!
    Representation of the key code with modifier flags.

    @discussion Depends on system's locale and the active input source
                at the time when shortcut was taken.
                Does not participate in equality test.
 */
@property (nullable, readonly) NSString *characters;

/*!
    Representation of the key code without modifier flags.

    @discussion Depends on system's locale and the active input source
                at the time when shortcut was taken.
                Does not participate in equality test.
 */
@property (nullable, readonly) NSString *charactersIgnoringModifiers;

/*!
    Dictionary representation of the shortcut. Compatible with ShortcutRecorer 2

    @seealso SRShortcutKey
 */
@property (nonatomic, readonly, copy) NSDictionary<SRShortcutKey, id> *dictionaryRepresentation;

/*!
    Return readable representation of the shortcut for user dialogs or accessibility.

    @param isASCII: Same key code can refere to different characters depending on the input source.
                    If isASCII is NO then the active input source is used. Otherwise ASCII input source is used.
                    Use isASCII = YES for consistent results.
 */
- (NSString *)readableStringRepresentation:(BOOL)isASCII NS_SWIFT_NAME(readableStringRepresentation(isASCII:));

/*!
 Compare the shortcut to another shortcut.

 @discussion Override to compare properties of the receiver against another shortcut only.
 */
- (BOOL)isEqualToShortcut:(SRShortcut *)aShortcut;

/*!
    Compare the shortcut to a dictionary representation.

    @seealso dictionaryRepresentation
 */
- (BOOL)isEqualToDictionary:(NSDictionary<SRShortcutKey, id> *)aDictionary NS_SWIFT_NAME(isEqual(dictionary:));

/*!
    Compare shortcut to Cocoa's key equivalent (e.g. NSMenuItem/keyEquivalent) and modifier flags.
 */
- (BOOL)isEqualToKeyEquivalent:(nullable NSString *)aKeyEquivalent withModifierFlags:(NSEventModifierFlags)aModifierFlags NS_SWIFT_NAME(isEqual(keyEquivalent:modifierFlags:));

/*!
    Dictionary-like access to properties.

    @seealso SRShortcutKey
 */
- (nullable id)objectForKeyedSubscript:(SRShortcutKey)aKey;

@end

/*!
    Check whether dictionary representations of shortcuts are equal (ShortcutRecorder 2).
 */
NS_INLINE BOOL SRShortcutEqualToShortcut(NSDictionary *a, NSDictionary *b) __attribute__((deprecated("", "SRShortcut/isEqual:")));
NS_INLINE BOOL SRShortcutEqualToShortcut(NSDictionary *a, NSDictionary *b)
{
    if (a == b)
        return YES;
    else if (a && !b)
        return NO;
    else if (!a && b)
        return NO;
    else
        return ([a[SRShortcutKeyKeyCode] isEqual:b[SRShortcutKeyKeyCode]] && [a[SRShortcutKeyModifierFlags] isEqual:b[SRShortcutKeyModifierFlags]]);
}

/*!
    Create ShortcutRecorder 2 shortcut.
 */
NS_INLINE NSDictionary *SRShortcutWithCocoaModifierFlagsAndKeyCode(NSEventModifierFlags aModifierFlags, unsigned short aKeyCode) __attribute__((deprecated("", "SRShortcut")));
NS_INLINE NSDictionary *SRShortcutWithCocoaModifierFlagsAndKeyCode(NSEventModifierFlags aModifierFlags, unsigned short aKeyCode)
{
    return @{SRShortcutKeyKeyCode: @(aKeyCode), SRShortcutKeyModifierFlags: @(aModifierFlags)};
}


/*!
    Return string representation of a shortcut with modifier flags replaced with their localized
    readable equivalents (e.g. ⌥ -> Option).
 */
NSString * _Nonnull SRReadableStringForCocoaModifierFlagsAndKeyCode(NSEventModifierFlags aModifierFlags, unsigned short aKeyCode) __attribute__((deprecated("", "SRShortcut/readableStringRepresentation:")));


/*!
    Return string representation of a shortcut with modifier flags replaced with their localized
    readable equivalents (e.g. ⌥ -> Option) and ASCII character for key code.
 */
NSString * _Nonnull SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(NSEventModifierFlags aModifierFlags, unsigned short aKeyCode) __attribute__((deprecated("", "SRShortcut/readableStringRepresentation:")));


/*!
    Check whether a given key code with modifier flags is equal to a key equivalent and key equivalent modifier flags
    (e.g. from NSButton or NSMenuItem).

    @discussion On macOS some key combinations can have "alternates". E.g. option-A can be represented both as "option-A" and "å".
 */
BOOL SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(unsigned short aKeyCode,
                                                     NSEventModifierFlags aKeyCodeFlags,
                                                     NSString * _Nullable aKeyEquivalent,
                                                     NSEventModifierFlags aKeyEquivalentModifierFlags) __attribute__((deprecated("", "SRShortcut/isEqualToKeyEquivalent:withModifierFlags:")));

NS_ASSUME_NONNULL_END
