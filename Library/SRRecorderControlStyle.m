//
//  SRRecorderControlStyle.m
//  ShortcutRecorder.framework
//
//  Copyright 2019 Contributors. All rights reserved.
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

#import "SRRecorderControl.h"

#import "SRRecorderControlStyle.h"


@implementation SRRecorderControlStyle
{
    NSLayoutConstraint *_backgroundTopConstraint;
    NSLayoutConstraint *_backgroundLeftConstraint;
    NSLayoutConstraint *_backgroundBottomConstraint;
    NSLayoutConstraint *_backgroundRightConstraint;

    NSLayoutConstraint *_alignmentSuggestedWidthConstraint;
    NSLayoutConstraint *_alignmentWidthConstraint;
    NSLayoutConstraint *_alignmentHeightConstraint;
    NSLayoutConstraint *_alignmentToLabelConstraint;

    NSLayoutConstraint *_labelToAlignmentConstraint;
    NSLayoutConstraint *_labelToCancelConstraint;
    NSLayoutConstraint *_cancelToAlignmentConstraint;
    NSLayoutConstraint *_clearToAlignmentConstraint;
    NSLayoutConstraint *_cancelButtonHeightConstraint;
    NSLayoutConstraint *_cancelButtonWidthConstraint;
    NSLayoutConstraint *_clearButtonHeightConstraint;
    NSLayoutConstraint *_clearButtonWidthConstraint;
    NSLayoutConstraint *_cancelToClearConstraint;
}

+ (instancetype)styleWithIdentifier:(NSString *)anIdentifier
{
    return [[self alloc] initWithIdentifier:anIdentifier];
}

- (instancetype)initWithIdentifier:(NSString *)anIdentifier
{
    if (self = [super init])
    {
        _identifier = anIdentifier.copy;
        _allowsVibrancy = NO;
        _opaque = NO;
        _alwaysConstraints = @[];
        _displayingConstraints = @[];
        _recordingWithValueConstraints = @[];
        _recordingWithNoValueConstraints = @[];
        _alignmentGuide = [NSLayoutGuide new];
        _backgroundDrawingGuide = [NSLayoutGuide new];
        _labelDrawingGuide = [NSLayoutGuide new];
        _cancelButtonDrawingGuide = [NSLayoutGuide new];
        _clearButtonDrawingGuide = [NSLayoutGuide new];
        _cancelButtonLayoutGuide = [NSLayoutGuide new];
        _clearButtonLayoutGuide = [NSLayoutGuide new];
    }

    return self;
}

#pragma mark Methods

- (NSImage *)loadImageNamed:(NSString *)aName
{
    NSImage *img = nil;

    for (NSString *p in _lookupPrefixes)
    {
        NSString *prefixedName = [NSString stringWithFormat:@"%@-%@", p, aName];
        img = SRImage(prefixedName);

        // Allow loading from the main bundle.
        if (!img)
            img = [NSImage imageNamed:prefixedName];

        if (img)
            break;
    }

    if (!img)
        img = SRImage(aName);

    if (!img)
        img = [NSImage imageNamed:aName];

    return img;
}

- (NSDictionary *)loadMetrics
{
    NSData *data = nil;

    for (NSString *p in _lookupPrefixes)
    {
        NSString *prefixedName = [NSString stringWithFormat:@"%@-%@", p, @"metrics"];
        data = [[NSDataAsset alloc] initWithName:prefixedName bundle:SRBundle()].data;

        // Allow loading from the main bundle.
        if (!data)
            data = [[NSDataAsset alloc] initWithName:prefixedName].data;

        if (data)
            break;
    }

    if (!data)
        data = [[NSDataAsset alloc] initWithName:@"metrics" bundle:SRBundle()].data;

    if (!data)
        data = [[NSDataAsset alloc] initWithName:@"metrics"].data;

    NSError *error = nil;
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!d)
        [NSException raise:NSInternalInconsistencyException format:@"%@", error.localizedFailureReason];

    return d;
}


