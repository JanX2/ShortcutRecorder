//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <ShortcutRecorder/SRShortcut.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 A mapping between shortcuts and actions.

 Useful to handle key equivalents in NSResponder subclasses.
 */
NS_SWIFT_NAME(ShortcutActions)
@interface SRShortcutActions : NSObject

/*!
 All shortcuts in the mapping.
 */
- (NSArray<SRShortcut *> *)allShortcuts;

/*!
 All actions in the mapping.
 */
- (NSArray<NSValue *> *)allActions;

/*!
 Action associated with the shortcut.
 */
- (nullable SEL)actionForShortcut:(SRShortcut *)aShortcut;

/*!
 Associate action with the shortcut.
 */
- (void)setAction:(SEL)anAction forShortcut:(SRShortcut *)aShortcut;

/*!
 Remove any action associated with the shortcut.
 */
- (void)removeActionForShortcut:(SRShortcut *)aShortcut;

/*!
 Attempt to perform an action associated with the shortcut on the target.

 @param aTarget An object that may implement an action associated with the shortcut.

 @return YES if there is an action associated with aShortcut and aTarget implements it; Otherwise NO.
 */
- (BOOL)performShortcut:(SRShortcut *)aShortcut onTarget:(id)aTarget;

/*!
 Same as `performShortcut:` but creates shortcut implicitly from a keyboard Cocoa event.

 @seealso SRShortcut/shortcutWithEvent:
 */
- (BOOL)performKeyEquivalent:(NSEvent *)anEvent onTarget:(id)aTarget;

@end

NS_ASSUME_NONNULL_END
