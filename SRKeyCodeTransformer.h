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
    @brief  Returns the shared trasformer.
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
    @param      aUsesASCII Determines whether transformer uses only ASCII capable keyboard input source.
 
    @param      aUsesPlainStrings Determines whether key codes without readable glyphs (e.g. F1...F19) are transformerd to
                to unicode characters (NSF1FunctionKey...NSF19FunctionKey) or to plain strings (@"F1"...@"F19").
 */
- (instancetype)initWithASCIICapableKeyboardInputSource:(BOOL)aUsesASCII plainStrings:(BOOL)aUsesPlainStrings;

@property (readonly) BOOL usesASCIICapableKeyboardInputSource;

@property (readonly) BOOL usesPlainStrings;

+ (NSDictionary *)specialKeyCodesToUnicodeCharactersMapping;

+ (NSDictionary *)specialKeyCodesToPlainStringsMapping;

@end
