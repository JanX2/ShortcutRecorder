//
//  SRKeyCodeTransformer.h
//  ShortcutRecorder
//
//  Copyright 2006-2018 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Ilya Kulakov
//      Silvio Rizzi

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>


NS_ASSUME_NONNULL_BEGIN

/*!
    Transform a key code into a unicode symbol or a literal string.
 */
NS_SWIFT_NAME(KeyCodeTransformer)
@interface SRKeyCodeTransformer : NSValueTransformer

/*!
    Shared symbolic transformer.
 */
@property (class, readonly) SRKeyCodeTransformer *sharedSymbolicTransformer;

/*!
    Shared symblic transformer configured to use only ASCII capable keyboard input source.
 */
@property (class, readonly) SRKeyCodeTransformer *sharedSymbolicASCIITransformer;

/*!
    Shared transformer configured to transform key codes to literal strings.
 */
@property (class, readonly) SRKeyCodeTransformer *sharedLiteralTransformer;

/*!
    Shared transformer configured to use only ASCII capable keyboard input source
    to transform key codes to literal strings.
 */
@property (class, readonly) SRKeyCodeTransformer *sharedLiteralASCIITransformer;

/*!
    Mapping from special key codes to unicode symbols.
 */
@property (class, readonly) NSDictionary *specialKeyCodeToSymbolMapping;

/*!
    Mapping from special key codes to literal strings.
 */
@property (class, readonly) NSDictionary *specialKeyCodeToLiteralMapping;

/*!
    Return initialized key code transformer.

    @param      aUsesASCII Determines whether transformer uses only ASCII capable keyboard input source.

    @param      aIsLiteral Determines whether key codes without readable glyphs (e.g. F1...F19) are transformed to
                to unicode symbols (NSF1FunctionKey...NSF19FunctionKey) suitable for setting key equivalents
                of Cocoa controls or to literal strings (@"F1"...@"F19") suitable for drawing, logging and accessibility.

    @discussion This method is the designated initializer for SRKeyCodeTransformer.
 */
- (instancetype)initWithASCIICapableKeyboardInputSource:(BOOL)aUsesASCII
                                              isLiteral:(BOOL)aIsLiteral NS_DESIGNATED_INITIALIZER;

/*!
    Whether transformer uses ASCII capable keyboard input source.
 */
@property (readonly) BOOL usesASCIICapableKeyboardInputSource;

/*!
    Whether key codes without readable glyphs are transformed to unicode symbols
    suitable for setting keqEquivalents or to literal strings suitable for drawing, logging and accessibility.
 */
@property (readonly) BOOL isLiteral;

/*!
    Whether key code is special.

    @param  aKeyCode Key code to be checked.
 */
- (BOOL)isKeyCodeSpecial:(unsigned short)aKeyCode;

/*!
 @seealso transformedSpecialKeyCode:withExplicitModifierFlags:forView:
 */
- (NSString *)transformedSpecialKeyCode:(NSNumber *)aKeyCode
              withExplicitModifierFlags:(nullable NSNumber *)anExplicitModifierFlags;

/*!
    Transforms given special key code into unicode symbol by taking into account modifier flags and view settings.

    @discussion E.g. the key code 0x30 is transformed to ⇥. But if shift is pressed, it is transformed to ⇤.

    @result     Unicode symbol or literal string. nil if not a special key code.
*/
- (NSString *)transformedSpecialKeyCode:(NSNumber *)aKeyCode
              withExplicitModifierFlags:(nullable NSNumber *)anExplicitModifierFlags
                                forView:(nullable NSView *)aView;

/*!
    Same as [self transformedValue:aValue withImplicitModifierFlags:aModifierFlags explicitModifierFlags:nil]
 */
- (nullable NSString *)transformedValue:(NSNumber *)aValue
                      withModifierFlags:(nullable NSNumber *)aModifierFlags;

/*!
 @seealso transformedValue:withImplicitModifierFlags:explicitModifierFlags:forView:
 */
- (nullable NSString *)transformedValue:(NSNumber *)aValue
              withImplicitModifierFlags:(nullable NSNumber *)anImplicitModifierFlags
                  explicitModifierFlags:(nullable NSNumber *)anExplicitModifierFlags;

/*!
    Transfrom given key code into unicode symbol by taking into account modifier flags and view settings.
 
    @param  aValue An instance of NSNumber (unsigned short) that represents key code.
 
    @param  anImplicitModifierFlags An instance of NSNumber (NSEventModifierFlags) that represents implicit modifier flags like opt in å.
 
    @param  anExplicitModifierFlags An instance of NSNumber (NSEventModifierFlags) that represents explicit modifier flags like shift in shift-⇤.

    @param  aView Optional view whose settings are being considered.

    @throws NSInvalidArgumentException

    @discussion If anImplicitModifierFlags and anExplicitModifierFlags share values, NSInvalidArgumentException is thrown.
 */
- (nullable NSString *)transformedValue:(NSNumber *)aValue
              withImplicitModifierFlags:(nullable NSNumber *)anImplicitModifierFlags
                  explicitModifierFlags:(nullable NSNumber *)anExplicitModifierFlags
                                forView:(nullable NSView *)aView;

@end


@interface SRKeyCodeTransformer(Deprecated)

+ (instancetype)sharedTransformer __attribute__((deprecated("", "sharedSymbolicTransformer")));
+ (instancetype)sharedASCIITransformer __attribute__((deprecated("", "sharedSymbolicASCIITransformer")));
+ (SRKeyCodeTransformer *)sharedPlainTransformer __attribute__((deprecated("", "sharedLiteralTransformer")));
+ (SRKeyCodeTransformer *)sharedPlainASCIITransformer __attribute__((deprecated("", "sharedLiteralASCIITransformer")));

- (instancetype)initWithASCIICapableKeyboardInputSource:(BOOL)aUsesASCII plainStrings:(BOOL)aUsesPlainStrings __attribute__((deprecated("", "initWithASCIICapableKeyboardInputSource:isLiteral:")));

@property (readonly, getter=isLiteral) BOOL usesPlainStrings __attribute__((deprecated("", "isLiteral")));

@end

NS_ASSUME_NONNULL_END
