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

#import "SRRecorderControl.h"
#import "SRKeyCodeTransformer.h"
#import "SRModifierFlagsTransformer.h"


NSString *const SRShortcutKeyCode = @"keyCode";

NSString *const SRShortcutModifierFlagsKey = @"modifierFlags";

NSString *const SRShortcutCharacters = @"characters";

NSString *const SRShortcutCharactersIgnoringModifiers = @"charactersIgnoringModifiers";


// Control Layout Constants
static const CGFloat _SRRecorderControlShapeXRadius = 11.0;

static const CGFloat _SRRecorderControlShapeYRadius = 12.0;

static const CGFloat _SRRecorderControlHeight = 25.0;

static const CGFloat _SRRecorderControlBottomShadowHeightInPixels = 1.0;

static const CGFloat _SRRecorderControlBaselineOffset = 5.0;


// Clear Button Layout Constants

static const CGFloat _SRRecorderControlClearButtonWidth = 14.0;

static const CGFloat _SRRecorderControlClearButtonHeight = 14.0;

static const CGFloat _SRRecorderControlClearButtonRightOffset = 4.0;

static const CGFloat _SRRecorderControlClearButtonLeftOffset = 1.0;

static const NSSize _SRRecorderControlClearButtonSize = {.width = _SRRecorderControlClearButtonWidth, .height = _SRRecorderControlClearButtonHeight};


// SanpBack Button Layout Constants

static const CGFloat _SRRecorderControlSnapBackButtonWidth = 14.0;

static const CGFloat _SRRecorderControlSnapBackButtonHeight = 14.0;

static const CGFloat _SRRecorderControlSnapBackButtonRightOffset = 1.0;

static const CGFloat _SRRecorderControlSnapBackButtonLeftOffset = 3.0;

static const NSSize _SRRecorderControlSnapBackButtonSize = {.width = _SRRecorderControlSnapBackButtonWidth, .height = _SRRecorderControlSnapBackButtonHeight};


static NSImage *_SRImages[16];


static NSUInteger _SRValueObservationContext;


typedef NS_ENUM(NSUInteger, _SRRecorderControlButtonTag)
{
    _SRRecorderControlInvalidButtonTag = -1,
    _SRRecorderControlSnapBackButtonTag = 0,
    _SRRecorderControlClearButtonTag = 1,
    _SRRecorderControlMainButtonTag = 2
};


/*!
    @brief  Extracts value transformer from binding options.

    @result Returns an instance of NSValueTransformer or nil if there is not transformer.
 */
static NSValueTransformer *_SRValueTransformerFromBindingOptions(NSDictionary *aBindingOptions)
{
    NSValueTransformer *valueTransformer = aBindingOptions[NSValueTransformerBindingOption];

    if (!valueTransformer || (NSNull *)valueTransformer == [NSNull null])
    {
        NSString *valueTransformerName = aBindingOptions[NSValueTransformerNameBindingOption];

        if (valueTransformerName && (NSNull *)valueTransformerName != [NSNull null])
            valueTransformer = [NSValueTransformer valueTransformerForName:valueTransformerName];
    }

    if ((NSNull *)valueTransformer != [NSNull null])
        return valueTransformer;
    else
        return nil;
}


@implementation SRRecorderControl
{
    NSTrackingArea *_mainButtonTrackingArea;
    NSTrackingArea *_snapBackButtonTrackingArea;
    NSTrackingArea *_clearButtonTrackingArea;

    _SRRecorderControlButtonTag _mouseTrackingButtonTag;
    NSToolTipTag _snapBackButtonToolTipTag;

    NSMutableDictionary *_bindingInfo;
}

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self != nil)
    {
        _allowedModifierFlags = SRCocoaModifierFlagsMask;
        _requiredModifierFlags = 0;
        _allowsEmptyModifierFlags = NO;
        _drawsASCIIEquivalentOfShortcut = YES;
        _allowsEscapeToCancelRecording = YES;
        _allowsDeleteToClearShortcutAndEndRecording = YES;
        _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
        _snapBackButtonToolTipTag = NSIntegerMax;
        _bindingInfo = [NSMutableDictionary dictionary];

        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
        {
            self.translatesAutoresizingMaskIntoConstraints = YES;

            [self setContentHuggingPriority:NSLayoutPriorityDefaultLow
                             forOrientation:NSLayoutConstraintOrientationHorizontal];
            [self setContentHuggingPriority:NSLayoutPriorityRequired
                             forOrientation:NSLayoutConstraintOrientationVertical];

            [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                           forOrientation:NSLayoutConstraintOrientationHorizontal];
            [self setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                           forOrientation:NSLayoutConstraintOrientationVertical];
        }

        [self setToolTip:SRLoc(@"Click to record shortcut")];
        [self updateTrackingAreas];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_bindingInfo unbind:NSValueBinding];
}


