//
//  SRKeyCodeTransformer.h
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
//      Ilya Kulakov
//      Silvio Rizzi

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>


/*!
    @brief  Transforms key code into unicode character.
 */
@interface SRKeyCodeTransformer : NSValueTransformer

/*!
    @brief      Returns initialized key code transformer.

    @param      aUsesASCII Determines whether transformer uses only ASCII capable keyboard input source.

    @param      aUsesPlainStrings Determines whether key codes without readable glyphs (e.g. F1...F19) are transformed to
                to unicode characters (NSF1FunctionKey...NSF19FunctionKey) suitable for setting key equivalents
                of Cocoa controls or to plain strings (@"F1"...@"F19") suitable for drawing, logging and accessibility.

    @discussion This method is the designated initializer for SRKeyCodeTransformer.
 */
- (instancetype)initWithASCIICapableKeyboardInputSource:(BOOL)aUsesASCII plainStrings:(BOOL)aUsesPlainStrings;

/*!
    @brief  Determines whether transformer uses ASCII capable keyboard input source.
 */
@property (readonly) BOOL usesASCIICapableKeyboardInputSource;

/*!
    @brief  Determines whether key codes without readable glyphs are transformed to unicode characters or to plain strings.
 */
@property (readonly) BOOL usesPlainStrings;

/*!
 @brief  Returns the shared transformer.
 */
+ (instancetype)sharedTransformer;

/*!
 @brief  Returns the shared transformer configured to use only ASCII capable keyboard input source.
 */
+ (instancetype)sharedASCIITransformer;

/*!
 @brief  Returns the shared transformer configured to transform key codes to plain strings.
 */
+ (SRKeyCodeTransformer *)sharedPlainTransformer;

/*!
 @brief  Returns the shared transformer configured to use only ASCII capable keyboard input source
 and to transform key codes to plain strings.
 */
+ (SRKeyCodeTransformer *)sharedPlainASCIITransformer;


/*!
    @brief  Returns mapping from special key codes to unicode characters.
 */
+ (NSDictionary *)specialKeyCodesToUnicodeCharactersMapping;

/*!
    @brief  Returns mapping from special key codes to plain strings.
 */
+ (NSDictionary *)specialKeyCodesToPlainStringsMapping;

@end


/*!
    @brief  These constants represents unicode characters for key codes that do not have appropriate constants
            in Carbon or Cocoa.
 */
NS_ENUM(unichar, SRKeyCodeGlyph)
{
    SRKeyCodeGlyphRight = 0x21E5,
    SRKeyCodeGlyphReturn = 0x2305,
    SRKeyCodeGlyphReturnR2L = 0x21A9,
    SRKeyCodeGlyphDeleteLeft = 0x232B,
    SRKeyCodeGlyphDeleteRight = 0x2326,
    SRKeyCodeGlyphPadClear = 0x2327,
    SRKeyCodeGlyphLeftArrow = 0x2190,
    SRKeyCodeGlyphRightArrow = 0x2192,
    SRKeyCodeGlyphUpArrow = 0x2191,
    SRKeyCodeGlyphDownArrow = 0x2193,
    SRKeyCodeGlyphPageDown = 0x21DF,
    SRKeyCodeGlyphPageUp = 0x21DE,
    SRKeyCodeGlyphNorthwestArrow = 0x2196,
    SRKeyCodeGlyphSoutheastArrow = 0x2198,
    SRKeyCodeGlyphEscape = 0x238B,
    SRKeyCodeGlyphHelp = 0x003F,
    SRKeyCodeGlyphSpace = 0x23B5,
};
