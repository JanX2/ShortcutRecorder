//
//  SRRecorderControl.m
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

#include <limits.h>

#import "SRRecorderControl.h"
#import "SRKeyCodeTransformer.h"
#import "SRModifierFlagsTransformer.h"


typedef NS_ENUM(NSUInteger, _SRRecorderControlButtonTag)
{
    _SRRecorderControlInvalidButtonTag = -1,
    _SRRecorderControlCancelButtonTag = 0,
    _SRRecorderControlClearButtonTag = 1,
    _SRRecorderControlMainButtonTag = 2
};


@implementation SRRecorderControl
{
    NSTrackingArea *_mainButtonTrackingArea;
    NSTrackingArea *_cancelButtonTrackingArea;
    NSTrackingArea *_clearButtonTrackingArea;

    _SRRecorderControlButtonTag _mouseTrackingButtonTag;
    NSToolTipTag _cancelButtonToolTipTag;

    SRShortcut *_objectValue;
}

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self)
    {
        [self _initInternalState];
    }

    return self;
}

- (void)_initInternalState
{
    _allowsEmptyModifierFlags = NO;
    _drawsASCIIEquivalentOfShortcut = YES;
    _allowsEscapeToCancelRecording = YES;
    _allowsDeleteToClearShortcutAndEndRecording = YES;
    _enabled = YES;
    _allowedModifierFlags = SRCocoaModifierFlagsMask;
    _requiredModifierFlags = 0;
    _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
    _cancelButtonToolTipTag = NSIntegerMax;

    self.translatesAutoresizingMaskIntoConstraints = NO;

    [self setContentHuggingPriority:NSLayoutPriorityDefaultLow
                     forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentHuggingPriority:NSLayoutPriorityRequired
                     forOrientation:NSLayoutConstraintOrientationVertical];

    [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                   forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                   forOrientation:NSLayoutConstraintOrientationVertical];

    self.style = nil;
    self.toolTip = SRLoc(@"Click to record shortcut");
    // TODO: seems to be unnecessary
    [self updateTrackingAreas];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
}


#pragma mark Properties

+ (BOOL)automaticallyNotifiesObserversOfObjectValue
{
    return NO;
}

- (void)setAllowedModifierFlags:(NSEventModifierFlags)newAllowedModifierFlags
          requiredModifierFlags:(NSEventModifierFlags)newRequiredModifierFlags
       allowsEmptyModifierFlags:(BOOL)newAllowsEmptyModifierFlags
{
    newAllowedModifierFlags &= SRCocoaModifierFlagsMask;
    newRequiredModifierFlags &= SRCocoaModifierFlagsMask;

    if ((newAllowedModifierFlags & newRequiredModifierFlags) != newRequiredModifierFlags)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Required flags (%lu) MUST be allowed (%lu)", newAllowedModifierFlags, newRequiredModifierFlags];
    }

    if (newAllowsEmptyModifierFlags && newRequiredModifierFlags != 0)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Empty modifier flags MUST be disallowed if required modifier flags are not empty."];
    }

    if (newAllowedModifierFlags == _allowedModifierFlags &&
        newRequiredModifierFlags == _requiredModifierFlags &&
        newAllowsEmptyModifierFlags == _allowsEmptyModifierFlags)
    {
        return;
    }

    [self endRecording];

    [self willChangeValueForKey:@"allowedModifierFlags"];
    [self willChangeValueForKey:@"requiredModifierFlags"];
    [self willChangeValueForKey:@"allowsEmptyModifierFlags"];
    _allowedModifierFlags = newAllowedModifierFlags;
    _requiredModifierFlags = newRequiredModifierFlags;
    _allowsEmptyModifierFlags = newAllowsEmptyModifierFlags;
    [self didChangeValueForKey:@"allowedModifierFlags"];
    [self didChangeValueForKey:@"requiredModifierFlags"];
    [self didChangeValueForKey:@"allowsEmptyModifierFlags"];
}

- (void)setEnabled:(BOOL)newEnabled
{
    if (newEnabled == _enabled)
        return;

    _enabled = newEnabled;
    self.needsDisplay = YES;

    if (!_enabled)
        [self endRecording];

    [self noteFocusRingMaskChanged];
}

- (SRShortcut *)objectValue
{
    if (_isCompatibilityModeEnabled)
        return (id)_objectValue.dictionaryRepresentation;
    else
        return _objectValue;
}

