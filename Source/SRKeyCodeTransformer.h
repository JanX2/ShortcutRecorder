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


@interface SRKeyCodeTransformer : NSValueTransformer
{
    BOOL transformsfunctionKeysToPlainStrings;

    NSCache *_cache;
}

/*!
 @abstract      Determines whether functional keys (F1...F19) are transformed to single-char unicode keys
 (NSF1FunctionKey...NSF19FunctionKey) or to plain strings (@"F1"...@"F19")
 @discussion    Defaults to NO.
 If want to draw result of transforming, you should set this value to YES.
 If you want to set the result as key equivalent of NSMenuItem or NSButton (etc), you should set this value to NO.
 */
@property (nonatomic) BOOL transformsfunctionKeysToPlainStrings;

+ (SRKeyCodeTransformer *)sharedTransformer;

+ (SRKeyCodeTransformer *)sharedPlainTransformer;

/*!
 @discussion    You are responsible for releasing the result.
 */
+ (TISInputSourceRef)preferredKeyboardInputSource;

/*!
 @discussion    You are responsible for releasing the result.
 */
+ (TISInputSourceRef)ASCIICapableKeyboardInputSource;

- (BOOL)isSpecialKeyCode:(NSInteger)aKeyCode;


@property (nonatomic, retain) NSDictionary *_reverseTransformDictionary;

@property (nonatomic, retain) NSArray *_padKeys;

@property (nonatomic, retain) NSDictionary *_specialKeyCodeStringsDictionary;

- (void)_keyboardInputSourceDidChange;

@end