- (NSArray<NSString *> *)makeLookupPrefixes
{
    if ([self.identifier hasSuffix:@"-"])
        return @[[self.identifier substringToIndex:self.identifier.length - 1]];

    NSMutableArray *loadOrder = NSMutableArray.array;

    NSArray *controlTintFragments = NSColor.currentControlTint == NSBlueControlTint ? @[@"-blue", @"-graphite", @""] : @[@"-graphite", @"-blue", @""];
    NSArray *accFragments = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast ? @[@"-acc", @""] : @[@"", @"-acc"];

    NSAppearanceName macOSAppearanceName = self.controlView.effectiveAppearance.name.copy;

    if (!macOSAppearanceName)
        macOSAppearanceName = NSAppearance.currentAppearance.name;

    if (!macOSAppearanceName)
        macOSAppearanceName = NSAppearanceNameAqua;

    NSArray *appearanceFragments = nil;

    if (@available(macOS 10.14, *))
    {
        if ([macOSAppearanceName isEqualToString:NSAppearanceNameDarkAqua])
            appearanceFragments = @[@"-darkaqua", @"-vibrantdark", @"-aqua", @"-vibrantlight", @""];
    }

    if ([macOSAppearanceName isEqualToString:NSAppearanceNameVibrantLight])
        appearanceFragments = @[@"-vibrantlight", @"-aqua", @"-vibrantdark", @"-darkaqua", @""];
    else if ([macOSAppearanceName isEqualToString:NSAppearanceNameVibrantDark])
        appearanceFragments = @[@"-vibrantdark", @"-darkaqua", @"-vibrantlight", @"-aqua", @""];
    else
        appearanceFragments = @[@"-aqua", @"-vibrantlight", @"-darkaqua", @"-vibrantdark", @""];

    for (NSString *appearance in appearanceFragments)
    {
        for (NSString *tint in controlTintFragments)
        {
            for (NSString *acc in accFragments)
            {
                [loadOrder addObject:[NSString stringWithFormat:@"%@%@%@%@", self->_prefix, appearance, tint, acc]];
            }
        }
    }

    return loadOrder.copy;
}