- (void)setObjectValue:(SRShortcut *)newObjectValue
{
    if (newObjectValue == _objectValue || [newObjectValue isEqual:_objectValue])
        return;

    [self willChangeValueForKey:@"objectValue"];
    // Cocoa KVO and KVC frequently uses NSNull as object substituation of nil.
    // SRRecorderControl expects either nil or valid object value, it's convenient
    // to handle NSNull here and convert it into nil.
    if ((NSNull *)newObjectValue == NSNull.null)
        newObjectValue = nil;
    // Backward compatibility with Shortcut Recorder 2
    else if ([newObjectValue isKindOfClass:NSDictionary.class] && _objectValue == nil)
    {
        NSLog(@"WARNING: Shortcut Recroder 2 compatibility mode enabled. Getters of objectValue and NSValueBinding will return an instance of NSDictionary.");
        _isCompatibilityModeEnabled = YES;
        newObjectValue = [SRShortcut shortcutWithDictionary:(NSDictionary *)newObjectValue];
    }

    _objectValue = [newObjectValue copy];
    [self didChangeValueForKey:@"objectValue"];

    if (_isCompatibilityModeEnabled)
        [self propagateValue:_objectValue.dictionaryRepresentation forBinding:NSValueBinding];
    else
        [self propagateValue:_objectValue forBinding:NSValueBinding];

    if (!self.isRecording)
    {
        NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);
        [self setNeedsDisplayInRect:self.style.labelDrawingGuide.frame];
    }
}

- (NSDictionary<SRShortcutKey, id> *)dictionaryValue
{
    return _objectValue.dictionaryRepresentation;
}

- (void)setDictionaryValue:(NSDictionary<SRShortcutKey, id> *)newDictionaryValue
{
    self.objectValue = [SRShortcut shortcutWithDictionary:newDictionaryValue];
}

- (void)setStyle:(SRRecorderControlStyle *)newStyle
{
    if (newStyle == nil)
    {
        if (@available(macOS 10.14, *))
            newStyle = [SRRecorderControlStyle styleWithPrefix:@"sr-mojave"];
        else
            newStyle = [SRRecorderControlStyle styleWithPrefix:@"sr-yosemite"];
    }

    _style = newStyle;
    _style.controlView = self;

    [self updateActiveConstraints];
}


#pragma mark Methods

- (BOOL)beginRecording
{
    if (!self.enabled)
        return NO;

    if (self.isRecording)
        return YES;

    self.needsDisplay = YES;

    if ([self.delegate respondsToSelector:@selector(shortcutRecorderShouldBeginRecording:)])
    {
        if (![self.delegate shortcutRecorderShouldBeginRecording:self])
        {
            NSBeep();
            return NO;
        }
    }

    NSDictionary *bindingInfo = [self infoForBinding:NSValueBinding];
    if (bindingInfo)
    {
        id controller = bindingInfo[NSObservedObjectKey];
        if ([controller respondsToSelector:@selector(objectDidBeginEditing:)])
            [controller objectDidBeginEditing:(id<NSEditor>) self];
    }

    [self willChangeValueForKey:@"isRecording"];
    _isRecording = YES;
    [self didChangeValueForKey:@"isRecording"];

    [self updateActiveConstraints];
    [self updateTrackingAreas];
    self.toolTip = SRLoc(@"Type shortcut");
    NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);

    return YES;
}

- (void)endRecording
{
    [self endRecordingWithObjectValue:_objectValue];
}

- (void)clearAndEndRecording
{
    [self endRecordingWithObjectValue:nil];
}

- (void)endRecordingWithObjectValue:(SRShortcut *)anObjectValue
{
    if (!self.isRecording)
        return;

    NSDictionary *bindingInfo = [self infoForBinding:NSValueBinding];
    if (bindingInfo)
    {
        id controller = bindingInfo[NSObservedObjectKey];
        if ([controller respondsToSelector:@selector(objectDidEndEditing:)])
            [controller objectDidEndEditing:(id<NSEditor>)self];
    }

    [self willChangeValueForKey:@"isRecording"];
    _isRecording = NO;
    [self didChangeValueForKey:@"isRecording"];

    self.objectValue = anObjectValue;

    [self updateActiveConstraints];
    [self updateTrackingAreas];
    self.toolTip = SRLoc(@"Click to record shortcut");
    self.needsDisplay = YES;
    NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);

    if (self.window.firstResponder == self && !self.canBecomeKeyView)
        [self.window makeFirstResponder:nil];

    if ([self.delegate respondsToSelector:@selector(shortcutRecorderDidEndRecording:)])
        [self.delegate shortcutRecorderDidEndRecording:self];
}


#pragma mark -

- (void)updateActiveConstraints
{
    [NSLayoutConstraint activateConstraints:_style.alwaysConstraints];

    if (self.isRecording && _objectValue)
    {
        [NSLayoutConstraint deactivateConstraints:self.style.displayingConstraints];
        [NSLayoutConstraint deactivateConstraints:self.style.recordingWithNoValueConstraints];
        [NSLayoutConstraint activateConstraints:self.style.recordingWithValueConstraints];
    }
    else if (self.isRecording)
    {
        [NSLayoutConstraint deactivateConstraints:self.style.displayingConstraints];
        [NSLayoutConstraint deactivateConstraints:self.style.recordingWithValueConstraints];
        [NSLayoutConstraint activateConstraints:self.style.recordingWithNoValueConstraints];
    }
    else
    {
        [NSLayoutConstraint deactivateConstraints:self.style.recordingWithNoValueConstraints];
        [NSLayoutConstraint deactivateConstraints:self.style.recordingWithValueConstraints];
        [NSLayoutConstraint activateConstraints:self.style.displayingConstraints];
    }
}