#pragma mark Properties

- (void)setAllowedModifierFlags:(NSUInteger)newAllowedModifierFlags
          requiredModifierFlags:(NSUInteger)newRequiredModifierFlags
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

    _allowedModifierFlags = newAllowedModifierFlags;
    _requiredModifierFlags = newRequiredModifierFlags;
    _allowsEmptyModifierFlags = newAllowsEmptyModifierFlags;
}

- (void)setObjectValue:(NSDictionary *)newObjectValue
{
    // Cocoa KVO and KVC frequently uses NSNull as object substituation of nil.
    // SRRecorderControl expects either nil or valid object value, it it's convenient
    // to handle handle NSNull here and convert it into nil.
    if ((NSNull *)newObjectValue == [NSNull null])
        newObjectValue = nil;

    _objectValue = [newObjectValue copy];

    if (!self.isRecording)
    {
        NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);
        [self setNeedsDisplay:YES];
    }
}


#pragma mark Methods

- (BOOL)beginRecording
{
    if (self.isRecording)
        return YES;

    [self setNeedsDisplay:YES];

    if ([self.delegate respondsToSelector:@selector(shortcutRecorderShouldBeginRecording:)])
    {
        if (![self.delegate shortcutRecorderShouldBeginRecording:self])
        {
            NSBeep();
            return NO;
        }
    }

    [self willChangeValueForKey:@"isRecording"];
    _isRecording = YES;
    [self didChangeValueForKey:@"isRecording"];

    [self updateTrackingAreas];
    [self setToolTip:SRLoc(@"Type shortcut")];
    NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);
    return YES;
}

- (void)endRecording
{
    [self endRecordingWithObjectValue:self.objectValue];
}

- (void)clearAndEndRecording
{
    [self endRecordingWithObjectValue:nil];
}

- (void)endRecordingWithObjectValue:(NSDictionary *)anObjectValue
{
    if (!self.isRecording)
        return;

    [self willChangeValueForKey:@"isRecording"];
    _isRecording = NO;
    [self didChangeValueForKey:@"isRecording"];

    NSDictionary *valueBindingInfo = _bindingInfo[NSValueBinding];

    if (valueBindingInfo)
    {
        NSValueTransformer *transformer = _SRValueTransformerFromBindingOptions(valueBindingInfo);

        if ([[transformer class] allowsReverseTransformation])
        {
            [valueBindingInfo[NSObservedObjectKey] setValue:[transformer reverseTransformedValue:anObjectValue]
                                                 forKeyPath:valueBindingInfo[NSObservedKeyPathKey]];
        }
        else
            [valueBindingInfo[NSObservedObjectKey] setValue:anObjectValue forKeyPath:valueBindingInfo[NSObservedKeyPathKey]];

        // objectValue will be set in -observeValueForKeyPath:ofObject:change:context:
    }
    else
        self.objectValue = anObjectValue;

    [self updateTrackingAreas];
    [self setToolTip:SRLoc(@"Click to record shortcut")];
    [self setNeedsDisplay:YES];
    NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);

    // Return to the "button" state but buttons cannot be first responders (unless Full Keyboard Access)
    if (self.window.firstResponder == self && ![self canBecomeKeyView])
        [self.window makeFirstResponder:nil];

    if ([self.delegate respondsToSelector:@selector(shortcutRecorderDidEndRecording:)])
        [self.delegate shortcutRecorderDidEndRecording:self];
}


#pragma mark -