- (void)addConstraints
{
    [self.controlView addLayoutGuide:self.alignmentGuide];
    [self.controlView addLayoutGuide:self.backgroundDrawingGuide];
    [self.controlView addLayoutGuide:self.labelDrawingGuide];
    [self.controlView addLayoutGuide:self.cancelButtonDrawingGuide];
    [self.controlView addLayoutGuide:self.clearButtonDrawingGuide];
    [self.controlView addLayoutGuide:self.cancelButtonLayoutGuide];
    [self.controlView addLayoutGuide:self.clearButtonLayoutGuide];

    __auto_type SetConstraint = ^(NSLayoutConstraint * __strong *var, NSLayoutConstraint *value) {
        *var = value;
        return value;
    };

    __auto_type MakeConstraint = ^(NSLayoutAnchor * _Nonnull firstItem, NSLayoutAnchor * _Nullable secondItem, CGFloat constant, NSLayoutPriority priority, NSLayoutRelation relation) {
        NSLayoutConstraint *c = nil;

        if (secondItem)
        {
            switch (relation)
            {
                case NSLayoutRelationEqual:
                    c = [firstItem constraintEqualToAnchor:secondItem constant:constant];
                    break;
                case NSLayoutRelationGreaterThanOrEqual:
                    c = [firstItem constraintGreaterThanOrEqualToAnchor:secondItem constant:constant];
                    break;
                case NSLayoutRelationLessThanOrEqual:
                    c = [firstItem constraintLessThanOrEqualToAnchor:secondItem constant:constant];
                    break;
            }
        }
        else
        {
            NSAssert([firstItem isKindOfClass:NSLayoutDimension.class], @"Only dimensional anchors allow constant constraints.");

            switch (relation)
            {
                case NSLayoutRelationEqual:
                    c = [(NSLayoutDimension *)firstItem constraintEqualToConstant:constant];
                    break;
                case NSLayoutRelationGreaterThanOrEqual:
                    c = [(NSLayoutDimension *)firstItem constraintGreaterThanOrEqualToConstant:constant];
                    break;
                case NSLayoutRelationLessThanOrEqual:
                    c = [(NSLayoutDimension *)firstItem constraintLessThanOrEqualToConstant:constant];
                    break;
            }
        }

        c.priority = priority;
        return c;
    };

    __auto_type MakeEqConstraint = ^(NSLayoutAnchor * _Nonnull firstItem, NSLayoutAnchor * _Nullable secondItem) {
        return MakeConstraint(firstItem, secondItem, 0.0, NSLayoutPriorityRequired, NSLayoutRelationEqual);
    };

    __auto_type MakeGteConstraint = ^(NSLayoutAnchor * _Nonnull firstItem, NSLayoutAnchor * _Nullable secondItem) {
        return MakeConstraint(firstItem, secondItem, 0.0, NSLayoutPriorityRequired, NSLayoutRelationGreaterThanOrEqual);
    };

    _alwaysConstraints = @[
        MakeEqConstraint(self.alignmentGuide.topAnchor, self.controlView.topAnchor),
        MakeEqConstraint(self.alignmentGuide.leftAnchor, self.controlView.leftAnchor),
        MakeEqConstraint(self.alignmentGuide.rightAnchor, self.controlView.rightAnchor),
        MakeConstraint(self.alignmentGuide.bottomAnchor, self.controlView.bottomAnchor, 0.0, NSLayoutPriorityDefaultHigh, NSLayoutRelationEqual),
        SetConstraint(&_alignmentHeightConstraint, MakeEqConstraint(self.alignmentGuide.heightAnchor, nil)),
        SetConstraint(&_alignmentWidthConstraint, MakeGteConstraint(self.alignmentGuide.widthAnchor, nil)),
        SetConstraint(&_alignmentSuggestedWidthConstraint, MakeConstraint(self.alignmentGuide.widthAnchor, nil, 0.0, NSLayoutPriorityDefaultLow, NSLayoutRelationEqual)),

        SetConstraint(&_backgroundTopConstraint, MakeEqConstraint(self.backgroundDrawingGuide.topAnchor, self.alignmentGuide.topAnchor)),
        SetConstraint(&_backgroundLeftConstraint, MakeEqConstraint(self.backgroundDrawingGuide.leftAnchor, self.alignmentGuide.leftAnchor)),
        SetConstraint(&_backgroundBottomConstraint, MakeEqConstraint(self.backgroundDrawingGuide.bottomAnchor, self.alignmentGuide.bottomAnchor)),
        SetConstraint(&_backgroundRightConstraint, MakeEqConstraint(self.backgroundDrawingGuide.rightAnchor, self.alignmentGuide.rightAnchor)),

        MakeEqConstraint(self.labelDrawingGuide.topAnchor, self.alignmentGuide.topAnchor),
        SetConstraint(&_alignmentToLabelConstraint, MakeGteConstraint(self.labelDrawingGuide.leadingAnchor, self.alignmentGuide.leadingAnchor)),
        MakeEqConstraint(self.labelDrawingGuide.bottomAnchor, self.alignmentGuide.bottomAnchor),
        MakeConstraint(self.labelDrawingGuide.centerXAnchor, self.alignmentGuide.centerXAnchor, 0.0, NSLayoutPriorityDefaultHigh, NSLayoutRelationEqual)
    ];

    _displayingConstraints = @[
        SetConstraint(&_labelToAlignmentConstraint, MakeEqConstraint(self.labelDrawingGuide.trailingAnchor, self.alignmentGuide.trailingAnchor)),
    ];

    _recordingWithNoValueConstraints = @[
        SetConstraint(&_labelToCancelConstraint, MakeEqConstraint(self.labelDrawingGuide.trailingAnchor, self.cancelButtonDrawingGuide.leadingAnchor)),

        SetConstraint(&_cancelToAlignmentConstraint, MakeEqConstraint(self.cancelButtonDrawingGuide.trailingAnchor, self.alignmentGuide.trailingAnchor)),
        MakeEqConstraint(self.cancelButtonDrawingGuide.centerYAnchor, self.alignmentGuide.centerYAnchor),
        SetConstraint(&_cancelButtonWidthConstraint, MakeEqConstraint(self.cancelButtonDrawingGuide.widthAnchor, nil)),
        SetConstraint(&_cancelButtonHeightConstraint, MakeEqConstraint(self.cancelButtonDrawingGuide.heightAnchor, nil)),

        MakeEqConstraint(self.cancelButtonLayoutGuide.topAnchor, self.alignmentGuide.topAnchor),
        MakeEqConstraint(self.cancelButtonLayoutGuide.leadingAnchor, self.cancelButtonDrawingGuide.leadingAnchor),
        MakeEqConstraint(self.cancelButtonLayoutGuide.bottomAnchor, self.alignmentGuide.bottomAnchor),
        MakeEqConstraint(self.cancelButtonLayoutGuide.trailingAnchor, self.cancelButtonDrawingGuide.trailingAnchor),
    ];

    _recordingWithValueConstraints = @[
        _labelToCancelConstraint,

        MakeEqConstraint(self.cancelButtonDrawingGuide.centerYAnchor, self.alignmentGuide.centerYAnchor),
        SetConstraint(&_cancelToClearConstraint, MakeEqConstraint(self.cancelButtonDrawingGuide.trailingAnchor, self.clearButtonDrawingGuide.leadingAnchor)),
        _cancelButtonWidthConstraint,
        _cancelButtonHeightConstraint,

        MakeEqConstraint(self.clearButtonDrawingGuide.centerYAnchor, self.alignmentGuide.centerYAnchor),
        SetConstraint(&_clearToAlignmentConstraint, MakeEqConstraint(self.clearButtonDrawingGuide.trailingAnchor, self.alignmentGuide.trailingAnchor)),
        SetConstraint(&_clearButtonWidthConstraint, MakeEqConstraint(self.clearButtonDrawingGuide.widthAnchor, nil)),
        SetConstraint(&_clearButtonHeightConstraint, MakeEqConstraint(self.clearButtonDrawingGuide.heightAnchor, nil)),

        MakeEqConstraint(self.cancelButtonLayoutGuide.topAnchor, self.alignmentGuide.topAnchor),
        MakeEqConstraint(self.cancelButtonLayoutGuide.leadingAnchor, self.cancelButtonDrawingGuide.leadingAnchor),
        MakeEqConstraint(self.cancelButtonLayoutGuide.bottomAnchor, self.alignmentGuide.bottomAnchor),
        MakeEqConstraint(self.cancelButtonLayoutGuide.trailingAnchor, self.cancelButtonDrawingGuide.trailingAnchor),

        MakeEqConstraint(self.clearButtonLayoutGuide.topAnchor, self.alignmentGuide.topAnchor),
        MakeEqConstraint(self.clearButtonLayoutGuide.leadingAnchor, self.clearButtonDrawingGuide.leadingAnchor),
        MakeEqConstraint(self.clearButtonLayoutGuide.bottomAnchor, self.alignmentGuide.bottomAnchor),
        MakeEqConstraint(self.clearButtonLayoutGuide.trailingAnchor, self.clearButtonDrawingGuide.trailingAnchor),
    ];
}