- (NSBezierPath *)controlShape
{
    NSRect alignmentFrame = self.style.alignmentGuide.frame;
    NSEdgeInsets shapeInsets = self.style.shapeInsets;
    NSSize shapeCornerRadius = self.style.shapeCornerRadius;

    alignmentFrame.origin.x += shapeInsets.left;
    alignmentFrame.origin.y += shapeInsets.top;
    alignmentFrame.size.width = fdim(alignmentFrame.size.width, shapeInsets.left + shapeInsets.right);
    alignmentFrame.size.height = fdim(alignmentFrame.size.height, shapeInsets.top + shapeInsets.bottom);
    return [NSBezierPath bezierPathWithRoundedRect:alignmentFrame xRadius:shapeCornerRadius.width yRadius:shapeCornerRadius.height];
}


#pragma mark -

- (NSString *)label
{
    NSString *label = nil;

    if (self.isRecording)
    {
        NSEventModifierFlags modifierFlags = [NSEvent modifierFlags] & self.allowedModifierFlags;

        if (modifierFlags)
            label = [SRModifierFlagsTransformer.sharedSymbolicTransformer transformedValue:@(modifierFlags)];
        else
            label = self.stringValue;

        if (!label.length)
            label = SRLoc(@"Type shortcut");
    }
    else
    {
        label = self.stringValue;

        if (!label.length)
            label = SRLoc(@"Click to record shortcut");
    }

    return label;
}

- (NSString *)accessibilityLabel
{
    NSString *label = nil;

    if (self.isRecording)
    {
        NSEventModifierFlags modifierFlags = [NSEvent modifierFlags] & self.allowedModifierFlags;
        label = [SRModifierFlagsTransformer.sharedLiteralTransformer transformedValue:@(modifierFlags)];

        if (!label.length)
            label = SRLoc(@"Type shortcut");
    }
    else
    {
        label = self.accessibilityStringValue;

        if (!label.length)
            label = SRLoc(@"Click to record shortcut");
    }

    return label;
}

- (NSString *)stringValue
{
    if (!_objectValue)
        return nil;

    NSString *flags = [SRModifierFlagsTransformer.sharedSymbolicTransformer transformedValue:@(_objectValue.modifierFlags)];
    SRKeyCodeTransformer *transformer = nil;

    if (self.drawsASCIIEquivalentOfShortcut)
        transformer = SRKeyCodeTransformer.sharedLiteralASCIITransformer;
    else
        transformer = SRKeyCodeTransformer.sharedLiteralTransformer;

    NSString *code = [transformer transformedValue:@(_objectValue.keyCode)
                      withImplicitModifierFlags:nil
                          explicitModifierFlags:@(_objectValue.modifierFlags)];

    return [NSString stringWithFormat:@"%@%@", flags, code];
}

- (NSString *)accessibilityStringValue
{
    if (!_objectValue)
        return nil;

    NSString *f = [SRModifierFlagsTransformer.sharedLiteralTransformer transformedValue:@(_objectValue.modifierFlags)];
    NSString *c = nil;

    if (self.drawsASCIIEquivalentOfShortcut)
        c = [SRKeyCodeTransformer.sharedLiteralASCIITransformer transformedValue:@(_objectValue.keyCode)];
    else
        c = [SRKeyCodeTransformer.sharedLiteralTransformer transformedValue:@(_objectValue.keyCode)];

    if (f.length > 0)
        return [NSString stringWithFormat:@"%@-%@", f, c];
    else
        return [NSString stringWithFormat:@"%@", c];
}

- (NSDictionary *)labelAttributes
{
    if (self.enabled)
    {
        if (self.isRecording)
            return self.style.recordingLabelAttributes;
        else
            return self.style.normalLabelAttributes;
    }
    else
        return self.style.disabledLabelAttributes;
}


#pragma mark -

