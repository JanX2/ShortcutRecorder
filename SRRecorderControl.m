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


static const CGFloat _SRRecorderControlShapeXRadius = 11.0;

static const CGFloat _SRRecorderControlShapeYRadius = 12.0;

static const CGFloat _SRRecorderControlHeight = 25.0;

static const CGFloat _SRRecorderControlBottomShadowHeightInPixels = 1.0;

static const CGFloat _SRRecorderControlClearButtonRightOffset = 4.0;

static const CGFloat _SRRecorderControlClearButtonLeftOffset = 1.0;

static const CGFloat _SRRecorderControlSnapBackButtonRightOffset = 1.0;

static const CGFloat _SRRecorderControlSnapBackButtonLeftOffset = 3.0;

static const NSSize _SRRecorderControlSnapBackButtonSize = {.width = 14.0, .height = 14.0};

static const NSSize _SRRecorderControlClearButtonSize = {.width = 14.0, .height = 14.0};

static const CGFloat _SRRecorderControlBaselineOffset = 5.0;


static NSImage *_SRImages[16];


typedef NS_ENUM(NSUInteger, _SRRecorderControlButtonTag)
{
    _SRRecorderControlInvalidButtonTag = -1,
    _SRRecorderControlSnapBackButtonTag = 0,
    _SRRecorderControlClearButtonTag = 1,
    _SRRecorderControlMainButtonTag = 2
};