#pragma mark SRRecorderControlStyling
@synthesize controlView = _controlView;
@synthesize identifier = _identifier;
@synthesize allowsVibrancy = _allowsVibrancy;
@synthesize opaque = _opaque;
@synthesize normalLabelAttributes = _normalLabelAttributes;
@synthesize recordingLabelAttributes = _recordingLabelAttributes;
@synthesize disabledLabelAttributes = _disabledLabelAttributes;
@synthesize bezelNormalLeft = _bezelNormalLeft;
@synthesize bezelNormalCenter = _bezelNormalCenter;
@synthesize bezelNormalRight = _bezelNormalRight;
@synthesize bezelPressedLeft = _bezelPressedLeft;
@synthesize bezelPressedCenter = _bezelPressedCenter;
@synthesize bezelPressedRight = _bezelPressedRight;
@synthesize bezelRecordingLeft = _bezelRecordingLeft;
@synthesize bezelRecordingCenter = _bezelRecordingCenter;
@synthesize bezelRecordingRight = _bezelRecordingRight;
@synthesize bezelDisabledLeft = _bezelDisabledLeft;
@synthesize bezelDisabledCenter = _bezelDisabledCenter;
@synthesize bezelDisabledRight = _bezelDisabledRight;
@synthesize cancelButton = _cancelButton;
@synthesize cancelButtonPressed = _cancelButtonPressed;
@synthesize clearButton = _clearButton;
@synthesize clearButtonPressed = _clearButtonPressed;
@synthesize shapeCornerRadius = _shapeCornerRadius;
@synthesize shapeInsets = _shapeInsets;
@synthesize baselineOffsetFromBottom = _baselineOffsetFromBottom;
@synthesize alignmentRectInsets = _alignmentRectInsets;
@synthesize alignmentGuide = _alignmentGuide;
@synthesize backgroundDrawingGuide = _backgroundDrawingGuide;
@synthesize labelDrawingGuide = _labelDrawingGuide;
@synthesize cancelButtonDrawingGuide = _cancelButtonDrawingGuide;
@synthesize clearButtonDrawingGuide = _clearButtonDrawingGuide;
@synthesize cancelButtonLayoutGuide = _cancelButtonLayoutGuide;
@synthesize clearButtonLayoutGuide = _clearButtonLayoutGuide;
@synthesize alwaysConstraints = _alwaysConstraints;
@synthesize displayingConstraints = _displayingConstraints;
@synthesize recordingWithNoValueConstraints = _recordingWithNoValueConstraints;
@synthesize recordingWithValueConstraints = _recordingWithValueConstraints;