- (void)drawBackground:(NSRect)aDirtyRect
{
    NSRect backgroundFrame = [self centerScanRect:self.style.backgroundDrawingGuide.frame];

    if (NSIsEmptyRect(backgroundFrame) || ![self needsToDrawRect:backgroundFrame])
        return;

    NSImage *left = nil;
    NSImage *center = nil;
    NSImage *right = nil;

    [NSGraphicsContext saveGraphicsState];

    if (self.isRecording)
    {
        left = self.style.bezelRecordingLeft;
        center = self.style.bezelRecordingCenter;
        right = self.style.bezelRecordingRight;
    }
    else
    {
        if (self.isMainButtonHighlighted)
        {
            left = self.style.bezelPressedLeft;
            center = self.style.bezelPressedCenter;
            right = self.style.bezelPressedRight;
        }
        else if (self.enabled)
        {
            left = self.style.bezelNormalLeft;
            center = self.style.bezelNormalCenter;
            right = self.style.bezelNormalRight;
        }
        else
        {
            left = self.style.bezelDisabledLeft;
            center = self.style.bezelDisabledCenter;
            right = self.style.bezelDisabledRight;
        }
    }

    NSDrawThreePartImage(backgroundFrame, left, center, right, NO, NSCompositeSourceOver, 1.0, self.isFlipped);
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawInterior:(NSRect)aDirtyRect
{
    [self drawLabel:aDirtyRect];

    if (self.isRecording)
    {
        [self drawCancelButton:aDirtyRect];

        if (_objectValue)
            [self drawClearButton:aDirtyRect];
    }
}

- (void)drawLabel:(NSRect)aDirtyRect
{
    NSRect labelFrame = self.style.labelDrawingGuide.frame;

    if (NSIsEmptyRect(labelFrame) || ![self needsToDrawRect:labelFrame])
        return;

    NSString *label = self.label;
    NSDictionary *labelAttributes = self.labelAttributes;

    [NSGraphicsContext saveGraphicsState];
    // Constant at the end compensates for drawing in the flipped graphics context.
    labelFrame.origin.y = NSMaxY(labelFrame) - self.baselineOffsetFromBottom + 1.0 / self.backingScaleFactor;
    [label drawWithRect:labelFrame options:0 attributes:labelAttributes context:nil];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawCancelButton:(NSRect)aDirtyRect
{
    NSRect cancelButtonFrame = [self centerScanRect:self.style.cancelButtonDrawingGuide.frame];

    if (NSIsEmptyRect(cancelButtonFrame) || ![self needsToDrawRect:cancelButtonFrame])
        return;

    [NSGraphicsContext saveGraphicsState];
    NSImage *image = self.isCancelButtonHighlighted ? self.style.cancelButtonPressed : self.style.cancelButton;
    [image drawInRect:cancelButtonFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawClearButton:(NSRect)aDirtyRect
{
    NSRect clearButtonFrame = [self centerScanRect:self.style.clearButtonDrawingGuide.frame];

    if (NSIsEmptyRect(clearButtonFrame) || ![self needsToDrawRect:clearButtonFrame])
        return;

    [NSGraphicsContext saveGraphicsState];
    NSImage *image = self.isClearButtonHighlighted ? self.style.clearButtonPressed : self.style.clearButton;
    [image drawInRect:clearButtonFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    [NSGraphicsContext restoreGraphicsState];
}

#pragma mark -

- (BOOL)isMainButtonHighlighted
{
    if (_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag)
    {
        NSPoint locationInView = [self convertPoint:self.window.mouseLocationOutsideOfEventStream
                                           fromView:nil];
        return [self mouse:locationInView inRect:self.bounds];
    }
    else
        return NO;
}

- (BOOL)isCancelButtonHighlighted
{
    if (_mouseTrackingButtonTag == _SRRecorderControlCancelButtonTag)
    {
        NSPoint locationInView = [self convertPoint:self.window.mouseLocationOutsideOfEventStream
                                           fromView:nil];
        return [self mouse:locationInView inRect:self.style.cancelButtonLayoutGuide.frame];
    }
    else
        return NO;
}

- (BOOL)isClearButtonHighlighted
{
    if (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag)
    {
        NSPoint locationInView = [self convertPoint:self.window.mouseLocationOutsideOfEventStream
                                           fromView:nil];
        return [self mouse:locationInView inRect:self.self.style.clearButtonLayoutGuide.frame];
    }
    else
        return NO;
}

- (BOOL)areModifierFlagsValid:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode
{
    aModifierFlags &= SRCocoaModifierFlagsMask;

    if ([self.delegate respondsToSelector:@selector(shortcutRecorder:shouldUnconditionallyAllowModifierFlags:forKeyCode:)] &&
        [self.delegate shortcutRecorder:self shouldUnconditionallyAllowModifierFlags:aModifierFlags forKeyCode:aKeyCode])
    {
        return YES;
    }
    else if (aModifierFlags == 0 && !self.allowsEmptyModifierFlags)
        return NO;
    else if ((aModifierFlags & self.requiredModifierFlags) != self.requiredModifierFlags)
        return NO;
    else if ((aModifierFlags & self.allowedModifierFlags) != aModifierFlags)
        return NO;
    else
        return YES;
}


#pragma mark -

- (void)propagateValue:(id)aValue forBinding:(NSString *)aBinding
{
    NSParameterAssert(aBinding != nil);

    NSDictionary* bindingInfo = [self infoForBinding:aBinding];

    if(!bindingInfo || (id)bindingInfo == NSNull.null)
        return;

    NSObject *boundObject = bindingInfo[NSObservedObjectKey];

    if(!boundObject || (id)boundObject == NSNull.null)
        [NSException raise:NSInternalInconsistencyException format:@"NSObservedObjectKey MUST NOT be nil for binding \"%@\"", aBinding];

    NSString* boundKeyPath = bindingInfo[NSObservedKeyPathKey];

    if(!boundKeyPath || (id)boundKeyPath == NSNull.null)
        [NSException raise:NSInternalInconsistencyException format:@"NSObservedKeyPathKey MUST NOT be nil for binding \"%@\"", aBinding];

    NSDictionary* bindingOptions = bindingInfo[NSOptionsKey];

    if(bindingOptions)
    {
        NSValueTransformer* transformer = [bindingOptions valueForKey:NSValueTransformerBindingOption];

        if(!transformer || (id)transformer == NSNull.null)
        {
            NSString* transformerName = [bindingOptions valueForKey:NSValueTransformerNameBindingOption];

            if(transformerName && (id)transformerName != NSNull.null)
                transformer = [NSValueTransformer valueTransformerForName:transformerName];
        }

        if(transformer && (id)transformer != NSNull.null)
        {
            if([[transformer class] allowsReverseTransformation])
                aValue = [transformer reverseTransformedValue:aValue];
#ifdef DEBUG
            else
                NSLog(@"WARNING: binding \"%@\" has value transformer, but it doesn't allow reverse transformations in %s", aBinding, __PRETTY_FUNCTION__);
#endif
        }
    }

    [boundObject setValue:aValue forKeyPath:boundKeyPath];
}

+ (BOOL)automaticallyNotifiesObserversOfValue
{
    return NO;
}

- (void)setValue:(id)newValue
{
    if (NSIsControllerMarker(newValue))
        [NSException raise:NSInternalInconsistencyException format:@"SRRecorderControl's NSValueBinding does not support controller value markers."];

    self.objectValue = newValue;
}

- (id)value
{
    return self.objectValue;
}

#pragma mark -

- (void)controlTintDidChange:(NSNotification *)aNotification
{
    [self.style controlAppearanceDidChange:aNotification];
}

- (void)accessibilityDisplayOptionsDidChange:(NSNotification *)aNotification
{
    [self.style controlAppearanceDidChange:aNotification];
}

- (CGFloat)backingScaleFactor
{
    CGFloat f = self.window.backingScaleFactor;

    if (f == 0.0)
    {
        CGSize deviceSize = CGContextConvertSizeToDeviceSpace(NSGraphicsContext.currentContext.CGContext, NSMakeSize(1.0, 1.0));

        if (deviceSize.height)
            f = deviceSize.height;
        else if (deviceSize.width)
            f = deviceSize.width;
        else
            f = 1.0;
    }

    return f;
}

#pragma mark NSAccessibility

- (BOOL)accessibilityIsIgnored
{
    return NO;
}

- (NSArray *)accessibilityAttributeNames
{
    static NSArray *AttributeNames = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^
    {
        AttributeNames = [[super accessibilityAttributeNames] mutableCopy];
        NSArray *newAttributes = @[
            NSAccessibilityRoleAttribute,
            NSAccessibilityTitleAttribute,
            NSAccessibilityEnabledAttribute
        ];

        for (NSString *attributeName in newAttributes)
        {
            if (![AttributeNames containsObject:attributeName])
                [(NSMutableArray *)AttributeNames addObject:attributeName];
        }

        AttributeNames = [AttributeNames copy];
    });
    return AttributeNames;
}

- (id)accessibilityAttributeValue:(NSString *)anAttributeName
{
    if ([anAttributeName isEqualToString:NSAccessibilityRoleAttribute])
        return NSAccessibilityButtonRole;
    else if ([anAttributeName isEqualToString:NSAccessibilityTitleAttribute])
        return self.accessibilityLabel;
    else if ([anAttributeName isEqualToString:NSAccessibilityEnabledAttribute])
        return @(self.enabled);
    else
        return [super accessibilityAttributeValue:anAttributeName];
}

- (NSArray *)accessibilityActionNames
{
    static NSArray *AllActions = nil;
    static NSArray *ButtonStateActionNames = nil;
    static NSArray *RecorderStateActionNames = nil;

    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^
    {
        AllActions = @[
            NSAccessibilityPressAction,
            NSAccessibilityCancelAction,
            NSAccessibilityDeleteAction
        ];

        ButtonStateActionNames = @[
            NSAccessibilityPressAction
        ];

        RecorderStateActionNames = @[
            NSAccessibilityCancelAction,
            NSAccessibilityDeleteAction
        ];
    });

    // List of supported actions names must be fixed for 10.6, but can vary for 10.7 and above.
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
    {
        if (self.enabled)
        {
            if (self.isRecording)
                return RecorderStateActionNames;
            else
                return ButtonStateActionNames;
        }
        else
            return @[];
    }
    else
        return AllActions;
}

- (NSString *)accessibilityActionDescription:(NSString *)anAction
{
    return NSAccessibilityActionDescription(anAction);
}

- (void)accessibilityPerformAction:(NSString *)anAction
{
    if ([anAction isEqualToString:NSAccessibilityPressAction])
        [self beginRecording];
    else if (self.isRecording && [anAction isEqualToString:NSAccessibilityCancelAction])
        [self endRecording];
    else if (self.isRecording && [anAction isEqualToString:NSAccessibilityDeleteAction])
        [self clearAndEndRecording];
}


#pragma mark NSEditor

- (BOOL)commitEditing
{
    // Shortcuts recording is atomic (either all or nothing) and there are no pending changes.
    [self discardEditing];
    return YES;
}

- (void)commitEditingWithDelegate:(id)aDelegate didCommitSelector:(SEL)aDidCommitSelector contextInfo:(void *)aContextInfo
{
    BOOL isEditingCommited = [self commitEditing];
    // See AppKit's __NSSendCommitEditingSelector
    NSInvocation *i = [NSInvocation invocationWithMethodSignature:[aDelegate methodSignatureForSelector:aDidCommitSelector]];
    [i setSelector:aDidCommitSelector];
    [i setArgument:(void*)&self atIndex:2];
    [i setArgument:&isEditingCommited atIndex:3];
    [i setArgument:&aContextInfo atIndex:4];
    [i retainArguments];
    [i performSelector:@selector(invokeWithTarget:) withObject:aDelegate afterDelay:0 inModes:@[NSRunLoopCommonModes]];
}

- (BOOL)commitEditingAndReturnError:(NSError **)outError
{
    return [self commitEditing];
}

- (void)discardEditing
{
    [self endRecording];
}


#pragma mark NSNibLoading

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    self.objectValue = [SRShortcut shortcutWithCode:0
                                      modifierFlags:NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift | NSEventModifierFlagCommand
                                         characters:@""
                        charactersIgnoringModifiers:@"a"];
}


#pragma mark NSViewToolTipOwner

- (NSString *)view:(NSView *)aView stringForToolTip:(NSToolTipTag)aTag point:(NSPoint)aPoint userData:(void *)aData
{
    if (aTag == _cancelButtonToolTipTag)
        return SRLoc(@"Use old shortcut");
    else
        return [super view:aView stringForToolTip:aTag point:aPoint userData:aData];
}


#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    // Since Xcode 6.x, user can configure xib to Prefer Coder.
    // In that case view will be instantiated with initWithCoder.
    //
    // awakeFromNib cannot be used to set up defaults for IBDesignable,
    // because at the time it's called, it's impossible to know whether properties
    // were set by a user in xib or they are compilation-time defaults.
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _initInternalState];
    }

    return self;
}