- (NSBezierPath *)controlShape
{
    NSRect shapeBounds = self.bounds;
    shapeBounds.size.height = _SRRecorderControlHeight - self.alignmentRectInsets.bottom;
    shapeBounds = NSInsetRect(shapeBounds, 1.0, 1.0);
    return [NSBezierPath bezierPathWithRoundedRect:shapeBounds
                                           xRadius:_SRRecorderControlShapeXRadius
                                           yRadius:_SRRecorderControlShapeYRadius];
}

- (NSRect)rectForLabel:(NSString *)aLabel withAttributes:(NSDictionary *)anAttributes
{
    NSSize labelSize = [aLabel sizeWithAttributes:anAttributes];
    NSRect enclosingRect = NSInsetRect(self.bounds, _SRRecorderControlShapeXRadius, 0.0);
    labelSize.width = fmin(ceil(labelSize.width), NSWidth(enclosingRect));
    labelSize.height = ceil(labelSize.height);
    CGFloat fontBaselineOffsetFromTop = labelSize.height + [anAttributes[NSFontAttributeName] descender];
    CGFloat baselineOffsetFromTop = _SRRecorderControlHeight - self.alignmentRectInsets.bottom - self.baselineOffsetFromBottom;
    NSRect labelRect = {
        .origin = NSMakePoint(NSMidX(enclosingRect) - labelSize.width / 2.0, baselineOffsetFromTop - fontBaselineOffsetFromTop),
        .size = labelSize
    };
    labelRect = [self centerScanRect:labelRect];

    // Ensure label and buttons do not overlap.
    if (self.isRecording)
    {
        CGFloat rightOffsetFromButtons = NSMinX(self.snapBackButtonRect) - NSMaxX(labelRect);

        if (rightOffsetFromButtons < 0.0)
        {
            labelRect = NSOffsetRect(labelRect, rightOffsetFromButtons, 0.0);

            if (NSMinX(labelRect) < NSMinX(enclosingRect))
            {
                labelRect.size.width -= NSMinX(enclosingRect) - NSMinX(labelRect);
                labelRect.origin.x = NSMinX(enclosingRect);
            }
        }
    }

    return labelRect;
}

- (NSRect)snapBackButtonRect
{
    NSRect clearButtonRect = self.clearButtonRect;
    NSRect bounds = self.bounds;
    NSRect snapBackButtonRect = NSZeroRect;
    snapBackButtonRect.origin.x = NSMinX(clearButtonRect) - _SRRecorderControlSnapBackButtonRightOffset - _SRRecorderControlSnapBackButtonSize.width - _SRRecorderControlSnapBackButtonLeftOffset;
    snapBackButtonRect.origin.y = NSMinY(bounds);
    snapBackButtonRect.size.width = fdim(NSMinX(clearButtonRect), NSMinX(snapBackButtonRect));
    snapBackButtonRect.size.height = _SRRecorderControlHeight;
    return snapBackButtonRect;
}

- (NSRect)clearButtonRect
{
    NSRect bounds = self.bounds;
    NSRect clearButtonRect = NSZeroRect;
    clearButtonRect.origin.x = NSMaxX(bounds) - _SRRecorderControlClearButtonRightOffset - _SRRecorderControlClearButtonSize.width - _SRRecorderControlClearButtonLeftOffset;
    clearButtonRect.origin.y = NSMinY(bounds);
    clearButtonRect.size.width = fdim(NSMaxX(bounds), NSMinX(clearButtonRect));
    clearButtonRect.size.height = _SRRecorderControlHeight;
    return clearButtonRect;
}


#pragma mark -

- (NSString *)label
{
    NSString *label = nil;

    if (self.isRecording)
    {
        NSUInteger modifierFlags = [NSEvent modifierFlags] & self.allowedModifierFlags;
        label = [[SRModifierFlagsTransformer sharedTransformer] transformedValue:@(modifierFlags)];

        if ([label length] == 0)
            label = SRLoc(@"Type shortcut");
    }
    else
    {
        if (self.objectValue != nil)
        {
            NSString *f = [[SRModifierFlagsTransformer sharedTransformer] transformedValue:self.objectValue[SRShortcutModifierFlagsKey]];
            SRKeyCodeTransformer *transformer = nil;

            if (self.drawsASCIIEquivalentOfShortcut)
                transformer = [SRKeyCodeTransformer sharedPlainASCIITransformer];
            else
                transformer = [SRKeyCodeTransformer sharedPlainTransformer];

            NSString *c = [transformer transformedValue:self.objectValue[SRShortcutKeyCode]];

            if (![transformer isKeyCodeSpecial:[self.objectValue[SRShortcutKeyCode] unsignedShortValue]])
                c = [c uppercaseString];

            label = [NSString stringWithFormat:@"%@%@", f, c];
        }
        else
            label = SRLoc(@"Click to record shortcut");
    }

    return label;
}

