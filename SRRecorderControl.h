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
#import <ShortcutRecorder/SRCommon.h>


/*!
    @brief      Key code.

    @discussion NSNumber representation of unsigned short.
                Required key of SRRecorderControl's objectValue.
 */
extern NSString *const SRShortcutKeyCode;

/*!
    @brief      Modifier flags.

    @discussion NSNumber representation of NSUInteger.
                Optional key of SRRecorderControl's objectValue.
 */
extern NSString *const SRShortcutModifierFlagsKey;

/*!
    @brief      Interpretation of key code and modifier flags depending on system locale and input source
                used when shortcut was taken.

    @discussion NSString.
                Optional key of SRRecorderControl's objectValue.
 */
extern NSString *const SRShortcutCharacters;

/*!
    @brief      Interpretation of key code without modifier flags depending on system locale and input source
                used when shortcut was taken.

    @discussion NSString.
                Optional key of SRRecorderControl's objectValue.
 */
extern NSString *const SRShortcutCharactersIgnoringModifiers;


@protocol SRRecorderControlDelegate;


/*!
    @brief  An SRRecorderControl object is a control (but not a subclass of NSControl) that allows you to record shortcuts.
 */
@interface SRRecorderControl : NSView /* <NSToolTipOwner> */

/*!
    @brief      The receiver’s delegate.

    @discussion A recorder control delegate responds to editing-related messages. You can use to to prevent editing
                in some cases or to validate typed shortcuts.
 */
@property (assign) IBOutlet NSObject<SRRecorderControlDelegate> *delegate;

/*!
    @brief      Returns an integer bit field indicating allowed modifier flags.

    @discussion Defaults to SRCocoaModifierFlagsMask.
 */
@property (readonly) NSUInteger allowedModifierFlags;

/*!
    @brief      Returns an integer bit field indicating required modifier flags.

    @discussion Defaults to 0.
 */
@property (readonly) NSUInteger requiredModifierFlags;

/*!
    @brief      Determines whether shortcuts without modifier flags are allowed.

    @discussion Defaults to NO.
 */
@property (readonly) BOOL allowsEmptyModifierFlags;

/*!
    @brief      Determines whether the control reinterpret key code and modifier flags
                using ASCII capable input source.

    @discussion Defaults to YES.
                If not set, the same key code may be draw differently depending on current input source.
                E.g. with US English input source key code 0x0 is interpreted as "a",
                however with Russian input source, it's interpreted as "ф".
 */
@property BOOL drawsASCIIEquivalentOfShortcut;

/*!
    @brief      Determines whether Escape is used to cancel recording.

    @discussion Defaults to YES.
                If set, Escape without modifier flags cannot be recorded as shortcut.
 */
@property BOOL allowsEscapeToCancelRecording;

/*!
    @brief      Determines whether delete (or forward delete) is used to remove current shortcut and end recording.

    @discussion Defaults to YES.
                If set, neither Delete nor Forward Delete without modifier flags can be recorded as shortcut.
 */
@property BOOL allowsDeleteToClearShortcutAndEndRecording;

/*!
    @brief  Determines whether recording is in process.
 */
@property (readonly) BOOL isRecording;

/*!
    @brief  Returns dictionary representation of receiver's shortcut.
 */
@property (nonatomic, copy) NSDictionary *objectValue;

/*!
    @brief      Configures recording behavior of the control.

    @param      newAllowedModifierFlags New allowed modifier flags.

    @param      newRequiredModifierFlags New required modifier flags.

    @param      newAllowsEmptyModifierFlags Determines whether empty modifier flags are allowed.

    @discussion Flags are filtered using SRCocoaModifierFlagsMask. Flags does not affect object values set manually.

                Throws NSInvalidArgumentException if either required flags are not allowed
                or required flags are not empty and no modifier flags are allowed.
 */
- (void)setAllowedModifierFlags:(NSUInteger)newAllowedModifierFlags
          requiredModifierFlags:(NSUInteger)newRequiredModifierFlags
       allowsEmptyModifierFlags:(BOOL)newAllowsEmptyModifierFlags;

- (BOOL)beginRecording;

- (void)endRecording;

- (void)clearAndEndRecording;

- (BOOL)areModifierFlagsValid:(NSUInteger)aModifierFlags;


- (NSBezierPath *)controlShape;

- (NSRect)enclosingLabelRect;

- (NSRect)rectForLabel:(NSString *)aLabel withAttributes:(NSDictionary *)anAttributes;

- (NSRect)snapBackButtonRect;

- (NSRect)clearButtonRect;


- (NSString *)label;

- (NSString *)plainLabel;

- (NSDictionary *)labelAttributes;

- (void)drawBackground:(NSRect)aDirtyRect;

- (void)drawInterior:(NSRect)aDirtyRect;

- (void)drawLabel:(NSRect)aDirtyRect;

- (void)drawSnapBackButton:(NSRect)aDirtyRect;

- (void)drawClearButton:(NSRect)aDirtyRect;


- (BOOL)isMainButtonHighlighted;

- (BOOL)isSnapBackButtonHighlighted;

- (BOOL)isClearButtonHighlighted;

@end


@protocol SRRecorderControlDelegate <NSObject>

@optional

- (BOOL)shortcutRecorderShouldBeginRecording:(SRRecorderControl *)aRecorder;

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder canRecordShortcut:(NSDictionary *)aShortcut;

- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder;

@end