- (void)setControlView:(SRRecorderControl *)newControlView
{
    if (newControlView == _controlView)
        return;

    [_controlView removeLayoutGuide:_alignmentGuide];
    [_controlView removeLayoutGuide:_labelDrawingGuide];
    [_controlView removeLayoutGuide:_cancelButtonDrawingGuide];
    [_controlView removeLayoutGuide:_clearButtonDrawingGuide];
    [_controlView removeLayoutGuide:_cancelButtonLayoutGuide];
    [_controlView removeLayoutGuide:_clearButtonLayoutGuide];

    _controlView = newControlView;
    _lookupPrefixes = nil;
    _metrics = nil;

    if (!_controlView)
        return;

    [self addConstraints];
    [self controlAppearanceDidChange:nil];

    _controlView.needsDisplay = YES;
}

- (void)controlAppearanceDidChange:(nullable id)aReason
{
    NSAssert(self.controlView != nil, @"Style MUST be applied to a control first!");

    NSArray<NSString *> *newLookupPrefixes = [self makeLookupPrefixes];
    if ([_lookupPrefixes isEqual:newLookupPrefixes])
        return;

    _lookupPrefixes = newLookupPrefixes;

    __auto_type UpdateImage = ^(NSString *imageName, NSString *propName, NSRect frame) {
        NSImage *newImage = [self loadImageNamed:imageName];

        NSAssert(newImage != nil, @"Missing image for %@!", imageName);

        if ([newImage isEqual:[self valueForKey:propName]])
            return;

        [self setValue:newImage forKey:propName];

        if (!NSIsEmptyRect(frame))
            [self.controlView setNeedsDisplayInRect:frame];
    };

    NSRect controlBounds = self.controlView.bounds;

    UpdateImage(@"bezel-normal-left", @"bezelNormalLeft", controlBounds);
    UpdateImage(@"bezel-normal-center", @"bezelNormalCenter", controlBounds);
    UpdateImage(@"bezel-normal-right", @"bezelNormalRight", controlBounds);

    UpdateImage(@"bezel-pressed-left", @"bezelPressedLeft", controlBounds);
    UpdateImage(@"bezel-pressed-center", @"bezelPressedCenter", controlBounds);
    UpdateImage(@"bezel-pressed-right", @"bezelPressedRight", controlBounds);

    UpdateImage(@"bezel-recording-left", @"bezelRecordingLeft", controlBounds);
    UpdateImage(@"bezel-recording-center", @"bezelRecordingCenter", controlBounds);
    UpdateImage(@"bezel-recording-right", @"bezelRecordingRight", controlBounds);

    UpdateImage(@"bezel-disabled-left", @"bezelDisabledLeft", controlBounds);
    UpdateImage(@"bezel-disabled-center", @"bezelDisabledCenter", controlBounds);
    UpdateImage(@"bezel-disabled-right", @"bezelDisabledRight", controlBounds);

    UpdateImage(@"button-cancel-normal", @"cancelButton", self.cancelButtonDrawingGuide.frame);
    UpdateImage(@"button-cancel-pressed", @"cancelButtonPressed", self.cancelButtonDrawingGuide.frame);

    UpdateImage(@"button-clear-normal", @"clearButton", self.clearButtonDrawingGuide.frame);
    UpdateImage(@"button-clear-pressed", @"clearButtonPressed", self.clearButtonDrawingGuide.frame);

    _cancelButtonWidthConstraint.constant = self.cancelButton.size.width;
    _cancelButtonHeightConstraint.constant = self.cancelButton.size.height;
    _clearButtonWidthConstraint.constant = self.clearButton.size.width;
    _clearButtonHeightConstraint.constant = self.clearButton.size.height;

    NSDictionary *newMetrics = [self loadMetrics];
    if ([newMetrics isEqual:_metrics])
    {
        return;
    }

    _metrics = newMetrics;

    NSEdgeInsets newAlignmentRectInsets = NSEdgeInsetsMake([_metrics[@"AlignmentInsets"][@"Top"] floatValue],
                                                           [_metrics[@"AlignmentInsets"][@"Left"] floatValue],
                                                           [_metrics[@"AlignmentInsets"][@"Bottom"] floatValue],
                                                           [_metrics[@"AlignmentInsets"][@"Right"] floatValue]);
    if (!NSEdgeInsetsEqual(newAlignmentRectInsets, self.alignmentRectInsets))
    {
        [self setValue:[NSValue valueWithEdgeInsets:newAlignmentRectInsets] forKey:@"alignmentRectInsets"];
    }

    NSSize newShapeCornerRadius = NSMakeSize([_metrics[@"Shape"][@"CornerRadius"][@"Width"] floatValue],
                                             [_metrics[@"Shape"][@"CornerRadius"][@"Height"] floatValue]);
    if (!NSEqualSizes(newShapeCornerRadius, self.shapeCornerRadius))
    {
        [self setValue:[NSValue valueWithSize:newShapeCornerRadius] forKey:@"shapeCornerRadius"];
        [self.controlView noteFocusRingMaskChanged];
    }

    NSEdgeInsets newShapeInsets = NSEdgeInsetsMake([_metrics[@"Shape"][@"Insets"][@"Top"] floatValue],
                                                   [_metrics[@"Shape"][@"Insets"][@"Left"] floatValue],
                                                   [_metrics[@"Shape"][@"Insets"][@"Bottom"] floatValue],
                                                   [_metrics[@"Shape"][@"Insets"][@"Right"] floatValue]);
    if (!NSEdgeInsetsEqual(newShapeInsets, self.shapeInsets))
    {
        [self setValue:[NSValue valueWithEdgeInsets:newShapeInsets] forKey:@"shapeInsets"];
        [self.controlView noteFocusRingMaskChanged];
    }

    CGFloat newBaselineOffsetFromBottom = [_metrics[@"BaselineOffsetFromBottom"] floatValue];
    if (newBaselineOffsetFromBottom != _baselineOffsetFromBottom)
    {
        [self setValue:@(newBaselineOffsetFromBottom) forKey:@"baselineOffsetFromBottom"];
    }

    __auto_type ParseAttrs = ^(NSDictionary *json) {
        if (!json)
            return (NSDictionary *)nil;

        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        p.alignment = NSTextAlignmentCenter;
        p.lineBreakMode = NSLineBreakByTruncatingMiddle;

        NSFont *font = [NSFont fontWithName:json[@"FontName"] size:[json[@"FontSize"] floatValue]];
        NSColor *fontColor = [NSColor colorWithCatalogName:json[@"FontColorCatalogName"] colorName:json[@"FontColorName"]];

        return @{
            NSParagraphStyleAttributeName: [p copy],
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: fontColor
        };
    };

    NSDictionary *normal = ParseAttrs(_metrics[@"NormalLabelAttributes"]);
    if (!normal)
        [NSException raise:NSGenericException format:@"The NormalLabelAttributes key is missing."];

    NSDictionary *recording = ParseAttrs(_metrics[@"RecordingLabelAttributes"]);
    if (!recording)
        recording = normal;

    NSDictionary *disabled = ParseAttrs(_metrics[@"DisabledLabelAttributes"]);
    if (!disabled)
        disabled = normal;

    if (![normal isEqual:self.normalLabelAttributes])
        [self setValue:normal forKey:@"normalLabelAttributes"];

    if (![recording isEqual:self.recordingLabelAttributes])
        [self setValue:recording forKey:@"recordingLabelAttributes"];

    if (![disabled isEqual:self.disabledLabelAttributes])
        [self setValue:disabled forKey:@"disabledLabelAttributes"];

    _alignmentHeightConstraint.constant = fdim([_metrics[@"MinSize"][@"Height"] floatValue], self.alignmentRectInsets.top + self.alignmentRectInsets.bottom);
    _alignmentWidthConstraint.constant = fdim([_metrics[@"MinSize"][@"Width"] floatValue], self.alignmentRectInsets.left + self.alignmentRectInsets.right);

    _backgroundTopConstraint.constant = -self.alignmentRectInsets.top;
    _backgroundLeftConstraint.constant = -self.alignmentRectInsets.left;
    _backgroundBottomConstraint.constant = self.alignmentRectInsets.bottom;
    _backgroundRightConstraint.constant = self.alignmentRectInsets.right;

    _alignmentToLabelConstraint.constant = [_metrics[@"AlignmentToLabel"] floatValue];
    _labelToAlignmentConstraint.constant = -[_metrics[@"LabelToAlignment"] floatValue];
    _labelToCancelConstraint.constant = -[_metrics[@"LabelToCancel"] floatValue];
    _cancelToAlignmentConstraint.constant = -[_metrics[@"ButtonToAlignment"] floatValue];
    _clearToAlignmentConstraint.constant = -[_metrics[@"ButtonToAlignment"] floatValue];
    _cancelToClearConstraint.constant = -[_metrics[@"CancelToClear"] floatValue];

    CGFloat maxExpectedLeadingLabelOffset = _alignmentToLabelConstraint.constant;
    CGFloat maxExpectedLabelWidth = [SRLoc(@"Click to record shortcut") sizeWithAttributes:self.normalLabelAttributes].width;
    CGFloat maxExpectedTrailingLabelOffset = MAX(_alignmentToLabelConstraint.constant, _labelToCancelConstraint.constant + _cancelButtonWidthConstraint.constant + _cancelToClearConstraint.constant + _clearButtonWidthConstraint.constant + _clearToAlignmentConstraint.constant);
    _alignmentSuggestedWidthConstraint.constant = maxExpectedLeadingLabelOffset + maxExpectedLabelWidth + maxExpectedTrailingLabelOffset;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)aZone
{
    return [[self.class alloc] initWithIdentifier:self.identifier];
}


#pragma mark NSObject

- (BOOL)isEqual:(SRRecorderControlStyle *)anObject
{
    return [anObject isKindOfClass:SRRecorderControlStyle.class] && [self.identifier isEqual:anObject.identifier];
}

- (NSUInteger)hash
{
    return self.identifier.hash;
}

@end
