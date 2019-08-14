//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <os/trace.h>
#import <os/activity.h>

#import "SRCommon.h"
#import "SRShortcutItem.h"


@implementation SRShortcutItem

- (instancetype)initWithShortcut:(SRShortcut *)aShortcut action:(SEL)anAction tag:(NSInteger)aTag
{
    self = [super init];

    if (self)
    {
        _shortcut = [aShortcut copy];
        _action = anAction;
        _tag = aTag;
    }

    return self;
}

- (instancetype)initWithShortcut:(SRShortcut *)aShortcut action:(SEL)anAction
{
    return [self initWithShortcut:aShortcut action:anAction tag:0];
}

#pragma mark Methods

- (BOOL)performOnTarget:(id)aTarget
{
    __block BOOL isPerformed = NO;
    os_activity_initiate("performOnTarget:", OS_ACTIVITY_FLAG_DEFAULT, ^{
        // Method exists and its signature is acceptable.
        NSMethodSignature *sig = [aTarget methodSignatureForSelector:self.action];
        if (!sig)
        {
            os_trace_error_with_payload("#Error target does not respond to the action", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "action", NSStringFromSelector(self.action).UTF8String);
            });
            return;
        }
        else if (sig.numberOfArguments > 3)
        {
            os_trace_error_with_payload("#Error too many arguments for the action", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "action", NSStringFromSelector(self.action).UTF8String);
            });
            return;
        }
        else if (strcmp(sig.methodReturnType, "v") != 0)
        {
            os_trace_error_with_payload("#Error wrong return type for the action, expected void", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "action", NSStringFromSelector(self.action).UTF8String);
            });
            return;
        }
        // Target allows it.
        else if ([aTarget respondsToSelector:@selector(validateUserInterfaceItem:)] &&
                 ![aTarget validateUserInterfaceItem:self])
        {
            os_trace_debug_with_payload("target ignored the action", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "action", NSStringFromSelector(self.action).UTF8String);
            });
            return;
        }

        IMP actionMethod = [aTarget methodForSelector:self.action];

        switch (sig.numberOfArguments)
        {
            case 2:
                ((void (*)(id, SEL))actionMethod)(aTarget, self.action);
                isPerformed = YES;
                break;
            case 3:
                ((void (*)(id, SEL, id))actionMethod)(aTarget, self.action, self);
                isPerformed = YES;
                break;
            default:
                break;
        }
    });
    return isPerformed;
}

- (BOOL)isEqualToShortcutItem:(SRShortcutItem *)aShortcutItem
{
    if (aShortcutItem == self)
        return YES;
    else if (![aShortcutItem isKindOfClass:SRShortcutItem.class])
        return NO;
    else
        return aShortcutItem.action == self.action && [aShortcutItem.shortcut isEqualToShortcut:self.shortcut];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)aZone
{
    // SRShortcutItem is immutable.
    return self;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithShortcut:[aDecoder decodeObjectOfClass:SRShortcut.class forKey:@"shortcut"]
                           action:NSSelectorFromString([aDecoder decodeObjectOfClass:NSString.class forKey:@"action"])
                              tag:[[aDecoder decodeObjectOfClass:NSNumber.class forKey:@"tag"] integerValue]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:SRBundle().infoDictionary[(__bridge NSString *)kCFBundleVersionKey] forKey:@"version"];
    [aCoder encodeObject:self.shortcut forKey:@"shortcut"];
    [aCoder encodeObject:NSStringFromSelector(self.action) forKey:@"action"];
    [aCoder encodeObject:@(self.tag) forKey:@"tag"];
}

#pragma mark NSObject

- (BOOL)isEqual:(NSObject *)anObject
{
    return [self SR_isEqual:anObject usingSelector:@selector(isEqualToShortcutItem:) ofCommonAncestor:SRShortcutItem.class];
}

- (NSUInteger)hash
{
    return self.shortcut.hash;
}

@end


@implementation SRShortcutItemCatalog
{
    NSMutableDictionary<SRShortcut *, SRShortcutItem *> *_items;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _items = [NSMutableDictionary new];
    }

    return self;
}

#pragma mark Methods

- (NSUInteger)countOfItems
{
    return _items.count;
}

- (NSEnumerator<SRShortcutItem *> *)enumeratorOfItems
{
    return _items.objectEnumerator;
}

