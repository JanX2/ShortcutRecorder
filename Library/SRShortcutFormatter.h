//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 3.0
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 Transform shortcut into a string.
 */
NS_SWIFT_NAME(ShortcutFormatter)
@interface SRShortcutFormatter : NSFormatter

@property IBInspectable BOOL isKeyCodeLiteral;
@property IBInspectable BOOL areModifierFlagsLiteral;
@property IBInspectable BOOL usesASCIICapableKeyboardInputSource;

@end

NS_ASSUME_NONNULL_END