@implementation SRRecorderControl
{
    NSTrackingArea *_mainButtonTrackingArea;
    NSTrackingArea *_snapBackButtonTrackingArea;
    NSTrackingArea *_clearButtonTrackingArea;

    _SRRecorderControlButtonTag _mouseTrackingButtonTag;
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

        if ([self respondsToSelector:@selector(setTranslatesAutoresizingMaskIntoConstraints:)])
            self.translatesAutoresizingMaskIntoConstraints = YES;

        if ([self respondsToSelector:@selector(setContentHuggingPriority:forOrientation:)])
        {
            [self setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
            [self setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutPriorityRequired];
        }

        if ([self respondsToSelector:@selector(setContentCompressionResistancePriority:forOrientation:)])
        {
            [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
            [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutPriorityRequired];
        }

        [self updateTrackingAreas];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


#pragma mark Methods

- (BOOL)beginRecording
{
    if (self.isRecording)
        return YES;

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
    if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
        [self invalidateIntrinsicContentSize];
    [self updateTrackingAreas];
    [self setNeedsDisplay:YES];
    return YES;
}

- (void)endRecording
{
    if (!self.isRecording)
        return;

    [self willChangeValueForKey:@"isRecording"];
    _isRecording = NO;
    [self didChangeValueForKey:@"isRecording"];
    if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
        [self invalidateIntrinsicContentSize];
    [self updateTrackingAreas];
    [self setNeedsDisplay:YES];

    if ([self.delegate respondsToSelector:@selector(shortcutRecorderDidEndRecording:)])
        [self.delegate shortcutRecorderDidEndRecording:self];
}

- (void)clearAndEndRecording
{
    self.objectValue = nil;
    [self endRecording];
}

- (BOOL)areModifierFlagsValid:(NSUInteger)aModifierFlags
{
    aModifierFlags &= SRCocoaModifierFlagsMask;
    return (aModifierFlags & self.requiredModifierFlags) == self.requiredModifierFlags &&
            (aModifierFlags & self.allowedModifierFlags) == aModifierFlags;
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

- (NSRect)enclosingLabelRect
{
    return NSInsetRect(self.bounds, _SRRecorderControlShapeXRadius, 0.0);
}

- (NSRect)rectForLabel:(NSString *)aLabel withAttributes:(NSDictionary *)anAttributes
{
    NSFont *font = anAttributes[NSFontAttributeName];
    NSSize labelSize = [aLabel sizeWithAttributes:anAttributes];
    labelSize.width = ceil(labelSize.width);
    labelSize.height = ceil(labelSize.height);
    CGFloat fontBaselineOffsetFromTop = labelSize.height + font.descender;
    CGFloat baselineOffsetFromTop = _SRRecorderControlHeight - self.alignmentRectInsets.bottom - self.baselineOffsetFromBottom;
    NSRect labelRect = {
        .origin = NSMakePoint(NSMidX(self.bounds) - labelSize.width / 2.0, baselineOffsetFromTop - fontBaselineOffsetFromTop),
        .size = labelSize
    };
    labelRect = [self centerScanRect:labelRect];
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
            NSString *c = nil;

            if (self.drawsASCIIEquivalentOfShortcut)
                c = [[[SRKeyCodeTransformer sharedPlainASCIITransformer] transformedValue:self.objectValue[SRShortcutKeyCode]] uppercaseString];
            else
                c = [[[SRKeyCodeTransformer sharedPlainTransformer] transformedValue:self.objectValue[SRShortcutKeyCode]] uppercaseString];

            label = [NSString stringWithFormat:@"%@%@", f, c];
        }
        else
            label = SRLoc(@"Click to record shortcut");
    }

    return label;
}

- (NSDictionary *)labelAttributes
{
    static dispatch_once_t OnceToken;
    static NSDictionary *NormalAttributes = nil;
    static NSDictionary *RecordingAttributes = nil;
    dispatch_once(&OnceToken, ^{
        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        p.alignment = NSCenterTextAlignment;
        p.lineBreakMode = NSLineBreakByClipping;
        p.baseWritingDirection = NSWritingDirectionLeftToRight;
        NormalAttributes = @{
            NSParagraphStyleAttributeName: p,
            NSFontAttributeName: [NSFont labelFontOfSize:[NSFont systemFontSize]],
            NSForegroundColorAttributeName: [NSColor controlTextColor]
        };
        RecordingAttributes = @{
            NSParagraphStyleAttributeName: p,
            NSFontAttributeName: [NSFont labelFontOfSize:[NSFont systemFontSize]],
            NSForegroundColorAttributeName: [NSColor disabledControlTextColor]
        };
    });

    return self.isRecording ? RecordingAttributes : NormalAttributes;
}

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
    [NSGraphicsContext saveGraphicsState];
    NSDictionary *attributes = self.labelAttributes;
    NSString *label = self.label;
    NSRect rect = [self rectForLabel:label withAttributes:attributes];
    [label drawInRect:rect withAttributes:attributes];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawSnapBackButton:(NSRect)aDirtyRect
{
    NSRect imageRect = self.snapBackButtonRect;
    imageRect.origin.x += _SRRecorderControlSnapBackButtonLeftOffset;
    imageRect.origin.y += self.alignmentRectInsets.top + (NSHeight(imageRect) - _SRRecorderControlSnapBackButtonSize.height) / 2.0;
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
    imageRect.origin.y += self.alignmentRectInsets.top + (NSHeight(imageRect) - _SRRecorderControlClearButtonSize.height) / 2.0;
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


#pragma mark NSToolTipOwner

- (NSString *)view:(NSView *)aView stringForToolTip:(NSToolTipTag)aTag point:(NSPoint)aPoint userData:(void *)aData
{
    if (self.isRecording && [self mouse:aPoint inRect:_snapBackButtonTrackingArea.rect])
        return SRLoc(@"Use old shortcut");
    else
        return [super view:aView stringForToolTip:aTag point:aPoint userData:aData];
}


#pragma mark SRRecorderCellDelegate
//
//- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell
//                   isKeyCode:(NSInteger)keyCode
//               andFlagsTaken:(NSUInteger)flags
//                      reason:(NSString **)aReason
//{
//    if ([delegate respondsToSelector:@selector(shortcutRecorder:isKeyCode:andFlagsTaken:reason:)])
//        return [delegate shortcutRecorder:self isKeyCode:keyCode andFlagsTaken:flags reason:aReason];
//    else
//        return NO;
//}
//
//- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(KeyCombo)newKeyCombo
//{
//    if ([delegate respondsToSelector:@selector(shortcutRecorder:keyComboDidChange:)])
//        [delegate shortcutRecorder:self keyComboDidChange:newKeyCombo];
//
//    // propagate view changes to binding (see http://www.tomdalling.com/cocoa/implementing-your-own-cocoa-bindings)
//    NSDictionary *bindingInfo = [self infoForBinding:@"value"];
//    if (!bindingInfo)
//        return;
//    // apply the value transformer, if one has been set
//    NSDictionary *value = [self objectValue];
//    NSDictionary *bindingOptions = [bindingInfo objectForKey:NSOptionsKey];
//    if (bindingOptions != nil)
//    {
//        NSValueTransformer *transformer = [bindingOptions valueForKey:NSValueTransformerBindingOption];
//        if (NilOrNull(transformer))
//        {
//            NSString *transformerName = [bindingOptions valueForKey:NSValueTransformerNameBindingOption];
//            if (!NilOrNull(transformerName))
//                transformer = [NSValueTransformer valueTransformerForName:transformerName];
//        }
//        if (!NilOrNull(transformer))
//        {
//            if ([[transformer class] allowsReverseTransformation])
//                value = [transformer reverseTransformedValue:value];
//            else
//                NSLog(@"WARNING: value has value transformer, but it doesn't allow reverse transformations in %s", __PRETTY_FUNCTION__);
//        }
//    }
//    id boundObject = [bindingInfo objectForKey:NSObservedObjectKey];
//    if (NilOrNull(boundObject))
//    {
//        NSLog(@"ERROR: NSObservedObjectKey was nil for value binding in %s", __PRETTY_FUNCTION__);
//        return;
//    }
//    NSString *boundKeyPath = [bindingInfo objectForKey:NSObservedKeyPathKey];
//    if (NilOrNull(boundKeyPath))
//    {
//        NSLog(@"ERROR: NSObservedKeyPathKey was nil for value binding in %s", __PRETTY_FUNCTION__);
//        return;
//    }
//    [boundObject setValue:value forKeyPath:boundKeyPath];
//}
//
//- (BOOL)shortcutRecorderCellShouldCheckMenu:(SRRecorderCell *)aRecorderCell
//{
//    if (delegate != nil && [delegate respondsToSelector:@selector(shortcutRecorderShouldCheckMenu:)])
//        return [delegate shortcutRecorderShouldCheckMenu:self];
//    else
//        return NO;
//}
//
//- (BOOL)shortcutRecorderCellShouldSystemShortcuts:(SRRecorderCell *)aRecorderCell
//{
//    if (delegate != nil && [delegate respondsToSelector:@selector(shortcutRecorderShouldSystemShortcuts:)])
//        return [delegate shortcutRecorderShouldSystemShortcuts:self];
//    else
//        return YES;
//}


#pragma mark


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
    return floor(_SRRecorderControlBaselineOffset - [self.labelAttributes[NSFontAttributeName] descender]);
}

- (NSSize)intrinsicContentSize
{
    NSString *label = self.label;
    NSDictionary *attributes = self.labelAttributes;
    if (self.isRecording)
    {
        return NSMakeSize(NSWidth([self rectForLabel:label withAttributes:attributes]) + 2 * (NSWidth(self.snapBackButtonRect) + NSWidth(self.clearButtonRect)),
                          _SRRecorderControlHeight);
    }
    else
    {
        return NSMakeSize(NSWidth([self rectForLabel:label withAttributes:attributes]) + 2 * _SRRecorderControlShapeXRadius,
                          _SRRecorderControlHeight);
    }
}

- (void)updateTrackingAreas
{
    static const NSUInteger TrackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder | NSTrackingEnabledDuringMouseDrag;

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
        [self removeAllToolTips];
        [self addToolTipRect:[_snapBackButtonTrackingArea rect] owner:self userData:NULL];
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

- (BOOL)resignFirstResponder
{
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
    return [[NSApplication sharedApplication] isFullKeyboardAccessEnabled];
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
    if (![self.window.firstResponder isEqual:self])
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
                    NSBeep();
                    return NO;
                }
            }

            self.objectValue = newObjectValue;
            [self endRecording];
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

        if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
            [self invalidateIntrinsicContentSize];

        [self setNeedsDisplayInRect:[self enclosingLabelRect]];
    }
    else
        [super flagsChanged:anEvent];
}

@end