- (SRShortcutItem *)memberOfItems:(SRShortcutItem *)aShortcutItem
{
    SRShortcutItem *member = _items[aShortcutItem.shortcut];
    if ([member isEqualToShortcutItem:aShortcutItem])
        return member;
    else
        return nil;
}

- (void)addItemsObject:(SRShortcutItem *)aShortcutItem
{
    _items[aShortcutItem.shortcut] = aShortcutItem;
}

- (void)removeItemsObject:(SRShortcutItem *)aShortcutItem
{
    SRShortcutItem *member = _items[aShortcutItem.shortcut];
    if ([member isEqualToShortcutItem:aShortcutItem])
        _items[aShortcutItem.shortcut] = nil;
}

- (void)addAction:(SEL)anAction forShortcut:(SRShortcut *)aShortcut
{
    [self addItemsObject:[[SRShortcutItem alloc] initWithShortcut:aShortcut action:anAction]];
}

- (void)addAction:(SEL)anAction forKeyEquivalent:(NSString *)aKeyEquivalent
{
    [self addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:aKeyEquivalent]
                                                           action:anAction]];
}

- (BOOL)performShortcut:(SRShortcut *)aShortcut onTarget:(id)aTarget
{
    SRShortcutItem *member = _items[aShortcut];
    if (!member)
    {
        os_trace_debug_with_payload("shortcut is not in the catalog", ^(xpc_object_t d) {
            xpc_dictionary_set_string(d, "shortcut", aShortcut.description.UTF8String);
        });
        return NO;
    }

    return [member performOnTarget:aTarget];
}

- (BOOL)performKeyEquivalent:(NSString *)aKeyEquivalent onTarget:(id)aTarget
{
    return [self performShortcut:[SRShortcut shortcutWithKeyEquivalent:aKeyEquivalent] onTarget:aTarget];
}

- (BOOL)performEvent:(NSEvent *)aKeyEvent onTarget:(id)aTarget
{
    if (aKeyEvent.type != NSEventTypeKeyDown || aKeyEvent.type != NSEventTypeKeyUp)
    {
        os_trace_error("#Error event is to of the key type");
        return NO;
    }

    return [self performShortcut:[SRShortcut shortcutWithEvent:aKeyEvent] onTarget:aTarget];
}

- (BOOL)isEqualToShortcutCatalog:(SRShortcutItemCatalog *)aCatalog
{
    if (aCatalog == self)
        return YES;
    else if (![aCatalog isKindOfClass:SRShortcutItemCatalog.class])
        return NO;
    else
        return [aCatalog->_items isEqualToDictionary:_items];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)aZone
{
    SRShortcutItemCatalog *catalog = [self.class new];
    catalog->_items = [_items mutableCopy];
    return catalog;
}

#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    _items = [[aDecoder decodeObjectOfClass:NSDictionary.class forKey:@"items"] mutableCopy];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:SRBundle().infoDictionary[(__bridge NSString *)kCFBundleVersionKey] forKey:@"version"];
    [aCoder encodeObject:_items forKey:@"items"];
}

#pragma mark NSObject

- (BOOL)isEqual:(NSObject *)anObject
{
    return [self SR_isEqual:anObject usingSelector:@selector(isEqualToShortcutCatalog:) ofCommonAncestor:SRShortcutItemCatalog.class];
}

- (NSUInteger)hash
{
    return _items.hash;
}

@end


@interface NSObject (WL_SRShortcutItem)

- (void)undo:(id)aSender;
- (void)redo:(id)aSender;

@end


@implementation SRShortcutItemCatalog (SRCommonShortcuts)