- (NSString *)accessibilityLabel
{
    NSString *label = nil;

    if (self.isRecording)
    {
        NSUInteger modifierFlags = [NSEvent modifierFlags] & self.allowedModifierFlags;
        label = [[SRModifierFlagsTransformer sharedPlainTransformer] transformedValue:@(modifierFlags)];

        if ([label length] == 0)
            label = SRLoc(@"Type shortcut");
    }
    else
    {
        if (self.objectValue != nil)
        {
            NSString *f = [[SRModifierFlagsTransformer sharedPlainTransformer] transformedValue:self.objectValue[SRShortcutModifierFlagsKey]];
            NSString *c = nil;

            if (self.drawsASCIIEquivalentOfShortcut)
                c = [[SRKeyCodeTransformer sharedPlainASCIITransformer] transformedValue:self.objectValue[SRShortcutKeyCode]];
            else
                c = [[SRKeyCodeTransformer sharedPlainTransformer] transformedValue:self.objectValue[SRShortcutKeyCode]];

            if (f.length > 0)
                label = [NSString stringWithFormat:@"%@-%@", f, c];
            else
                label = [NSString stringWithFormat:@"%@", c];
        }
        else
            label = SRLoc(@"Click to record shortcut");
    }

    return label;
}

- (NSDictionary *)labelAttributes
{
    return self.isRecording ? [self recordingLabelAttributes] : [self normalLabelAttributes];
}

- (NSDictionary *)normalLabelAttributes
{
    static dispatch_once_t OnceToken;
    static NSDictionary *NormalAttributes = nil;
    dispatch_once(&OnceToken, ^{
        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        p.alignment = NSCenterTextAlignment;
        p.lineBreakMode = NSLineBreakByClipping;
        p.baseWritingDirection = NSWritingDirectionLeftToRight;
        NormalAttributes = @{
            NSParagraphStyleAttributeName: [p copy],
            NSFontAttributeName: [NSFont labelFontOfSize:[NSFont systemFontSize]],
            NSForegroundColorAttributeName: [NSColor controlTextColor]
        };
    });
    return NormalAttributes;
}

- (NSDictionary *)recordingLabelAttributes
{
    static dispatch_once_t OnceToken;
    static NSDictionary *RecordingAttributes = nil;
    dispatch_once(&OnceToken, ^{
        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        p.alignment = NSCenterTextAlignment;
        p.lineBreakMode = NSLineBreakByClipping;
        p.baseWritingDirection = NSWritingDirectionLeftToRight;
        RecordingAttributes = @{
            NSParagraphStyleAttributeName: [p copy],
            NSFontAttributeName: [NSFont labelFontOfSize:[NSFont systemFontSize]],
            NSForegroundColorAttributeName: [NSColor disabledControlTextColor]
        };
    });
    return RecordingAttributes;
}


#pragma mark -

