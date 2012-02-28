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
    NSCache *_cache;
}

+ (SRKeyCodeTransformer *)sharedTransformer;

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