+ (SRShortcutItemCatalog *)standard
{
    static SRShortcutItemCatalog *Catalog = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Catalog = [SRShortcutItemCatalog new];
        [Catalog addAction:@selector(moveForward:) forKeyEquivalent:@"⌃F"];
        [Catalog addAction:@selector(moveRight:) forKeyEquivalent:@"→"];
        [Catalog addAction:@selector(moveBackward:) forKeyEquivalent:@"⌃B"];
        [Catalog addAction:@selector(moveLeft:) forKeyEquivalent:@"←"];
        [Catalog addAction:@selector(moveUp:) forKeyEquivalent:@"↑"];
        [Catalog addAction:@selector(moveUp:) forKeyEquivalent:@"⌃P"];
        [Catalog addAction:@selector(moveDown:) forKeyEquivalent:@"↓"];
        [Catalog addAction:@selector(moveDown:) forKeyEquivalent:@"⌃N"];
        [Catalog addAction:@selector(moveWordForward:) forKeyEquivalent:@"⌥F"];
        [Catalog addAction:@selector(moveWordBackward:) forKeyEquivalent:@"⌥B"];
        [Catalog addAction:@selector(moveToBeginningOfLine:) forKeyEquivalent:@"⌃A"];
        [Catalog addAction:@selector(moveToEndOfLine:) forKeyEquivalent:@"⌃E"];
        [Catalog addAction:@selector(moveToEndOfDocument:) forKeyEquivalent:@"⌘↓"];
        [Catalog addAction:@selector(moveToBeginningOfDocument:) forKeyEquivalent:@"⌘↑"];
        [Catalog addAction:@selector(pageDown:) forKeyEquivalent:@"⌃V"];
        [Catalog addAction:@selector(pageUp:) forKeyEquivalent:@"⌥V"];
        [Catalog addAction:@selector(centerSelectionInVisibleArea:) forKeyEquivalent:@"⌃L"];
        [Catalog addAction:@selector(moveBackwardAndModifySelection:) forKeyEquivalent:@"⇧⌃B"];
        [Catalog addAction:@selector(moveForwardAndModifySelection:) forKeyEquivalent:@"⇧⌃F"];
        [Catalog addAction:@selector(moveWordForwardAndModifySelection:) forKeyEquivalent:@"⇧⌥F"];
        [Catalog addAction:@selector(moveWordBackwardAndModifySelection:) forKeyEquivalent:@"⇧⌥B"];
        [Catalog addAction:@selector(moveUpAndModifySelection:) forKeyEquivalent:@"⇧↑"];
        [Catalog addAction:@selector(moveUpAndModifySelection:) forKeyEquivalent:@"⇧⌃P"];
        [Catalog addAction:@selector(moveDownAndModifySelection:) forKeyEquivalent:@"⇧↓"];
        [Catalog addAction:@selector(moveDownAndModifySelection:) forKeyEquivalent:@"⇧⌃N"];
        [Catalog addAction:@selector(moveToBeginningOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌃A"];
        [Catalog addAction:@selector(moveToBeginningOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌘←"];
        [Catalog addAction:@selector(moveToEndOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌃E"];
        [Catalog addAction:@selector(moveToEndOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌘→"];
        [Catalog addAction:@selector(moveToEndOfDocumentAndModifySelection:) forKeyEquivalent:@"⇧⌘↓"];
        [Catalog addAction:@selector(moveToBeginningOfDocumentAndModifySelection:) forKeyEquivalent:@"⇧⌘↑"];
        [Catalog addAction:@selector(pageDownAndModifySelection:) forKeyEquivalent:@"⇧⌃V"];
        [Catalog addAction:@selector(pageUpAndModifySelection:) forKeyEquivalent:@"⇧⌥V"];
        [Catalog addAction:@selector(moveWordRight:) forKeyEquivalent:@"⌥→"];
        [Catalog addAction:@selector(moveWordLeft:) forKeyEquivalent:@"⌥←"];
        [Catalog addAction:@selector(moveRightAndModifySelection:) forKeyEquivalent:@"⇧→"];
        [Catalog addAction:@selector(moveLeftAndModifySelection:) forKeyEquivalent:@"⇧←"];
        [Catalog addAction:@selector(moveWordRightAndModifySelection:) forKeyEquivalent:@"⇧⌥→"];
        [Catalog addAction:@selector(moveWordLeftAndModifySelection:) forKeyEquivalent:@"⇧⌥←"];
        [Catalog addAction:@selector(moveToLeftEndOfLine:) forKeyEquivalent:@"⌘←"];
        [Catalog addAction:@selector(moveToRightEndOfLine:) forKeyEquivalent:@"⌘→"];
        [Catalog addAction:@selector(moveToLeftEndOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌘←"];
        [Catalog addAction:@selector(moveToRightEndOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌘→"];
        [Catalog addAction:@selector(scrollPageUp:) forKeyEquivalent:@"⇞"];
        [Catalog addAction:@selector(scrollPageDown:) forKeyEquivalent:@"⇟"];
        [Catalog addAction:@selector(scrollToBeginningOfDocument:) forKeyEquivalent:@"↖"];
        [Catalog addAction:@selector(scrollToEndOfDocument:) forKeyEquivalent:@"↘"];
        [Catalog addAction:@selector(transpose:) forKeyEquivalent:@"⌃T"];
        [Catalog addAction:@selector(transposeWords:) forKeyEquivalent:@"⌥T"];
        [Catalog addAction:@selector(selectAll:) forKeyEquivalent:@"⌘A"];
        [Catalog addAction:@selector(insertNewline:) forKeyEquivalent:@"⌃O"];
        [Catalog addAction:@selector(deleteForward:) forKeyEquivalent:@"⌦"];
        [Catalog addAction:@selector(deleteBackward:) forKeyEquivalent:@"⌫"];
        [Catalog addAction:@selector(deleteWordForward:) forKeyEquivalent:@"⌥⌦"];
        [Catalog addAction:@selector(deleteWordBackward:) forKeyEquivalent:@"⌥⌫"];
        [Catalog addAction:@selector(deleteToEndOfLine:) forKeyEquivalent:@"⌃K"];
        [Catalog addAction:@selector(deleteToBeginningOfLine:) forKeyEquivalent:@"⌃W"];
        [Catalog addAction:@selector(yank:) forKeyEquivalent:@"⌃Y"];
        [Catalog addAction:@selector(setMark:) forKeyEquivalent:@"⌃Space"];
        [Catalog addAction:@selector(complete:) forKeyEquivalent:@"⌥⎋"];
        [Catalog addAction:@selector(cancelOperation:) forKeyEquivalent:@"⌘."];
    });
    return [Catalog copy];
}

+ (SRShortcutItemCatalog *)mainMenu
{
    static SRShortcutItemCatalog *Catalog = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Catalog = [SRShortcutItemCatalog new];
        [Catalog addAction:@selector(hide:) forKeyEquivalent:@"⌘H"];
        [Catalog addAction:@selector(hideOtherApplications:) forKeyEquivalent:@"⌥⌘H"];
        [Catalog addAction:@selector(terminate:) forKeyEquivalent:@"⌘Q"];

        [Catalog addAction:@selector(newDocument:) forKeyEquivalent:@"⌘N"];
        [Catalog addAction:@selector(openDocument:) forKeyEquivalent:@"⌘O"];
        [Catalog addAction:@selector(performClose:) forKeyEquivalent:@"⌘W"];
        [Catalog addAction:@selector(saveDocument:) forKeyEquivalent:@"⌘S"];
        [Catalog addAction:@selector(saveDocumentAs:) forKeyEquivalent:@"⇧⌘S"];
        [Catalog addAction:@selector(revertDocumentToSaved:) forKeyEquivalent:@"⌘R"];
        [Catalog addAction:@selector(runPageLayout:) forKeyEquivalent:@"⇧⌘P"];
        [Catalog addAction:@selector(print:) forKeyEquivalent:@"⌘P"];


        [Catalog addAction:@selector(undo:) forKeyEquivalent:@"⌘Z"];
        [Catalog addAction:@selector(redo:) forKeyEquivalent:@"⇧⌘Z"];
        [Catalog addAction:@selector(cut:) forKeyEquivalent:@"⌘X"];
        [Catalog addAction:@selector(copy:) forKeyEquivalent:@"⌘C"];
        [Catalog addAction:@selector(paste:) forKeyEquivalent:@"⌘V"];
        [Catalog addAction:@selector(pasteAsPlainText:) forKeyEquivalent:@"⌥⇧⌘V"];
        [Catalog addAction:@selector(selectAll:) forKeyEquivalent:@"⌘A"];

        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌘F"]
                                                                  action:@selector(performFindPanelAction:)
                                                                     tag:1]]; // Find
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌥⌘F"]
                                                                  action:@selector(performFindPanelAction:)
                                                                     tag:12]]; // Find and Replace...
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌘G"]
                                                                  action:@selector(performFindPanelAction:)
                                                                     tag:2]]; // Find Next
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⇧⌘G"]
                                                                  action:@selector(performFindPanelAction:)
                                                                     tag:3]]; // Find Previous
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌘E"]
                                                                  action:@selector(performFindPanelAction:)
                                                                     tag:7]]; // Use Selection for Find
        [Catalog addAction:@selector(centerSelectionInVisibleArea:) forKeyEquivalent:@"⌘J"];

        [Catalog addAction:@selector(showGuessPanel:) forKeyEquivalent:@"⇧⌘;"];
        [Catalog addAction:@selector(checkSpelling:) forKeyEquivalent:@"⌘;"];

        [Catalog addAction:@selector(orderFrontFontPanel:) forKeyEquivalent:@"⌘T"];
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌘B"]
                                                                  action:@selector(addFontTrait:)
                                                                     tag:2]]; // Bold
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌘B"]
                                                                  action:@selector(addFontTrait:)
                                                                     tag:2]]; // Bold
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌘I"]
                                                                  action:@selector(addFontTrait:)
                                                                     tag:1]]; // Italic
        [Catalog addAction:@selector(underline:) forKeyEquivalent:@"⌘U"];
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌘+"]
                                                                  action:@selector(modifyFont:)
                                                                     tag:3]]; // Bigger
        [Catalog addItemsObject:[[SRShortcutItem alloc] initWithShortcut:[SRShortcut shortcutWithKeyEquivalent:@"⌘-"]
                                                                  action:@selector(modifyFont:)
                                                                     tag:4]]; // Bigger
        [Catalog addAction:@selector(orderFrontColorPanel:) forKeyEquivalent:@"⇧⌘C"];
        [Catalog addAction:@selector(copyFont:) forKeyEquivalent:@"⌥⌘C"];
        [Catalog addAction:@selector(pasteFont:) forKeyEquivalent:@"⌥⌘V"];

        [Catalog addAction:@selector(alignLeft:) forKeyEquivalent:@"⇧⌘["];
        [Catalog addAction:@selector(alignCenter:) forKeyEquivalent:@"⇧⌘\\"];
        [Catalog addAction:@selector(alignRight:) forKeyEquivalent:@"⇧⌘]"];
        [Catalog addAction:@selector(copyRuler:) forKeyEquivalent:@"⌃⌘C"];
        [Catalog addAction:@selector(pasteRuler:) forKeyEquivalent:@"⌃⌘V"];

        [Catalog addAction:@selector(toggleToolbarShown:) forKeyEquivalent:@"⌥⌘T"];
        [Catalog addAction:@selector(toggleSidebar:) forKeyEquivalent:@"⌃⌘S"];
        [Catalog addAction:@selector(toggleFullScreen:) forKeyEquivalent:@"⌃⌘F"];

        [Catalog addAction:@selector(performMiniaturize:) forKeyEquivalent:@"⌘M"];

        [Catalog addAction:@selector(showHelp:) forKeyEquivalent:@"⇧⌘/"];
    });
    return [Catalog copy];
}

