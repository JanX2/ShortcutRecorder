//
//  Copyright 2006 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <limits.h>
#import <objc/runtime.h>
#import <os/trace.h>
#import <os/activity.h>

#import "SRRecorderControl.h"
#import "SRShortcutRegistration.h"
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
    SRRecorderControlStyle *_style;
    NSInvocation *_notifyStyle;

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
        [self initInternalState];
    }

    return self;
}

- (void)initInternalState
{
    self.enabled = YES;
    _allowsEmptyModifierFlags = NO;
    _drawsASCIIEquivalentOfShortcut = YES;
    _allowsEscapeToCancelRecording = YES;
    _allowsDeleteToClearShortcutAndEndRecording = YES;
    _allowedModifierFlags = SRCocoaModifierFlagsMask;
    _requiredModifierFlags = 0;
    _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
    _cancelButtonToolTipTag = NSIntegerMax;
    _disablesShortcutRegistrationsWhileRecording = YES;

    _notifyStyle = [NSInvocation invocationWithMethodSignature:[SRRecorderControlStyle instanceMethodSignatureForSelector:@selector(recorderControlAppearanceDidChange:)]];
    _notifyStyle.selector = @selector(recorderControlAppearanceDidChange:);
    [_notifyStyle retainArguments];

    self.translatesAutoresizingMaskIntoConstraints = NO;

    [self setContentHuggingPriority:NSLayoutPriorityDefaultLow
                     forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentHuggingPriority:NSLayoutPriorityRequired
                     forOrientation:NSLayoutConstraintOrientationVertical];

    [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                   forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                   forOrientation:NSLayoutConstraintOrientationVertical];

    self.toolTip = SRLoc(@"Click to record shortcut");
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_notifyStyle];
}

#pragma mark Properties
@dynamic style;