#pragma mark NSView

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (BOOL)isOpaque
{
    return self.style.isOpaque;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)layout
{
    NSRect oldLabelFrame = self.style.labelDrawingGuide.frame;
    NSRect oldCancelButtonFrame = self.style.cancelButtonDrawingGuide.frame;
    NSRect oldClearButtonFrame = self.style.clearButtonDrawingGuide.frame;

    [super layout];

    NSRect newLabelFrame = self.style.labelDrawingGuide.frame;
    NSRect newCancelButtonFrame = self.style.cancelButtonDrawingGuide.frame;
    NSRect newClearButtonFrame = self.style.clearButtonDrawingGuide.frame;

    if (!NSEqualRects(oldLabelFrame, newLabelFrame))
    {
        [self setNeedsDisplayInRect:oldLabelFrame];
        [self setNeedsDisplayInRect:newLabelFrame];
    }

    if (!NSEqualRects(oldCancelButtonFrame, newCancelButtonFrame))
    {
        [self setNeedsDisplayInRect:oldCancelButtonFrame];
        [self setNeedsDisplayInRect:newCancelButtonFrame];
    }

    if (!NSEqualRects(oldClearButtonFrame, newClearButtonFrame))
    {
        [self setNeedsDisplayInRect:oldClearButtonFrame];
        [self setNeedsDisplayInRect:newClearButtonFrame];
    }
}