+ (SRShortcutItemCatalog *)clipboard
{
    static SRShortcutItemCatalog *Catalog = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Catalog = [SRShortcutItemCatalog new];
        [Catalog addAction:@selector(cut:) forKeyEquivalent:@"⌘X"];
        [Catalog addAction:@selector(copy:) forKeyEquivalent:@"⌘C"];
        [Catalog addAction:@selector(paste:) forKeyEquivalent:@"⌘V"];
        [Catalog addAction:@selector(pasteAsPlainText:) forKeyEquivalent:@"⌥⇧⌘V"];
        [Catalog addAction:@selector(undo:) forKeyEquivalent:@"⌘Z"];
        [Catalog addAction:@selector(redo:) forKeyEquivalent:@"⇧⌘Z"];
    });
    return [Catalog copy];
}

+ (SRShortcutItemCatalog *)window
{
    static SRShortcutItemCatalog *Catalog = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Catalog = [SRShortcutItemCatalog new];
        [Catalog addAction:@selector(performClose:) forKeyEquivalent:@"⌘W"];
        [Catalog addAction:@selector(performMiniaturize:) forKeyEquivalent:@"⌘M"];
        [Catalog addAction:@selector(toggleFullScreen:) forKeyEquivalent:@"⌃⌘F"];
    });
    return [Catalog copy];
}

