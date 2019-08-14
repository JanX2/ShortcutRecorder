//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRShortcut.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 An association of a Shortcut and an Action (selector).

 The class implements the NSValidatedUserInterfaceItem protocol and can participate in user interface item validation.
 */
NS_SWIFT_NAME(ShortcutItem)
@interface SRShortcutItem : NSObject <NSValidatedUserInterfaceItem, NSSecureCoding, NSCopying>

@property (readonly) SRShortcut *shortcut;

@property (readonly) SEL action;

@property (readonly) NSInteger tag;

+ (SRShortcutItem *)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithShortcut:(SRShortcut *)aShortcut action:(SEL)anAction tag:(NSInteger)aTag NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithShortcut:(SRShortcut *)aShortcut action:(SEL)anAction;

/*!
 Perform the associated action on aTarget.

 The action is performed if:
    1. aTarget implements provides the compatible Target-Action implementation
    2. - validateUserInterfaceItem:, if implemented, returns YES
 */
- (BOOL)performOnTarget:(id)aTarget;

- (BOOL)isEqualToShortcutItem:(SRShortcutItem *)aShortcutItem;

@end


/*!
 Catalog is a collection of shortcut items.

 The items are stored in an unordered KVC-complient collection items.
 Only one action can be associated with a shortcut.
 */
NS_SWIFT_NAME(ShortcutItemCatalog)
@interface SRShortcutItemCatalog : NSObject <NSSecureCoding, NSCopying>

- (NSUInteger)countOfItems;

- (NSEnumerator<SRShortcutItem *> *)enumeratorOfItems;

- (nullable SRShortcutItem *)memberOfItems:(SRShortcutItem *)aShortcutItem;

- (void)addItemsObject:(SRShortcutItem *)aShortcutItem;

- (void)removeItemsObject:(SRShortcutItem *)aShortcutItem;

/*!
 A convenience method to add a shortcut item.
 */
- (void)addAction:(SEL)anAction forShortcut:(SRShortcut *)aShortcut NS_SWIFT_NAME(addAction(_:forShortcut:));

/*!
 A convenience method to add a shortcut item.
 */
- (void)addAction:(SEL)anAction forKeyEquivalent:(NSString *)aKeyEquivalent;

/*!
 Perform the shortcut on the target.

 @seealso SRShortcutItem/performOnTarget:
 */
- (BOOL)performShortcut:(SRShortcut *)aShortcut onTarget:(id)aTarget;

/*!
 Perform a shortcut encoded in the key equivalent on the target.

 @seealso SRShortcutItem/performOnTarget:
 */
- (BOOL)performKeyEquivalent:(NSString *)aKeyEquivalent onTarget:(id)aTarget;

/*!
 Perform a shortcut encoded in the key event on the target.

 @param aKeyEvent Either key down or key up event.
 */
- (BOOL)performEvent:(NSEvent *)aKeyEvent onTarget:(id)aTarget;

- (BOOL)isEqualToShortcutCatalog:(SRShortcutItemCatalog *)aCatalog;

@end


@interface SRShortcutItemCatalog (SRCommonShortcuts)

/*!
 Text-related key bindings.

 @seealso NSStandardKeyBindingResponding
 */
@property (class, readonly) SRShortcutItemCatalog *standard;

/*!
 Key bindings that mimic default main menu for new Applications.
 */
@property (class, readonly) SRShortcutItemCatalog *mainMenu;

/*!
 Key bindings associated with the clipboard.

 - cut:
 - copy:
 - paste:
 - pasteAsPlainText:
 - redo:
 - undo:
 */
@property (class, readonly) SRShortcutItemCatalog *clipboard;

/*!
 Key bindings associated with window management.

 - performClose:
 - performMiniaturize:
 - toggleFullScreen:
 */
@property (class, readonly) SRShortcutItemCatalog *window;

/*!
 Key bindings associated with document management.

 - print:
 - runPageLayout:
 - revertDocumentToSaved:
 - saveDocument:
 - saveDocumentAs:
 - duplicateDocument:
 - openDocument:
 */
@property (class, readonly) SRShortcutItemCatalog *document;

/*!
 Key bindings associated with application management.

 - hide:
 - hideOtherApplications:
 - terminate:
 */
@property (class, readonly) SRShortcutItemCatalog *app;

/*!
 Update catalog with system-wide and user-specific Cocoa Text System key bindings.

 As a result items may be modified and removed. No new items can be added.
 */
- (void)updateWithCocoaTextKeyBindings;

@end

NS_ASSUME_NONNULL_END