- (void)drawBackground:(NSRect)aDirtyRect
{
    [NSGraphicsContext saveGraphicsState];

    NSRect frame = self.bounds;
    frame.size.height = _SRRecorderControlHeight;

    if (self.isRecording)
    {
        NSDrawThreePartImage(frame,
                             _SRImages[3],
                             _SRImages[4],
                             _SRImages[5],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             self.isFlipped);
    }
    else
    {
        if (self.isMainButtonHighlighted)
        {
            if ([NSColor currentControlTint] == NSBlueControlTint)
            {
                NSDrawThreePartImage(frame,
                                     _SRImages[0],
                                     _SRImages[1],
                                     _SRImages[2],
                                     NO,
                                     NSCompositeSourceOver,
                                     1.0,
                                     self.isFlipped);
            }
            else
            {
                NSDrawThreePartImage(frame,
                                     _SRImages[6],
                                     _SRImages[7],
                                     _SRImages[8],
                                     NO,
                                     NSCompositeSourceOver,
                                     1.0,
                                     self.isFlipped);
            }
        }
        else
        {
            NSDrawThreePartImage(frame,
                                 _SRImages[9],
                                 _SRImages[10],
                                 _SRImages[11],
                                 NO,
                                 NSCompositeSourceOver,
                                 1.0,
                                 self.isFlipped);
        }
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawInterior:(NSRect)aDirtyRect
{
    [self drawLabel:aDirtyRect];

    if (self.isRecording)
    {
        [self drawSnapBackButton:aDirtyRect];
        [self drawClearButton:aDirtyRect];
    }
}

- (void)drawLabel:(NSRect)aDirtyRect
{
    NSString *label = self.label;
    NSDictionary *labelAttributes = self.labelAttributes;
    NSRect labelRect = [self rectForLabel:label withAttributes:labelAttributes];

    if (!NSIntersectsRect(labelRect, aDirtyRect))
        return;

    [NSGraphicsContext saveGraphicsState];
    [label drawInRect:labelRect withAttributes:labelAttributes];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawSnapBackButton:(NSRect)aDirtyRect
{
    NSRect imageRect = self.snapBackButtonRect;
    imageRect.origin.x += _SRRecorderControlSnapBackButtonLeftOffset;
    imageRect.origin.y += floor(self.alignmentRectInsets.top + (NSHeight(imageRect) - _SRRecorderControlSnapBackButtonSize.height) / 2.0);
    imageRect.size = _SRRecorderControlSnapBackButtonSize;
    imageRect = [self centerScanRect:imageRect];

    if (!NSIntersectsRect(imageRect, aDirtyRect))
        return;

    [NSGraphicsContext saveGraphicsState];

    if (self.isSnapBackButtonHighlighted)
    {
        [_SRImages[14] drawInRect:imageRect
                         fromRect:NSZeroRect
                        operation:NSCompositeSourceOver
                         fraction:1.0];
    }
    else
    {
        [_SRImages[15] drawInRect:imageRect
                         fromRect:NSZeroRect
                        operation:NSCompositeSourceOver
                         fraction:1.0];
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawClearButton:(NSRect)aDirtyRect
{
    NSRect imageRect = self.clearButtonRect;
    imageRect.origin.x += _SRRecorderControlClearButtonLeftOffset;
    imageRect.origin.y += floor(self.alignmentRectInsets.top + (NSHeight(imageRect) - _SRRecorderControlClearButtonSize.height) / 2.0);
    imageRect.size = _SRRecorderControlClearButtonSize;
    imageRect = [self centerScanRect:imageRect];

    if (!NSIntersectsRect(imageRect, aDirtyRect))
        return;

    [NSGraphicsContext saveGraphicsState];

    if (self.isClearButtonHighlighted)
    {
        [_SRImages[12] drawInRect:imageRect
                         fromRect:NSZeroRect
                        operation:NSCompositeSourceOver
                         fraction:1.0];
    }
    else
    {
        [_SRImages[13] drawInRect:imageRect
                         fromRect:NSZeroRect
                        operation:NSCompositeSourceOver
                         fraction:1.0];
    }

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

- (BOOL)isSnapBackButtonHighlighted
{
    if (_mouseTrackingButtonTag == _SRRecorderControlSnapBackButtonTag)
    {
        NSPoint locationInView = [self convertPoint:self.window.mouseLocationOutsideOfEventStream
                                           fromView:nil];
        return [self mouse:locationInView inRect:self.snapBackButtonRect];
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
        return [self mouse:locationInView inRect:self.clearButtonRect];
    }
    else
        return NO;
}

- (BOOL)areModifierFlagsValid:(NSUInteger)aModifierFlags
{
    aModifierFlags &= SRCocoaModifierFlagsMask;
    return (aModifierFlags & self.requiredModifierFlags) == self.requiredModifierFlags &&
    (aModifierFlags & self.allowedModifierFlags) == aModifierFlags;
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
            NSAccessibilityTitleAttribute
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
    else
        return [super accessibilityAttributeValue:anAttributeName];
}

- (NSArray *)accessibilityActionNames
{
    static NSArray *ActionNames = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^
                  {
                      ActionNames = @[
                      NSAccessibilityPressAction,
                      NSAccessibilityCancelAction,
                      NSAccessibilityDeleteAction
                      ];
                  });
    return ActionNames;
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


#pragma mark NSKeyValueBindingCreation

- (Class)valueClassForBinding:(NSString *)aBinding
{
    if ([aBinding isEqualToString:NSValueBinding])
        return [NSDictionary class];
    else
        return [super valueClassForBinding:aBinding];
}

- (void)bind:(NSString *)aBinding toObject:(id)anObservable withKeyPath:(NSString *)aKeyPath options:(NSDictionary *)anOptions
{
    if ([aBinding isEqualToString:NSValueBinding])
    {
        [self unbind:aBinding];

        [anObservable addObserver:self
                       forKeyPath:aKeyPath
                          options:0
                          context:&_SRValueObservationContext];
        _bindingInfo[aBinding] = @{
            NSObservedObjectKey: anObservable,
            NSObservedKeyPathKey: [aKeyPath copy],
            NSOptionsKey: [NSDictionary dictionaryWithDictionary:anOptions]
        };
        self.objectValue = [anObservable valueForKeyPath:aKeyPath];

        // This method is typically called when view is not presented to a user.
        // If'd use -setNeedsDisplay:, the user may notice flickering when window with view is shown first time.
        // Therefore ensure view is shown with correct value drawn by -displayIfNeeded
        [self displayIfNeeded];
    }
    else
        [super bind:aBinding toObject:anObservable withKeyPath:aKeyPath options:anOptions];
}

- (NSDictionary *)infoForBinding:(NSString *)aBinding
{
    NSDictionary *info = _bindingInfo[aBinding];

    if (!info)
        info = [super infoForBinding:aBinding];

    return info;
}

- (void)unbind:(NSString *)aBinding
{
    if ([aBinding isEqualToString:NSValueBinding])
    {
        NSDictionary *valueBindingInfo = _bindingInfo[NSValueBinding];

        if (valueBindingInfo)
        {
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
                [valueBindingInfo[NSObservedObjectKey] removeObserver:self forKeyPath:valueBindingInfo[NSObservedKeyPathKey]];
            else
                [valueBindingInfo[NSObservedObjectKey] removeObserver:self forKeyPath:valueBindingInfo[NSObservedKeyPathKey] context:&_SRValueObservationContext];

            [_bindingInfo removeObjectForKey:NSValueBinding];
        }
    }
    else
        [super unbind:aBinding];
}


#pragma mark NSToolTipOwner

- (NSString *)view:(NSView *)aView stringForToolTip:(NSToolTipTag)aTag point:(NSPoint)aPoint userData:(void *)aData
{
    if (aTag == _snapBackButtonToolTipTag)
        return SRLoc(@"Use old shortcut");
    else
        return [super view:aView stringForToolTip:aTag point:aPoint userData:aData];
}


#pragma mark NSView

- (BOOL)isOpaque
{
    return NO;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)viewWillDraw
{
    [super viewWillDraw];

    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        _SRImages[0] = SRImage(@"shortcut-recorder-bezel-blue-highlighted-left");
        _SRImages[1] = SRImage(@"shortcut-recorder-bezel-blue-highlighted-middle");
        _SRImages[2] = SRImage(@"shortcut-recorder-bezel-blue-highlighted-right");
        _SRImages[3] = SRImage(@"shortcut-recorder-bezel-editing-left");
        _SRImages[4] = SRImage(@"shortcut-recorder-bezel-editing-middle");
        _SRImages[5] = SRImage(@"shortcut-recorder-bezel-editing-right");
        _SRImages[6] = SRImage(@"shortcut-recorder-bezel-graphite-highlight-mask-left");
        _SRImages[7] = SRImage(@"shortcut-recorder-bezel-graphite-highlight-mask-middle");
        _SRImages[8] = SRImage(@"shortcut-recorder-bezel-graphite-highlight-mask-right");
        _SRImages[9] = SRImage(@"shortcut-recorder-bezel-left");
        _SRImages[10] = SRImage(@"shortcut-recorder-bezel-middle");
        _SRImages[11] = SRImage(@"shortcut-recorder-bezel-right");
        _SRImages[12] = SRImage(@"shortcut-recorder-clear-highlighted");
        _SRImages[13] = SRImage(@"shortcut-recorder-clear");
        _SRImages[14] = SRImage(@"shortcut-recorder-snapback-highlighted");
        _SRImages[15] = SRImage(@"shortcut-recorder-snapback");
    });
}


- (void)drawRect:(NSRect)aDirtyRect
{
    [self drawBackground:aDirtyRect];
    [self drawInterior:aDirtyRect];

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
    {
        if (self.window.firstResponder == self)
        {
            [NSGraphicsContext saveGraphicsState];
            NSSetFocusRingStyle(NSFocusRingOnly);
            [self.controlShape fill];
            [NSGraphicsContext restoreGraphicsState];
        }
    }
}

- (void)drawFocusRingMask
{
    [self.controlShape fill];
}

- (NSRect)focusRingMaskBounds
{
    return self.controlShape.bounds;
}

- (NSEdgeInsets)alignmentRectInsets
{
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6 || self.window == nil)
        return NSEdgeInsetsMake(0.0, 0.0, _SRRecorderControlBottomShadowHeightInPixels, 0.0);
    else
        return NSEdgeInsetsMake(0.0, 0.0, _SRRecorderControlBottomShadowHeightInPixels / self.window.backingScaleFactor, 0.0);
}

- (CGFloat)baselineOffsetFromBottom
{
    return (NSHeight(self.bounds) - _SRRecorderControlHeight) + floor(_SRRecorderControlBaselineOffset - [self.labelAttributes[NSFontAttributeName] descender]);
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(NSWidth([self rectForLabel:SRLoc(@"Click to record shortcut") withAttributes:self.normalLabelAttributes]) + _SRRecorderControlShapeXRadius + _SRRecorderControlShapeXRadius,
                      _SRRecorderControlHeight);
}


- (void)updateTrackingAreas
{
    static const NSUInteger TrackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder | NSTrackingEnabledDuringMouseDrag;

    if (_mainButtonTrackingArea != nil)
        [self removeTrackingArea:_mainButtonTrackingArea];

    _mainButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                        options:TrackingOptions
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:_mainButtonTrackingArea];

    if (_snapBackButtonTrackingArea)
    {
        [self removeTrackingArea:_snapBackButtonTrackingArea];
        _snapBackButtonTrackingArea = nil;
    }

    if (_clearButtonTrackingArea)
    {
        [self removeTrackingArea:_clearButtonTrackingArea];
        _clearButtonTrackingArea = nil;
    }

    if (_snapBackButtonToolTipTag != NSIntegerMax)
    {
        [self removeToolTip:_snapBackButtonToolTipTag];
        _snapBackButtonToolTipTag = NSIntegerMax;
    }

    if (self.isRecording)
    {
        _snapBackButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:self.snapBackButtonRect
                                                                   options:TrackingOptions
                                                                     owner:self
                                                                  userInfo:nil];
        [self addTrackingArea:_snapBackButtonTrackingArea];
        _clearButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:self.clearButtonRect
                                                                options:TrackingOptions
                                                                  owner:self
                                                               userInfo:nil];
        [self addTrackingArea:_clearButtonTrackingArea];

        // Since this method is used to set up tracking rects of aux buttons, the rest of the code is aware
        // it should be called whenever geometry or apperance changes. Therefore it's a good place to set up tooltip rects.
        _snapBackButtonToolTipTag = [self addToolTipRect:[_snapBackButtonTrackingArea rect] owner:self userData:NULL];
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)aWindow
{
    if (self.window)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSWindowDidResignKeyNotification
                                                      object:self.window];
    }

    if (aWindow)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(endRecording)
                                                     name:NSWindowDidResignKeyNotification
                                                   object:aWindow];
    }

    [super viewWillMoveToWindow:aWindow];
}