+ (SRShortcutItemCatalog *)document
{
    static SRShortcutItemCatalog *Catalog = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Catalog = [SRShortcutItemCatalog new];
        [Catalog addAction:@selector(print:) forKeyEquivalent:@"⌘P"];
        [Catalog addAction:@selector(runPageLayout:) forKeyEquivalent:@"⇧⌘P"];
        [Catalog addAction:@selector(revertDocumentToSaved:) forKeyEquivalent:@"⌘R"];
        [Catalog addAction:@selector(saveDocument:) forKeyEquivalent:@"⌘S"];
        [Catalog addAction:@selector(saveDocumentAs:) forKeyEquivalent:@"⇧⌥⌘S"];
        [Catalog addAction:@selector(duplicateDocument:) forKeyEquivalent:@"⇧⌘S"];
        [Catalog addAction:@selector(openDocument:) forKeyEquivalent:@"⌘O"];
    });
    return [Catalog copy];
}

+ (SRShortcutItemCatalog *)app
{
    static SRShortcutItemCatalog *Catalog = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Catalog = [SRShortcutItemCatalog new];
        [Catalog addAction:@selector(hide:) forKeyEquivalent:@"⌘H"];
        [Catalog addAction:@selector(hideOtherApplications:) forKeyEquivalent:@"⌥⌘H"];
        [Catalog addAction:@selector(terminate:) forKeyEquivalent:@"⌘Q"];
    });
    return [Catalog copy];
}