- (void)drawRect:(NSRect)aDirtyRect
{
    [self drawBackground:aDirtyRect];
    [self drawInterior:aDirtyRect];
}

- (void)drawFocusRingMask
{
    if (self.enabled && self.window.firstResponder == self)
        [self.controlShape fill];
}

- (NSRect)focusRingMaskBounds
{
    if (self.enabled && self.window.firstResponder == self)
        return self.controlShape.bounds;
    else
        return NSZeroRect;
}

- (NSEdgeInsets)alignmentRectInsets
{
    return self.style.alignmentRectInsets;
}

- (CGFloat)baselineOffsetFromBottom
{
    return self.style.baselineOffsetFromBottom;
}

- (CGFloat)firstBaselineOffsetFromTop
{
    return self.style.alignmentGuide.frame.size.height - self.baselineOffsetFromBottom;
}

- (void)updateTrackingAreas
{
    static const NSTrackingAreaOptions TrackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder | NSTrackingEnabledDuringMouseDrag;

    if (_mainButtonTrackingArea)
        [self removeTrackingArea:_mainButtonTrackingArea];

    _mainButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                        options:TrackingOptions
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:_mainButtonTrackingArea];

    if (_cancelButtonTrackingArea)
    {
        [self removeTrackingArea:_cancelButtonTrackingArea];
        _cancelButtonTrackingArea = nil;
    }

    if (_clearButtonTrackingArea)
    {
        [self removeTrackingArea:_clearButtonTrackingArea];
        _clearButtonTrackingArea = nil;
    }

    if (_cancelButtonToolTipTag != NSIntegerMax)
    {
        [self removeToolTip:_cancelButtonToolTipTag];
        _cancelButtonToolTipTag = NSIntegerMax;
    }

    if (self.isRecording)
    {
        _cancelButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:self.style.cancelButtonLayoutGuide.frame
                                                                 options:TrackingOptions
                                                                   owner:self
                                                                userInfo:nil];
        [self addTrackingArea:_cancelButtonTrackingArea];

        if (_objectValue)
        {
            _clearButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:self.style.clearButtonLayoutGuide.frame
                                                                    options:TrackingOptions
                                                                      owner:self
                                                                   userInfo:nil];
            [self addTrackingArea:_clearButtonTrackingArea];
        }

        // Since this method is used to set up tracking rects of aux buttons, the rest of the code is aware
        // it should be called whenever geometry or apperance changes. Therefore it's a good place to set up tooltip rects.
        _cancelButtonToolTipTag = [self addToolTipRect:_cancelButtonTrackingArea.rect owner:self userData:NULL];
    }

    [super updateTrackingAreas];
}