+ (BOOL)automaticallyNotifiesObserversOfValue
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfObjectValue
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfStringValue
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfAttributedStringValue
{
    return NO;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingDictionaryValue
{
    return [NSSet setWithObject:@"objectValue"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingStringValue
{
    return [NSSet setWithObject:@"objectValue"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingAttributedStringValue
{
    return [NSSet setWithObject:@"objectValue"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingAccessibilityStringValue
{
    return [NSSet setWithObject:@"objectValue"];
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

    _objectValue = newObjectValue.copy;
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

- (id)value
{
    return self.objectValue;
}

- (void)setValue:(id)newValue
{
    if (NSIsControllerMarker(newValue))
        [NSException raise:NSInternalInconsistencyException format:@"SRRecorderControl's NSValueBinding does not support controller value markers."];

    self.objectValue = newValue;
}

- (SRRecorderControlStyle *)style
{
    if (_style == nil)
    {
        _style = [self makeDefaultStyle];
        [_style prepareForRecorderControl:self];
    }

    return _style;
}

- (void)setStyle:(SRRecorderControlStyle *)newStyle
{
    if (newStyle == nil)
        newStyle = [self makeDefaultStyle];
    else if ([newStyle isEqual:_style])
        return;
    else
        newStyle = newStyle.copy;

    [NSObject cancelPreviousPerformRequestsWithTarget:_notifyStyle];
    [_style prepareForRemoval];
    _style = newStyle;
    [_style prepareForRecorderControl:self];
}

- (NSBezierPath *)focusRingShape
{
    NSRect alignmentFrame = self.style.alignmentGuide.frame;
    NSEdgeInsets insets = self.style.focusRingInsets;
    NSSize cornerRadius = self.style.focusRingCornerRadius;

    alignmentFrame.origin.x += insets.left;
    alignmentFrame.origin.y += insets.top;
    alignmentFrame.size.width = fdim(alignmentFrame.size.width, insets.left + insets.right);
    alignmentFrame.size.height = fdim(alignmentFrame.size.height, insets.top + insets.bottom);
    return [NSBezierPath bezierPathWithRoundedRect:alignmentFrame xRadius:cornerRadius.width yRadius:cornerRadius.height];
}

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

- (NSString *)drawingLabel
{
    NSString *label = nil;

    if (self.isRecording)
    {
        NSEventModifierFlags modifierFlags = [NSEvent modifierFlags] & self.allowedModifierFlags;

        if (modifierFlags)
        {
            __auto_type layoutDirection = self.drawLabelRespectsUserInterfaceLayoutDirection ? self.userInterfaceLayoutDirection : NSUserInterfaceLayoutDirectionLeftToRight;
            label = [SRSymbolicModifierFlagsTransformer.sharedTransformer transformedValue:@(modifierFlags)
                                                                           layoutDirection:layoutDirection];
        }
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

- (NSString *)accessibilityStringValue
{
    if (!_objectValue)
        return nil;

    __auto_type layoutDirection = self.drawLabelRespectsUserInterfaceLayoutDirection ? self.userInterfaceLayoutDirection : NSUserInterfaceLayoutDirectionLeftToRight;
    NSString *f = [SRLiteralModifierFlagsTransformer.sharedTransformer transformedValue:@(_objectValue.modifierFlags)
                                                                        layoutDirection:layoutDirection];
    NSString *c = nil;

    if (self.drawsASCIIEquivalentOfShortcut)
        c = [SRASCIILiteralKeyCodeTransformer.sharedTransformer transformedValue:@(_objectValue.keyCode)];
    else
        c = [SRLiteralKeyCodeTransformer.sharedTransformer transformedValue:@(_objectValue.keyCode)];

    if (f.length > 0)
        return [NSString stringWithFormat:@"%@-%@", f, c];
    else
        return [NSString stringWithFormat:@"%@", c];
}

- (NSDictionary *)drawingLabelAttributes
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

#pragma mark Methods

- (SRRecorderControlStyle *)makeDefaultStyle
{
    return [SRRecorderControlStyle new];
}

- (BOOL)beginRecording
{
    __block BOOL result = NO;
    os_activity_initiate("beginRecording", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (!self.enabled)
        {
            result = NO;
            return;
        }

        if (self.isRecording)
        {
            result = YES;
            return;
        }

        self.needsDisplay = YES;

        BOOL shouldBeginRecording = YES;

        if ([self.delegate respondsToSelector:@selector(recorderControlShouldBeginRecording:)])
            shouldBeginRecording = [self.delegate recorderControlShouldBeginRecording:self];
        else if ([self.delegate respondsToSelector:@selector(shortcutRecorderShouldBeginRecording:)])
            shouldBeginRecording = [self.delegate shortcutRecorderShouldBeginRecording:self];

        if (!shouldBeginRecording)
        {
            NSBeep();
            result = NO;
            return;
        }

        NSDictionary *bindingInfo = [self infoForBinding:NSValueBinding];
        if (bindingInfo)
        {
            id controller = bindingInfo[NSObservedObjectKey];
            if ([controller respondsToSelector:@selector(objectDidBeginEditing:)])
                [controller objectDidBeginEditing:(id<NSEditor>) self];
        }

        [self willChangeValueForKey:@"isRecording"];
        self->_isRecording = YES;
        [self didChangeValueForKey:@"isRecording"];

        [self updateActiveConstraints];
        [self updateTrackingAreas];
        self.toolTip = SRLoc(@"Type shortcut");
        NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);

        if (self.disablesShortcutRegistrationsWhileRecording)
            [SRShortcutRegistration disableShortcutRegistrations];

        result = YES;
    });

    return result;
}

- (void)endRecording
{
    if (!self.isRecording)
        return;

    os_activity_initiate("endRecording via cancel", OS_ACTIVITY_FLAG_DEFAULT, ^{
        [self endRecordingWithObjectValue:self->_objectValue];
    });
}

- (void)clearAndEndRecording
{
    if (!self.isRecording)
        return;

    os_activity_initiate("endRecording via clear", OS_ACTIVITY_FLAG_DEFAULT, ^{
        [self endRecordingWithObjectValue:nil];
    });
}

- (void)endRecordingWithObjectValue:(SRShortcut *)anObjectValue
{
    if (!self.isRecording)
        return;

    os_activity_initiate("endRecording explicitly", OS_ACTIVITY_FLAG_IF_NONE_PRESENT, ^{
        NSDictionary *bindingInfo = [self infoForBinding:NSValueBinding];
        if (bindingInfo)
        {
            id controller = bindingInfo[NSObservedObjectKey];
            if ([controller respondsToSelector:@selector(objectDidEndEditing:)])
                [controller objectDidEndEditing:(id<NSEditor>)self];
        }

        [self willChangeValueForKey:@"isRecording"];
        self->_isRecording = NO;
        [self didChangeValueForKey:@"isRecording"];

        self.objectValue = anObjectValue;

        [self updateActiveConstraints];
        [self updateTrackingAreas];
        self.toolTip = SRLoc(@"Click to record shortcut");
        self.needsDisplay = YES;
        NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);

        if (self.window.firstResponder == self && !self.canBecomeKeyView)
            [self.window makeFirstResponder:nil];

        if ([self.delegate respondsToSelector:@selector(recorderControlDidEndRecording:)])
            [self.delegate recorderControlDidEndRecording:self];
        else if ([self.delegate respondsToSelector:@selector(shortcutRecorderDidEndRecording:)])
            [self.delegate shortcutRecorderDidEndRecording:self];

        [self sendAction:self.action to:self.target];

        if (self.disablesShortcutRegistrationsWhileRecording)
            [SRShortcutRegistration enableShortcutRegistrations];
    });
}

- (void)updateActiveConstraints
{
    [NSLayoutConstraint activateConstraints:self.style.alwaysConstraints];

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

    NSString *label = self.drawingLabel;
    NSDictionary *labelAttributes = self.drawingLabelAttributes;

    [NSGraphicsContext saveGraphicsState];
    labelFrame.origin.y = NSMaxY(labelFrame) - self.style.baselineDrawingOffsetFromBottom;
    labelFrame = [self backingAlignedRect:labelFrame options:NSAlignRectFlipped |
                  NSAlignMinXOutward |
                  NSAlignMinYOutward |
                  NSAlignMaxXInward |
                  NSAlignMaxYInward];
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

- (BOOL)areModifierFlagsValid:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode
{
    __block BOOL allowModifierFlags = NO;
    aModifierFlags &= SRCocoaModifierFlagsMask;

    os_activity_initiate("areModifierFlagsValid:forKeyCode:", OS_ACTIVITY_FLAG_DEFAULT, ^{


        if ([self.delegate respondsToSelector:@selector(recorderControl:shouldUnconditionallyAllowModifierFlags:forKeyCode:)])
            allowModifierFlags = [self.delegate recorderControl:self
                        shouldUnconditionallyAllowModifierFlags:aModifierFlags
                                                     forKeyCode:aKeyCode];
        else if ([self.delegate respondsToSelector:@selector(shortcutRecorder:shouldUnconditionallyAllowModifierFlags:forKeyCode:)])
            allowModifierFlags = [self.delegate shortcutRecorder:self
                         shouldUnconditionallyAllowModifierFlags:aModifierFlags
                                                      forKeyCode:aKeyCode];
    });

    if (allowModifierFlags)
        return YES;
    else if (aModifierFlags == 0 && !self.allowsEmptyModifierFlags)
        return NO;
    else if ((aModifierFlags & self.requiredModifierFlags) != self.requiredModifierFlags)
        return NO;
    else if ((aModifierFlags & self.allowedModifierFlags) != aModifierFlags)
        return NO;
    else
        return YES;
}

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
            else
                NSLog(@"WARNING: binding \"%@\" has value transformer, but it doesn't allow reverse transformations in %s", aBinding, __PRETTY_FUNCTION__);
        }
    }

    if (!_isCompatibilityModeEnabled &&
        ([boundObject isKindOfClass:NSUserDefaults.class] || [boundObject isKindOfClass:NSUserDefaultsController.class]) &&
        [aValue isKindOfClass:SRShortcut.class])
    {
        os_trace_error("#Error The control is bound to NSUserDefaults but is not transformed into an allowed CFPreferences value");
        NSLog(@"WARNING: Shortcut Recroder 2 compatibility mode enabled. Getters of objectValue and NSValueBinding will return an instance of NSDictionary.");
        _isCompatibilityModeEnabled = YES;

        aValue = [aValue dictionaryRepresentation];
    }

    [boundObject setValue:aValue forKeyPath:boundKeyPath];
}

- (void)controlTintDidChange:(NSNotification *)aNotification
{
    [self scheduleControlViewAppearanceDidChange:aNotification];
}

- (void)accessibilityDisplayOptionsDidChange:(NSNotification *)aNotification
{
    [self scheduleControlViewAppearanceDidChange:aNotification];
}

- (void)scheduleControlViewAppearanceDidChange:(nullable id)aReason
{
    if (_notifyStyle == nil || _style == nil)
        // recorderControlAppearanceDidChange: is called whenever _style is created.
        return;

    [NSObject cancelPreviousPerformRequestsWithTarget:_notifyStyle];
    [_notifyStyle setArgument:&aReason atIndex:2];
    [_notifyStyle performSelector:@selector(invokeWithTarget:) withObject:_style afterDelay:0.0 inModes:@[NSRunLoopCommonModes]];
}

#pragma mark NSAccessibility

- (BOOL)accessibilityIsIgnored
{
    return NO;
}

- (NSString *)accessibilityLabel
{
    NSString *label = nil;

    if (self.isRecording)
    {
        __auto_type layoutDirection = self.drawLabelRespectsUserInterfaceLayoutDirection ? self.userInterfaceLayoutDirection : NSUserInterfaceLayoutDirectionLeftToRight;
        NSEventModifierFlags modifierFlags = [NSEvent modifierFlags] & self.allowedModifierFlags;
        label = [SRLiteralModifierFlagsTransformer.sharedTransformer transformedValue:@(modifierFlags) layoutDirection:layoutDirection];

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

- (BOOL)commitEditingAndReturnError:(NSError * __autoreleasing *)outError
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
        [self initInternalState];
    }

    return self;
}

#pragma mark NSControl
@dynamic enabled;
@synthesize refusesFirstResponder = refusesFirstResponder;
@synthesize tag = _tag;

+ (Class)cellClass
{
    return nil;
}

- (NSAttributedString *)attributedStringValue
{
    return [[NSAttributedString alloc] initWithString:self.stringValue];
}

- (void)setAttributedStringValue:(NSAttributedString *)newAttributedStringValue
{
    [self setObjectValue:[SRShortcut shortcutWithKeyEquivalent:newAttributedStringValue.string]];
}

- (NSString *)stringValue
{
    if (!_objectValue)
        return @"";

    __auto_type layoutDirection = self.drawLabelRespectsUserInterfaceLayoutDirection ? self.userInterfaceLayoutDirection : NSUserInterfaceLayoutDirectionLeftToRight;
    NSString *flags = [SRSymbolicModifierFlagsTransformer.sharedTransformer transformedValue:@(_objectValue.modifierFlags)
                                                                             layoutDirection:layoutDirection];
    SRKeyCodeTransformer *transformer = nil;

    if (self.drawsASCIIEquivalentOfShortcut)
        transformer = SRASCIILiteralKeyCodeTransformer.sharedTransformer;
    else
        transformer = SRLiteralKeyCodeTransformer.sharedTransformer;

    NSString *code = [transformer transformedValue:@(_objectValue.keyCode)
                         withImplicitModifierFlags:nil
                             explicitModifierFlags:@(_objectValue.modifierFlags)
                                   layoutDirection:layoutDirection];

    if (layoutDirection == NSUserInterfaceLayoutDirectionRightToLeft)
        return [NSString stringWithFormat:@"%@%@", code, flags];
    else
        return [NSString stringWithFormat:@"%@%@", flags, code];
}

- (void)setStringValue:(NSString *)newStringValue
{
    [self setObjectValue:[SRShortcut shortcutWithKeyEquivalent:newStringValue]];
}

- (BOOL)isHighlighted
{
    return self.isMainButtonHighlighted;
}

- (BOOL)abortEditing
{
    [self endRecording];
    return NO;
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

- (BOOL)allowsVibrancy
{
    return self.style.allowsVibrancy;
}

- (BOOL)isFlipped
{
    return YES;
}

- (NSUserInterfaceLayoutDirection)userInterfaceLayoutDirection
{
    // NSView uses associated objects to track whether default value was overridden.
    // Here the lookup order is altered in the following way
    //     1. View's own value
    //     2. Style's value
    //     3. View's default value that falls back to NSWindow and then NSApp
    NSNumber *superValue = objc_getAssociatedObject(self, @selector(userInterfaceLayoutDirection));
    if (superValue)
        return superValue.integerValue;

    if (self.style.preferredComponents.layoutDirection != SRRecorderControlStyleComponentsLayoutDirectionUnspecified)
        return SRRecorderControlStyleComponentsLayoutDirectionToSystem(self.style.preferredComponents.layoutDirection);
    else
        return super.userInterfaceLayoutDirection;
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
        [self.focusRingShape fill];
}

- (NSRect)focusRingMaskBounds
{
    if (self.enabled && self.window.firstResponder == self)
        return self.focusRingShape.bounds;
    else
        return NSZeroRect;
}

- (NSEdgeInsets)alignmentRectInsets
{
    return self.style.alignmentRectInsets;
}

- (NSSize)intrinsicContentSize
{
    return self.style.intrinsicContentSize;
}

- (CGFloat)baselineOffsetFromBottom
{
    return self.style.baselineLayoutOffsetFromBottom;
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
    [self scheduleControlViewAppearanceDidChange:nil];
}

- (void)viewDidChangeEffectiveAppearance
{
    [super viewDidChangeEffectiveAppearance];
    [self scheduleControlViewAppearanceDidChange:nil];
}


#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
    return self.enabled && !self.refusesFirstResponder;
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
    __block BOOL result = NO;
    os_activity_initiate("performKeyEquivalent:", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (!self.enabled)
        {
            os_trace_debug("The control is disabled -> NO");
            result = NO;
            return;
        }

        if (self.window.firstResponder != self)
        {
            os_trace_debug("The control is not the first responder -> NO");
            result = NO;
            return;
        }

        if (self->_mouseTrackingButtonTag != _SRRecorderControlInvalidButtonTag)
        {
            os_trace_debug("The control is tracking %lu -> NO", self->_mouseTrackingButtonTag);
            result = NO;
            return;
        }

        if (self.isRecording)
        {
            if (anEvent.keyCode == USHRT_MAX)
            {
                // This shouldn't really happen ever, but was rarely observed.
                // See https://github.com/Kentzo/ShortcutRecorder/issues/40
                os_trace_debug("Invalid keyCode -> NO");
                result = NO;
            }
            else if (self.allowsEscapeToCancelRecording &&
                anEvent.keyCode == kVK_Escape &&
                (anEvent.modifierFlags & SRCocoaModifierFlagsMask) == 0)
            {
                os_trace_debug("Cancel via Esc -> YES");
                [self endRecording];
                result = YES;
            }
            else if (self.allowsDeleteToClearShortcutAndEndRecording &&
                    (anEvent.keyCode == kVK_Delete || anEvent.keyCode == kVK_ForwardDelete) &&
                    (anEvent.modifierFlags & SRCocoaModifierFlagsMask) == 0)
            {
                os_trace_debug("Clear via Delete -> YES");
                [self clearAndEndRecording];
                result = YES;
            }
            else if ([self areModifierFlagsValid:anEvent.modifierFlags forKeyCode:anEvent.keyCode])
            {
                SRShortcut *newObjectValue = [SRShortcut shortcutWithCode:anEvent.keyCode
                                                            modifierFlags:anEvent.modifierFlags
                                                               characters:anEvent.characters
                                              charactersIgnoringModifiers:anEvent.charactersIgnoringModifiers];

                BOOL canRecordShortcut = YES;

                if ([self.delegate respondsToSelector:@selector(recorderControl:canRecordShortcut:)])
                    canRecordShortcut = [self.delegate recorderControl:self canRecordShortcut:newObjectValue];
                else if ([self.delegate respondsToSelector:@selector(shortcutRecorder:canRecordShortcut:)])
                    canRecordShortcut = [self.delegate shortcutRecorder:self canRecordShortcut:newObjectValue.dictionaryRepresentation];
                else if ([self.delegate respondsToSelector:@selector(control:isValidObject:)])
                    canRecordShortcut = [self.delegate control:self isValidObject:newObjectValue];

                if (canRecordShortcut)
                {
                    os_trace_debug("Valid and accepted shortcut -> YES");
                    [self endRecordingWithObjectValue:newObjectValue];
                    result = YES;
                }
                else
                {
                    // Do not end editing and allow the client to make another attempt.
                    os_trace_debug("Valid but rejected shortcut -> YES");
                    result = YES;
                }
            }
            else
            {
                os_trace_debug("Modifier flags %lu rejected -> NO", anEvent.modifierFlags);
                result = NO;
            }
        }
        else if (anEvent.keyCode == kVK_Space)
        {
            os_trace_debug("Begin recording via Space -> YES");
            result = [self beginRecording];
        }
        else
            result = NO;
    });

    return result;
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
    }
}

- (Class)valueClassForBinding:(NSBindingName)aBinding
{
    if ([aBinding isEqualToString:NSValueBinding])
        return SRShortcut.class;
    else
        return [super valueClassForBinding:aBinding];
}

- (NSArray<NSAttributeDescription *> *)optionDescriptionsForBinding:(NSBindingName)aBinding
{
    if ([aBinding isEqualToString:NSValueBinding])
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