+ (NSDictionary<NSString *, id> *)_parseSystemKeyBindings
{
    NSBundle *appKitBundle = [NSBundle bundleWithIdentifier:@"com.apple.AppKit"];
    NSURL *systemKeyBindingsURL = [appKitBundle URLForResource:@"StandardKeyBinding" withExtension:@"dict"];
    NSDictionary *systemKeyBindings = nil;

    if (@available(macOS 10.13, *))
    {
        NSError *error = nil;
        systemKeyBindings = [NSDictionary dictionaryWithContentsOfURL:systemKeyBindingsURL error:&error];
        if (!systemKeyBindings)
        {
            os_trace_error_with_payload("#Error unable to read system key bindings", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "error", error.localizedDescription.UTF8String);
            });
            systemKeyBindings = @{};
        }
    }
    else
    {
        systemKeyBindings = [NSDictionary dictionaryWithContentsOfURL:systemKeyBindingsURL];
        if (!systemKeyBindings)
        {
            os_trace_error("#Error unable to read system key bindings");
            systemKeyBindings = @{};
        }
    }

    return systemKeyBindings;
}

+ (NSDictionary<NSString *, id> *)_parseUserKeyBindings
{
    NSURL *userKeyBindingsURL = [NSURL fileURLWithPath:[@"~/Library/KeyBindings/DefaultKeyBinding.dict" stringByExpandingTildeInPath]];
    NSDictionary *userKeyBindings = nil;

    if (@available(macOS 10.13, *))
    {
        NSError *error = nil;
        userKeyBindings = [NSDictionary dictionaryWithContentsOfURL:userKeyBindingsURL error:&error];
        if (!userKeyBindings)
        {
            os_trace_debug_with_payload("#Error unable to read user key bindings", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "error", error.localizedDescription.UTF8String);
            });
            userKeyBindings = @{};
        }
    }
    else
    {
        userKeyBindings = [NSDictionary dictionaryWithContentsOfURL:userKeyBindingsURL];
        if (!userKeyBindings)
        {
            os_trace_debug("#Error unable to read user key bindings");
            userKeyBindings = @{};
        }
    }

    return userKeyBindings;
}

- (void)updateWithCocoaTextKeyBindings
{
    __auto_type systemKeyBindings = [self.class _parseSystemKeyBindings];
    __auto_type userKeyBindings = [self.class _parseUserKeyBindings];

    NSMutableDictionary *keyBindings = [systemKeyBindings mutableCopy];
    [keyBindings addEntriesFromDictionary:userKeyBindings];

    [keyBindings enumerateKeysAndObjectsUsingBlock:^(NSString *aKey, NSString *aValue, BOOL *aStop) {
        if ([aValue isKindOfClass:NSArray.class])
            aValue = [(NSArray *)aValue firstObject];

        if (![aKey isKindOfClass:NSString.class] || !aKey.length)
            return;

        if (![aValue isKindOfClass:NSString.class])
            return;

        SRShortcut *shortcut = [SRShortcut shortcutWithKeyBinding:aKey];
        if (!shortcut)
        {
            os_trace_debug_with_payload("#Error unable to transform the key binding into a shortcut", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "binding", aKey.UTF8String);
            });
            return;
        }

        if (!aValue.length || [aValue isEqualToString:@"noop:"])
            self->_items[shortcut] = nil;
        else if (self->_items[shortcut] != nil)
            [self addAction:NSSelectorFromString(aValue) forShortcut:shortcut];
    }];
}

@end
