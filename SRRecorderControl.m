//
//  SRRecorderControl.m
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Ilya Kulakov

#import "SRRecorderControl.h"
#import "SRCommon.h"


NSString *const SRShortcutCodeKey = @"keyCode";

NSString *const SRShortcutFlagsKey = @"modifierFlags";

NSString *const SRShortcutCharacters = @"characters";

NSString *const SRShortcutCharactersIgnoringModifiers = @"charactersIgnoringModifiers";


#define SRCell (SRRecorderCell *)[self cell]


#define NilOrNull(o) ((o) == nil || (id)(o) == [NSNull null])


@implementation SRRecorderControl

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    if (self != nil)
    {
        self.translatesAutoresizingMaskIntoConstraints = YES;
        [SRCell setDelegate:self];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self != nil)
    {
        self.translatesAutoresizingMaskIntoConstraints = YES;
        [SRCell setDelegate:self];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Properties

- (BOOL)animates
{
    return [SRCell animates];
}

- (void)setAnimates:(BOOL)an
{
    [SRCell setAnimates:an];
}

- (SRRecorderStyle)style
{
    return [SRCell style];
}

- (void)setStyle:(SRRecorderStyle)nStyle
{
    [SRCell setStyle:nStyle];
}

- (NSUInteger)allowedFlags
{
    return [SRCell allowedFlags];
}

- (void)setAllowedFlags:(NSUInteger)flags
{
    [SRCell setAllowedFlags:flags];
}

- (BOOL)allowsKeyOnly
{
    return [SRCell allowsKeyOnly];
}

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord
{
    [SRCell setAllowsKeyOnly:nAllowsKeyOnly escapeKeysRecord:nEscapeKeysRecord];
}

- (BOOL)escapeKeysRecord
{
    return [SRCell escapeKeysRecord];
}

- (BOOL)canCaptureGlobalHotKeys
{
    return [[self cell] canCaptureGlobalHotKeys];
}

- (void)setCanCaptureGlobalHotKeys:(BOOL)inState
{
    [[self cell] setCanCaptureGlobalHotKeys:inState];
}

- (NSUInteger)requiredFlags
{
    return [SRCell requiredFlags];
}

- (void)setRequiredFlags:(NSUInteger)flags
{
    [SRCell setRequiredFlags:flags];
}

- (KeyCombo)keyCombo
{
    return [SRCell keyCombo];
}

- (NSString *)keyChars
{
    return [SRCell keyChars];
}

- (NSString *)keyCharsIgnoringModifiers
{
    return [SRCell keyCharsIgnoringModifiers];
}

- (void)setKeyCombo:(KeyCombo)newKeyCombo
           keyChars:(NSString *)newKeyChars
keyCharsIgnoringModifiers:(NSString *)newKeyCharsIgnoringModifiers
{
    [SRCell setKeyCombo:newKeyCombo
               keyChars:newKeyChars
keyCharsIgnoringModifiers:newKeyCharsIgnoringModifiers];
}

- (BOOL)isASCIIOnly
{
    return [SRCell isASCIIOnly];
}

- (void)setIsASCIIOnly:(BOOL)newIsASCIIOnly
{
    [SRCell setIsASCIIOnly:newIsASCIIOnly];
}

- (NSDictionary *)objectValue
{
    KeyCombo keyCombo = [self keyCombo];
    if ((keyCombo.code == ShortcutRecorderEmptyCode) ||
        (keyCombo.code != ShortcutRecorderEmptyCode &&
         keyCombo.flags == ShortcutRecorderEmptyFlags &&
         ![self allowsKeyOnly]))
    {
        return nil;
    }

    return @{
        SRShortcutCharactersIgnoringModifiers: self.keyCharsIgnoringModifiers,
        SRShortcutCharacters: self.keyChars,
        SRShortcutCodeKey: @(self.keyCombo.code),
        SRShortcutFlagsKey: @(self.keyCombo.flags)
    };
}

- (void)setObjectValue:(NSDictionary *)shortcut
{
    KeyCombo keyCombo = SRMakeKeyCombo(ShortcutRecorderEmptyCode, ShortcutRecorderEmptyFlags);
    NSString *keyChars = nil;
    NSString *keyCharsIgnoringModifiers = nil;
    if (shortcut != nil && [shortcut isKindOfClass:[NSDictionary class]])
    {
        NSNumber *keyCode = [shortcut objectForKey:SRShortcutCodeKey];
        NSNumber *modifierFlags = [shortcut objectForKey:SRShortcutFlagsKey];
        if ([keyCode isKindOfClass:[NSNumber class]] && [modifierFlags isKindOfClass:[NSNumber class]])
        {
            keyCombo.code = [keyCode integerValue];
            keyCombo.flags = [modifierFlags unsignedIntegerValue];
        }
        keyChars = [shortcut objectForKey:SRShortcutCharacters];
        keyCharsIgnoringModifiers = [shortcut objectForKey:SRShortcutCharactersIgnoringModifiers];
    }

    [self setKeyCombo:keyCombo keyChars:keyChars keyCharsIgnoringModifiers:keyCharsIgnoringModifiers];
}

// Only the delegate will be handled by the control
- (id)delegate
{
    return delegate;
}

- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (NSString *)keyComboString
{
    return [SRCell keyComboString];
}


#pragma mark Methods

- (NSUInteger)cocoaToCarbonFlags:(NSUInteger)cocoaFlags
{
    return SRCocoaToCarbonFlags(cocoaFlags);
}

- (NSUInteger)carbonToCocoaFlags:(NSUInteger)carbonFlags;
{
    return SRCarbonToCocoaFlags(carbonFlags);
}

- (void)resetTrackingRects
{
    [SRCell resetTrackingRects];
}


#pragma mark NSShortcutRecorderCell


- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
    if (delegate != nil && [delegate respondsToSelector:@selector(shortcutRecorder:isKeyCode:andFlagsTaken:reason:)])
        return [delegate shortcutRecorder:self isKeyCode:keyCode andFlagsTaken:flags reason:aReason];
    else
        return NO;
}

- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(KeyCombo)newKeyCombo
{
    if (delegate != nil && [delegate respondsToSelector:@selector(shortcutRecorder:keyComboDidChange:)])
        [delegate shortcutRecorder:self keyComboDidChange:newKeyCombo];

    // propagate view changes to binding (see http://www.tomdalling.com/cocoa/implementing-your-own-cocoa-bindings)
    NSDictionary *bindingInfo = [self infoForBinding:@"value"];
    if (!bindingInfo)
        return;

    // apply the value transformer, if one has been set
    NSDictionary *value = [self objectValue];
    NSDictionary *bindingOptions = [bindingInfo objectForKey:NSOptionsKey];
    if (bindingOptions != nil)
    {
        NSValueTransformer *transformer = [bindingOptions valueForKey:NSValueTransformerBindingOption];
        if (NilOrNull(transformer))
        {
            NSString *transformerName = [bindingOptions valueForKey:NSValueTransformerNameBindingOption];
            if (!NilOrNull(transformerName))
                transformer = [NSValueTransformer valueTransformerForName:transformerName];
        }

        if (!NilOrNull(transformer))
        {
            if ([[transformer class] allowsReverseTransformation])
                value = [transformer reverseTransformedValue:value];
            else
                NSLog(@"WARNING: value has value transformer, but it doesn't allow reverse transformations in %s", __PRETTY_FUNCTION__);
        }
    }

    id boundObject = [bindingInfo objectForKey:NSObservedObjectKey];
    if (NilOrNull(boundObject))
    {
        NSLog(@"ERROR: NSObservedObjectKey was nil for value binding in %s", __PRETTY_FUNCTION__);
        return;
    }

    NSString *boundKeyPath = [bindingInfo objectForKey:NSObservedKeyPathKey];
    if (NilOrNull(boundKeyPath))
    {
        NSLog(@"ERROR: NSObservedKeyPathKey was nil for value binding in %s", __PRETTY_FUNCTION__);
        return;
    }

    [boundObject setValue:value forKeyPath:boundKeyPath];
}

- (BOOL)shortcutRecorderCellShouldCheckMenu:(SRRecorderCell *)aRecorderCell
{
    if (delegate != nil && [delegate respondsToSelector:@selector(shortcutRecorderShouldCheckMenu:)])
        return [delegate shortcutRecorderShouldCheckMenu:self];
    else
        return NO;
}

- (BOOL)shortcutRecorderCellShouldSystemShortcuts:(SRRecorderCell *)aRecorderCell
{
    if (delegate != nil && [delegate respondsToSelector:@selector(shortcutRecorderShouldSystemShortcuts:)])
        return [delegate shortcutRecorderShouldSystemShortcuts:self];
    else
        return YES;
}


#pragma mark NSKeyValueBinding

- (Class)valueClassForBinding:(NSString *)binding
{
    if ([binding isEqualToString:@"value"])
        return [NSDictionary class];

    return [super valueClassForBinding:binding];
}


#pragma mark NSControl

+ (Class)cellClass
{
    return [SRRecorderCell class];
}


#pragma mark NSView

// If the control is set to be resizeable in width, this will make sure that the tracking rects are always updated
- (void)viewDidMoveToWindow
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center removeObserver:self];
    [center addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self];

    [self resetTrackingRects];
}

- (void)viewFrameDidChange:(NSNotification *)aNotification
{
    [self resetTrackingRects];
}

- (NSSize)fittingSize
{
    return NSMakeSize(SRMinWidth, SRMaxHeight);
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(SRMinWidth, SRMaxHeight);
}


#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL okToChange = [SRCell becomeFirstResponder];

    if (okToChange)
        [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];

    return okToChange;
}

- (BOOL)resignFirstResponder
{
    BOOL okToChange = [SRCell resignFirstResponder];

    if (okToChange)
        [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];

    return okToChange;
}


// Like most NSControls, pass things on to the cell
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    // Only if we're key, please. Otherwise hitting Space after having
    // tabbed past SRRecorderControl will put you into recording mode.
    if (([[[self window] firstResponder] isEqualTo:self]))
    {
        if ([SRCell performKeyEquivalent:theEvent]) return YES;
    }

    return [super performKeyEquivalent:theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    [SRCell flagsChanged:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent
{
    if ([SRCell performKeyEquivalent:theEvent])
        return;

    [super keyDown:theEvent];
}

@end
