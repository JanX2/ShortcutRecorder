//
//  SRValidator.h
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
//      Andy Kim
//      Silvio Rizzi
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>

#import <ShortcutRecorder/SRRecorderControl.h>


NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ValidatorDelegate)
@protocol SRValidatorDelegate;

/*!
    Validate shortcut by checking whether shortcut is taken by other parts of the application and system.

    @discussion Implementation of SRRecorderControlDelegate/shortcutRecorder:canRecordShortcut: uses
                the validateShortcut:error: method and presents error via NSErrorPresentation
                of a given SRRecorderControl instance.
 */
NS_SWIFT_NAME(Validator)
@interface SRValidator : NSObject <SRRecorderControlDelegate>

@property (nullable, weak) NSObject<SRValidatorDelegate> *delegate;

- (instancetype)initWithDelegate:(nullable NSObject<SRValidatorDelegate> *)aDelegate NS_DESIGNATED_INITIALIZER;

/*!
    Check whether shortcut is valid.

    @result     YES if shortcut is valid.

    @discussion Key is checked in the following order:
                1. Delegate's shortcutValidator:isShortcutValid:reason:
                2. If delegate allows system-wide shortcuts are checked
                3. If delegate allows application menu it checked

    @see        SRValidatorDelegate
 */
- (BOOL)validateShortcut:(SRShortcut *)aShortcut error:(NSError * _Nullable *)outError NS_SWIFT_NAME(validateShortcut(_:));

/*!
    Check whether delegate allows the shortcut.

    @result     YES if shortcut is valid.

    @discussion Defaults to YES if delegate does not implement the method.
 */
- (BOOL)validateShortcutAgainstDelegate:(SRShortcut *)aShortcut error:(NSError * _Nullable *)outError;

/*!
    Check whether shortcut is taken by system-wide shortcuts.

    @result     YES if shortcut is valid.

    @see SRValidatorDelegate/shortcutValidatorShouldCheckSystemShortcuts:
 */
- (BOOL)validateShortcutAgainstSystemShortcuts:(SRShortcut *)aShortcut error:(NSError * _Nullable *)outError;

/*!
    Check whether shortcut is taken by a menu item.

    @result     YES if shortcut is valid.

    @see SRValidatorDelegate/shortcutValidatorShouldCheckMenu:
 */
- (BOOL)validateShortcut:(SRShortcut *)aShortcut againstMenu:(NSMenu *)aMenu error:(NSError * _Nullable *)outError NS_SWIFT_NAME(validateShortcut(_:againstMenu:));

@end


@interface SRValidator(Deprecated)

- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagsTaken:(NSEventModifierFlags)aFlags error:(NSError * _Nullable *)outError __attribute__((deprecated("", "validateShortcut:error:"))) NS_SWIFT_UNAVAILABLE("validateShortcut(_:)");
- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagTakenInDelegate:(NSEventModifierFlags)aFlags error:(NSError * _Nullable *)outError __attribute__((deprecated("", "validateShortcutAgainstDelegate:error:"))) NS_SWIFT_UNAVAILABLE("validateShortcutAgainstDelegate(_:)");
- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagsTakenInSystemShortcuts:(NSEventModifierFlags)aFlags error:(NSError * _Nullable *)outError __attribute__((deprecated("", "validateShortcutAgainstSystemShortcuts:error:"))) NS_SWIFT_UNAVAILABLE("Use validateShortcutAgainstSystemShortcuts(_:)");
- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlags:(NSEventModifierFlags)aFlags takenInMenu:(NSMenu *)aMenu error:(NSError * _Nullable *)outError __attribute__((deprecated("", "validateShortcut:againstMenu:error:"))) NS_SWIFT_UNAVAILABLE("Use validateShortcut(_:againstMenu:)");

@end


@protocol SRValidatorDelegate

@optional

/*!
    Ask the delegate if shortcut is valid.

    @param      aValidator The validator that validates key code and flags.

    @param      aKeyCode Key code to validate.

    @param      aFlags Flags to validate.

    @param      outReason If delegate decides that shortcut is invalid, it may pass here an error message.

    @result     YES if shortcut is valid. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, checking proceeds as if this method had returned YES.
 */
- (BOOL)shortcutValidator:(SRValidator *)aValidator isShortcutValid:(SRShortcut *)aShortcut reason:(NSString * _Nullable * _Nonnull)outReason;

/*!
    Same as -shortcutValidator:isShortcutValid:reason: but return value is flipped. I.e. YES means shortcut is invalid.
 */
- (BOOL)shortcutValidator:(SRValidator *)aValidator isKeyCode:(unsigned short)aKeyCode andFlagsTaken:(NSEventModifierFlags)aFlags reason:(NSString * _Nullable * _Nonnull)outReason __attribute__((deprecated("", "shortcutValidator:isShortcutValid:reason:")));

/*!
    Asks the delegate whether validator should check key equivalents of app's menu items.

    @param      aValidator The validator that going to check app's menu items.

    @result     YES if validator should check key equivalents of app's menu items. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, checking proceeds as if this method had returned YES.
 */
- (BOOL)shortcutValidatorShouldCheckMenu:(SRValidator *)aValidator;

/*!
    Asks the delegate whether it should check system shortcuts.

    @param      aValidator The validator that going to check system shortcuts.

    @result     YES if validator should check system shortcuts. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, checking proceeds as if this method had returned YES.
 */
- (BOOL)shortcutValidatorShouldCheckSystemShortcuts:(SRValidator *)aValidator;

/*!
    Asks the delegate whether it should use ASCII representation of key code when making error messages.

    @param      aValidator The validator that is about to make an error message.

    @result     YES if validator should use ASCII representation. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, ASCII representation of key code is used.
 */
- (BOOL)shortcutValidatorShouldUseASCIIStringForKeyCodes:(SRValidator *)aValidator;

@end


@interface NSMenuItem (SRValidator)

/*!
    Full path to the menu item. E.g. "Window → Zoom"
 */
- (NSString *)SR_path;

@end

NS_ASSUME_NONNULL_END
