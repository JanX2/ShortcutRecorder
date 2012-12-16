//
//  SRValidator.h
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
//      Andy Kim
//      Silvio Rizzi
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>


@protocol SRValidatorDelegate;

/*!
    @brief  Implements logic to check whether shortcut is taken by other parts of the application and system.
 */
@interface SRValidator : NSObject

@property (assign) NSObject<SRValidatorDelegate> *delegate;

- (instancetype)initWithDelegate:(NSObject<SRValidatorDelegate> *)aDelegate;

/*!
    @brief      Determines whether shortcut is taken.
 
    @discussion Key is checked in the following order:
                1. If delegate implements shortcutValidator:isKeyCode:andFlagsTaken:reason:
                2. If delegate allows system-wide shortcuts are checked
                3. If delegate allows application menu it checked
 
    @see        SRValidatorDelegate
 */
- (BOOL)isKeyCode:(NSInteger)aKeyCode andFlagsTaken:(NSUInteger)aFlags error:(NSError **)outError;

/*!
    @brief      Determines whether shortcut is taken in delegate.
 
    @discussion If delegate does not implement appropriate method, returns immediately.
 */
- (BOOL)isKeyCode:(NSInteger)aKeyCode andFlagTakenInDelegate:(NSUInteger)aFlags error:(NSError **)outError;

/*!
    @brief      Determines whether shortcut is taken by system-wide shortcuts.
 
    @discussion Does not check whether delegate allows or disallows checking in system shortcuts.
 */
- (BOOL)isKeyCode:(NSInteger)aKeyCode andFlagsTakenInSystemShortcuts:(NSUInteger)aFlags error:(NSError **)outError;

/*!
    @brief      Determines whether shortcut is taken by application menu item.
 
    @discussion Does not check whether delegate allows or disallows checking in application menu.
 */
- (BOOL)isKeyCode:(NSInteger)aKeyCode andFlags:(NSUInteger)aFlags takenInMenu:(NSMenu *)aMenu error:(NSError **)outError;

@end


@protocol SRValidatorDelegate

@optional

/*!
    @brief  Delegate may implement this method to provide custom shortcut check.
 */
- (BOOL)shortcutValidator:(SRValidator *)aValidator isKeyCode:(NSInteger)aKeyCode andFlagsTaken:(NSUInteger)aFlags reason:(NSString **)outReason;

/*!
    @brief  Delegate may implement this method to allow the validator to check in system shortcuts.
 */
- (BOOL)shortcutValidatorShouldCheckMenu:(SRValidator *)aValidator;

/*!
    @brief  Delegate may implement this method to prevent the validator to check in system shortcuts.
 */
- (BOOL)shortcutValidatorShouldCheckSystemShortcuts:(SRValidator *)aValidator;

/*!
    @brief  Delegate may implement this method to force the validator to show ASCII representation of keyCode in errors.
 */
- (BOOL)shortcutValidatorShouldUseASCIIStringForKeyCodes:(SRValidator *)aValidator;

@end