#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
    return YES;
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
    return [super canBecomeKeyView] && [NSApp isFullKeyboardAccessEnabled];
}

- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

- (void)mouseDown:(NSEvent *)anEvent
{
    NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];

    if (self.isRecording)
    {
        if ([self mouse:locationInView inRect:self.snapBackButtonRect])
        {
            _mouseTrackingButtonTag = _SRRecorderControlSnapBackButtonTag;
            [self setNeedsDisplayInRect:self.snapBackButtonRect];
        }
        else if ([self mouse:locationInView inRect:self.clearButtonRect])
        {
            _mouseTrackingButtonTag = _SRRecorderControlClearButtonTag;
            [self setNeedsDisplayInRect:self.clearButtonRect];
        }
    }
    else if ([self mouse:locationInView inRect:self.bounds])
    {
        _mouseTrackingButtonTag = _SRRecorderControlMainButtonTag;
        [self setNeedsDisplay:YES];
    }

    [super mouseDown:anEvent];
}

- (void)mouseUp:(NSEvent *)anEvent
{
    if (_mouseTrackingButtonTag != _SRRecorderControlInvalidButtonTag)
    {
        NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];

        if (_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag &&
            [self mouse:locationInView inRect:self.bounds])
        {
            [self beginRecording];
        }
        else if (_mouseTrackingButtonTag == _SRRecorderControlSnapBackButtonTag &&
                 [self mouse:locationInView inRect:self.snapBackButtonRect])
        {
            [self endRecording];
        }
        else if (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag &&
                 [self mouse:locationInView inRect:self.clearButtonRect])
        {
            [self clearAndEndRecording];
        }

        _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
    }

    [super mouseUp:anEvent];
}