- (void)updateConstraints
{
    [self updateActiveConstraints];
    [super updateConstraints];
}

- (void)viewWillMoveToWindow:(NSWindow *)aWindow
{
    // We want control to end recording whenever window resigns first responder status.
    // Otherwise we could end up with "dangling" recording.
    if (self.window)
    {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:NSWindowDidResignKeyNotification
                                                    object:self.window];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:NSControlTintDidChangeNotification
                                                    object:NSApp];
        [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self
                                                                  name:NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification
                                                                object:nil];
    }

    if (aWindow)
    {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(endRecording)
                                                   name:NSWindowDidResignKeyNotification
                                                 object:aWindow];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(controlTintDidChange:)
                                                   name:NSControlTintDidChangeNotification
                                                 object:NSApp];
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self
                                                           selector:@selector(accessibilityDisplayOptionsDidChange:) name:NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification
                                                             object:nil];
    }

    [super viewWillMoveToWindow:aWindow];
}

- (void)viewDidChangeBackingProperties
{
    [super viewDidChangeBackingProperties];
    [self.style controlAppearanceDidChange:nil];
}

- (void)viewDidChangeEffectiveAppearance
{
    [super viewDidChangeEffectiveAppearance];
    [self.style controlAppearanceDidChange:nil];
}


#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
    return self.enabled;
}

- (BOOL)becomeFirstResponder
{
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        [self setKeyboardFocusRingNeedsDisplayInRect:self.bounds];

    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        [self setKeyboardFocusRingNeedsDisplayInRect:self.bounds];

    [self endRecording];
    _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
    return [super resignFirstResponder];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent
{
    return YES;
}

- (BOOL)canBecomeKeyView
{
    // SRRecorderControl uses the button metaphor, but buttons cannot become key unless
    // Full Keyboard Access is enabled. Respect this.
    return super.canBecomeKeyView && NSApp.fullKeyboardAccessEnabled;
}

- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

- (void)mouseDown:(NSEvent *)anEvent
{
    if (!self.enabled)
    {
        [super mouseDown:anEvent];
        return;
    }

    NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];

    if (self.isRecording)
    {
        if ([self mouse:locationInView inRect:self.style.cancelButtonLayoutGuide.frame])
        {
            _mouseTrackingButtonTag = _SRRecorderControlCancelButtonTag;
            [self setNeedsDisplayInRect:self.style.cancelButtonLayoutGuide.frame];
        }
        else if ([self mouse:locationInView inRect:self.style.clearButtonLayoutGuide.frame])
        {
            _mouseTrackingButtonTag = _SRRecorderControlClearButtonTag;
            [self setNeedsDisplayInRect:self.style.clearButtonLayoutGuide.frame];
        }
        else
            [super mouseDown:anEvent];
    }
    else if ([self mouse:locationInView inRect:self.bounds])
    {
        _mouseTrackingButtonTag = _SRRecorderControlMainButtonTag;
        [self setNeedsDisplay:YES];
    }
    else
        [super mouseDown:anEvent];
}

- (void)mouseUp:(NSEvent *)anEvent
{
    if (!self.enabled)
    {
        [super mouseUp:anEvent];
        return;
    }

    if (_mouseTrackingButtonTag != _SRRecorderControlInvalidButtonTag)
    {
        if (!self.window.isKeyWindow)
        {
            // It's possible to receive this event after window resigned its key status
            // e.g. when shortcut brings new window and makes it key.
            [self setNeedsDisplay:YES];
        }
        else
        {
            NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];

            if (_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag &&
                [self mouse:locationInView inRect:self.bounds])
            {
                [self beginRecording];
            }
            else if (_mouseTrackingButtonTag == _SRRecorderControlCancelButtonTag &&
                     [self mouse:locationInView inRect:self.style.cancelButtonLayoutGuide.frame])
            {
                [self endRecording];
            }
            else if (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag &&
                     [self mouse:locationInView inRect:self.style.clearButtonLayoutGuide.frame])
            {
                [self clearAndEndRecording];
            }
        }

        _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
    }
    else
        [super mouseUp:anEvent];
}

- (void)mouseEntered:(NSEvent *)anEvent
{
    if (!self.enabled)
    {
        [super mouseEntered:anEvent];
        return;
    }

    if ((_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag && anEvent.trackingArea == _mainButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlCancelButtonTag && anEvent.trackingArea == _cancelButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag && anEvent.trackingArea == _clearButtonTrackingArea))
    {
        [self setNeedsDisplayInRect:anEvent.trackingArea.rect];
    }

    [super mouseEntered:anEvent];
}

