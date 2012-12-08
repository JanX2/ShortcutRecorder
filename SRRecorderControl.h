//
//  SRRecorderControl.h
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

#import <Cocoa/Cocoa.h>
#import "SRRecorderCell.h"

extern NSString *const SRShortcutCodeKey;
extern NSString *const SRShortcutFlagsKey;
extern NSString *const SRShortcutCharacters;
extern NSString *const SRShortcutCharactersIgnoringModifiers;

@interface SRRecorderControl : NSControl
{
    IBOutlet id delegate;
}

@property (nonatomic) BOOL animates;

@property (nonatomic) SRRecorderStyle style;

@property (assign) id delegate;

@property (nonatomic) NSUInteger allowedFlags;

@property (readonly, nonatomic) BOOL allowsKeyOnly;

@property (readonly, nonatomic) BOOL escapeKeysRecord;

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord;

@property (nonatomic) BOOL canCaptureGlobalHotKeys;

@property (nonatomic) NSUInteger requiredFlags;

@property (nonatomic, readonly) KeyCombo keyCombo;

@property (nonatomic, readonly) NSString *keyChars;

@property (nonatomic, readonly) NSString *keyCharsIgnoringModifiers;

- (void)setKeyCombo:(KeyCombo)newKeyCombo keyChars:(NSString *)newKeyChars keyCharsIgnoringModifiers:(NSString *)newKeyCharsIgnoringModifiers;

@property (nonatomic) BOOL isASCIIOnly;

@property (nonatomic, copy) NSDictionary *objectValue;

// Returns the displayed key combination if set
@property (nonatomic, readonly) NSString *keyComboString;

#pragma mark *** Conversion Methods ***

- (NSUInteger)cocoaToCarbonFlags:(NSUInteger)cocoaFlags;

- (NSUInteger)carbonToCocoaFlags:(NSUInteger)carbonFlags;

- (void)resetTrackingRects;

@end

// Delegate Methods
@interface NSObject (SRRecorderDelegate)

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo;

- (BOOL)shortcutRecorderShouldCheckMenu:(SRRecorderControl *)aRecorder;

- (BOOL)shortcutRecorderShouldSystemShortcuts:(SRRecorderControl *)aRecorder;
@end