- (void)mouseEntered:(NSEvent *)anEvent
{
    if ((_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag && anEvent.trackingArea == _mainButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlSnapBackButtonTag && anEvent.trackingArea == _snapBackButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag && anEvent.trackingArea == _clearButtonTrackingArea))
    {
        [self setNeedsDisplayInRect:anEvent.trackingArea.rect];
    }

    [super mouseEntered:anEvent];
}

- (void)mouseExited:(NSEvent *)anEvent
{
    if ((_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag && anEvent.trackingArea == _mainButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlSnapBackButtonTag && anEvent.trackingArea == _snapBackButtonTrackingArea) ||
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
    if (self.window.firstResponder != self)
        return NO;

    if (_mouseTrackingButtonTag != _SRRecorderControlInvalidButtonTag)
        return NO;

    if (self.isRecording)
    {
        if (self.allowsEscapeToCancelRecording &&
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
        else if ([self areModifierFlagsValid:anEvent.modifierFlags])
        {
            NSDictionary *newObjectValue = @{
                SRShortcutKeyCode: @(anEvent.keyCode),
                SRShortcutModifierFlagsKey: @(anEvent.modifierFlags & SRCocoaModifierFlagsMask),
                SRShortcutCharacters: anEvent.characters,
                SRShortcutCharactersIgnoringModifiers: anEvent.charactersIgnoringModifiers
            };

            if ([self.delegate respondsToSelector:@selector(shortcutRecorder:canRecordShortcut:)])
            {
                if (![self.delegate shortcutRecorder:self canRecordShortcut:newObjectValue])
                {
                    // We acutally handled key equivalent, because client likely performs some action
                    // to represent an error (e.g. beep and error dialog.
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
        if (![self areModifierFlagsValid:anEvent.modifierFlags])
            NSBeep();

        [self setNeedsDisplay:YES];
    }
    else
        [super flagsChanged:anEvent];
}


#pragma mark NSObject

+ (void)initialize
{
    if (self == [SRRecorderControl class])
        [self exposeBinding:NSValueBinding];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if (aContext == &_SRValueObservationContext)
    {
        id newObjectValue = [anObject valueForKeyPath:aKeyPath];

        if (NSIsControllerMarker(newObjectValue))
            [NSException raise:NSInternalInconsistencyException format:@"SRRecorderControl's NSValueBinding does not support controller value markers."];

        NSValueTransformer *valueTransformer = _SRValueTransformerFromBindingOptions(_bindingInfo[NSValueBinding][NSOptionsKey]);

        if (valueTransformer)
            newObjectValue = [valueTransformer transformedValue:newObjectValue];

        self.objectValue = newObjectValue;
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end