- (void)mouseExited:(NSEvent *)anEvent
{
    if (!self.enabled)
    {
        [super mouseExited:anEvent];
        return;
    }

    if ((_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag && anEvent.trackingArea == _mainButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlCancelButtonTag && anEvent.trackingArea == _cancelButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag && anEvent.trackingArea == _clearButtonTrackingArea))
    {
        [self setNeedsDisplayInRect:anEvent.trackingArea.rect];
    }

    [super mouseExited:anEvent];
}

- (void)keyDown:(NSEvent *)anEvent
{
    if (![self performKeyEquivalent:anEvent])
        [super keyDown:anEvent];
}

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
    if (!self.enabled)
        return NO;

    if (self.window.firstResponder != self)
        return NO;

    if (_mouseTrackingButtonTag != _SRRecorderControlInvalidButtonTag)
        return NO;

    if (self.isRecording)
    {
        if (anEvent.keyCode == USHRT_MAX)
        {
            // This shouldn't really happen ever, but was rarely observed.
            // See https://github.com/Kentzo/ShortcutRecorder/issues/40
            return NO;
        }
        else if (self.allowsEscapeToCancelRecording &&
            anEvent.keyCode == kVK_Escape &&
            (anEvent.modifierFlags & SRCocoaModifierFlagsMask) == 0)
        {
            [self endRecording];
            return YES;
        }
        else if (self.allowsDeleteToClearShortcutAndEndRecording &&
                (anEvent.keyCode == kVK_Delete || anEvent.keyCode == kVK_ForwardDelete) &&
                (anEvent.modifierFlags & SRCocoaModifierFlagsMask) == 0)
        {
            [self clearAndEndRecording];
            return YES;
        }
        else if ([self areModifierFlagsValid:anEvent.modifierFlags forKeyCode:anEvent.keyCode])
        {
            SRShortcut *newObjectValue = [SRShortcut shortcutWithCode:anEvent.keyCode
                                                        modifierFlags:anEvent.modifierFlags
                                                           characters:anEvent.characters
                                          charactersIgnoringModifiers:anEvent.charactersIgnoringModifiers];

            if ([self.delegate respondsToSelector:@selector(shortcutRecorder:canRecordShortcut:)])
            {
                if (![self.delegate shortcutRecorder:self canRecordShortcut:newObjectValue])
                {
                    // We acutally handled key equivalent, because client likely performs some action
                    // to represent an error (e.g. beep and error dialog).
                    // Do not end editing, because if client do not use additional window to show an error
                    // first responder will not change. Allow a user to make another attempt.
                    return YES;
                }
            }

            [self endRecordingWithObjectValue:newObjectValue];
            return YES;
        }
    }
    else if (anEvent.keyCode == kVK_Space)
        return [self beginRecording];

    return NO;
}

- (void)flagsChanged:(NSEvent *)anEvent
{
    if (self.isRecording)
    {
        NSEventModifierFlags modifierFlags = anEvent.modifierFlags & SRCocoaModifierFlagsMask;
        if (modifierFlags != 0 && ![self areModifierFlagsValid:modifierFlags forKeyCode:anEvent.keyCode])
            NSBeep();

        [self setNeedsDisplayInRect:self.style.labelDrawingGuide.frame];
    }

    [super flagsChanged:anEvent];
}


#pragma mark NSObject

+ (void)initialize
{
    if (self == [SRRecorderControl class])
    {
        [self exposeBinding:NSValueBinding];
        [self exposeBinding:NSEnabledBinding];
    }
}

+ (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if (@available(macOS 10.14, *))
    {
        if (aProtocol == NSProtocolFromString(@"NSViewToolTipOwner"))
            return YES;
        else if (aProtocol == NSProtocolFromString(@"NSEditor"))
            return YES;
    }

    return [super conformsToProtocol:aProtocol];
}

- (Class)valueClassForBinding:(NSBindingName)aBinding
{
    if ([aBinding isEqualToString:NSValueBinding])
        return SRShortcut.class;
    else if ([aBinding isEqualToString:NSEnabledBinding])
        return NSNumber.class;
    else
        return [super valueClassForBinding:aBinding];
}

- (NSArray<NSAttributeDescription *> *)optionDescriptionsForBinding:(NSBindingName)aBinding
{
    if ([aBinding isEqualToString:NSValueBinding] || [aBinding isEqualToString:NSEnabledBinding])
    {
        NSAttributeDescription *valueTransformer = [NSAttributeDescription new];
        valueTransformer.name = NSValueTransformerBindingOption;
        valueTransformer.attributeType = NSStringAttributeType;
        valueTransformer.defaultValue = @"";

        NSAttributeDescription *valueTransformerName = [NSAttributeDescription new];
        valueTransformerName.name = NSValueTransformerNameBindingOption;
        valueTransformerName.attributeType = NSStringAttributeType;
        valueTransformerName.defaultValue = @"";

        return @[valueTransformer, valueTransformerName];
    }
    else
        return [super optionDescriptionsForBinding:aBinding];
}

@end
