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


SRRecorderControlStyleComponentsAppearance SRRecorderControlStyleComponentsAppearanceFromSystem(NSAppearanceName aSystemAppearanceName)
{
    static NSDictionary<NSAppearanceName, NSNumber *> *Map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Map = @{
            NSAppearanceNameAqua: @(SRRecorderControlStyleComponentsAppearanceAqua),
            NSAppearanceNameVibrantLight: @(SRRecorderControlStyleComponentsAppearanceVibrantLight),
            NSAppearanceNameVibrantDark: @(SRRecorderControlStyleComponentsAppearanceVibrantDark)
        }.mutableCopy;

        if (@available(macOS 10.14, *))
            [(NSMutableDictionary *)Map setObject:@(SRRecorderControlStyleComponentsAppearanceDarkAqua) forKey:NSAppearanceNameDarkAqua];
    });

    NSNumber *appearance = Map[aSystemAppearanceName];


    if (@available(macOS 10.14, *))
    {
        if (!appearance)
        {
            NSAppearance *systemAppearance = [NSAppearance appearanceNamed:aSystemAppearanceName];
            aSystemAppearanceName = [systemAppearance bestMatchFromAppearancesWithNames:Map.allKeys];

            if (aSystemAppearanceName)
                appearance = Map[aSystemAppearanceName];
        }
    }

    if (appearance)
        return appearance.unsignedIntegerValue;
    else
        return SRRecorderControlStyleComponentsAppearanceUnspecified;
}


SRRecorderControlStyleComponentsTint SRRecorderControlStyleComponentsTintFromSystem(NSControlTint aSystemTint)
{
    switch (aSystemTint)
    {
        case NSBlueControlTint:
            return SRRecorderControlStyleComponentsTintBlue;
        case NSGraphiteControlTint:
            return SRRecorderControlStyleComponentsTintGraphite;
        default:
            return SRRecorderControlStyleComponentsTintUnspecified;
    }
}


SRRecorderControlStyleComponentsLayoutDirection SRRecorderControlStyleComponentsLayoutDirectionFromSystem(NSUserInterfaceLayoutDirection aSystemLayoutDirection)
{
    switch (aSystemLayoutDirection)
    {
        case NSUserInterfaceLayoutDirectionLeftToRight:
            return SRRecorderControlStyleComponentsLayoutDirectionLeftToRight;
        case NSUserInterfaceLayoutDirectionRightToLeft:
            return SRRecorderControlStyleComponentsLayoutDirectionRightToLeft;
        default:
            return SRRecorderControlStyleComponentsLayoutDirectionUnspecified;
    }
}


@implementation SRRecorderControlStyleComponents

+ (SRRecorderControlStyleComponents *)currentComponents
{
    return [self currentComponentsForView:nil];
}

+ (SRRecorderControlStyleComponents *)currentComponentsForView:(NSView *)aView
{
    NSAppearanceName effectiveSystemAppearance = nil;

    if (aView)
        effectiveSystemAppearance = aView.effectiveAppearance.name;
    else
        effectiveSystemAppearance = NSAppearance.currentAppearance.name;

    __auto_type appearance = SRRecorderControlStyleComponentsAppearanceFromSystem(effectiveSystemAppearance);
    __auto_type tint = SRRecorderControlStyleComponentsTintFromSystem(NSColor.currentControlTint);
    __auto_type accessibility = SRRecorderControlStyleComponentsAccessibilityUnspecified;

    if (NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast)
        accessibility = SRRecorderControlStyleComponentsAccessibilityHighContrast;
    else
        accessibility = SRRecorderControlStyleComponentsAccessibilityNone;

    __auto_type layoutDirection = SRRecorderControlStyleComponentsLayoutDirectionUnspecified;

    if (aView)
        layoutDirection = SRRecorderControlStyleComponentsLayoutDirectionFromSystem(aView.userInterfaceLayoutDirection);
    else
        layoutDirection = SRRecorderControlStyleComponentsLayoutDirectionFromSystem(NSApp.userInterfaceLayoutDirection);

    return [[SRRecorderControlStyleComponents alloc] initWithAppearance:appearance
                                                                   tint:tint
                                                          accessibility:accessibility
                                                        layoutDirection:layoutDirection];
}

- (instancetype)initWithAppearance:(SRRecorderControlStyleComponentsAppearance)anAppearance
                              tint:(SRRecorderControlStyleComponentsTint)aTint
                     accessibility:(SRRecorderControlStyleComponentsAccessibility)anAccessibility
                   layoutDirection:(SRRecorderControlStyleComponentsLayoutDirection)aDirection
{
    NSAssert(anAppearance >= SRRecorderControlStyleComponentsAppearanceUnspecified && anAppearance < SRRecorderControlStyleComponentsAppearanceMax,
             @"anAppearance is outside of the allowed range.");
    NSAssert(aTint >= SRRecorderControlStyleComponentsTintUnspecified && aTint < SRRecorderControlStyleComponentsTintMax,
             @"aTint is outside of the allowed range.");
    NSAssert((anAccessibility & ~SRRecorderControlStyleComponentsAccessibilityMask) == 0,
             @"anAccessibility is outside of the allowed range.");
    NSAssert(aDirection >= SRRecorderControlStyleComponentsLayoutDirectionUnspecified && aTint < SRRecorderControlStyleComponentsLayoutDirectionMax,
             @"aDirection is outside of the allowed range.");

    self = [super init];

    if (self)
    {
        _appearance = anAppearance;
        _tint = aTint;
        _accessibility = anAccessibility;
        _layoutDirection = aDirection;
    }

    return self;
}

- (instancetype)init
{
    return [self initWithAppearance:SRRecorderControlStyleComponentsAppearanceUnspecified
                               tint:SRRecorderControlStyleComponentsTintUnspecified
                      accessibility:SRRecorderControlStyleComponentsAccessibilityUnspecified
                    layoutDirection:SRRecorderControlStyleComponentsLayoutDirectionUnspecified];
}

- (NSString *)stringRepresentation
{
    NSString *appearance = nil;
    NSString *tint = nil;
    NSString *acc = nil;
    NSString *direction = nil;

    switch (self.appearance)
    {
        case SRRecorderControlStyleComponentsAppearanceDarkAqua:
            appearance = @"-darkaqua";
            break;
        case SRRecorderControlStyleComponentsAppearanceAqua:
            appearance = @"-aqua";
            break;
        case SRRecorderControlStyleComponentsAppearanceVibrantDark:
            appearance = @"-vibrantdark";
            break;
        case SRRecorderControlStyleComponentsAppearanceVibrantLight:
            appearance = @"-vibrantlight";
            break;
        case SRRecorderControlStyleComponentsAppearanceUnspecified:
            appearance = @"";
            break;
    }

    switch (self.tint)
    {
        case SRRecorderControlStyleComponentsTintBlue:
            tint = @"-blue";
            break;
        case SRRecorderControlStyleComponentsTintGraphite:
            tint = @"-graphite";
            break;
        case SRRecorderControlStyleComponentsTintUnspecified:
            tint = @"";
            break;
    }

    switch (self.accessibility)
    {
        case SRRecorderControlStyleComponentsAccessibilityHighContrast:
            acc = @"-acc";
            break;
        default:
            acc = @"";
            break;
    }

    switch (self.layoutDirection)
    {
        case SRRecorderControlStyleComponentsLayoutDirectionLeftToRight:
            direction = @"-ltr";
            break;
        case SRRecorderControlStyleComponentsLayoutDirectionRightToLeft:
            direction = @"-rtl";
            break;
        case SRRecorderControlStyleComponentsLayoutDirectionUnspecified:
            direction = @"";
            break;
    }

    return [NSString stringWithFormat:@"%@%@%@%@", appearance, tint, acc, direction];
}

- (BOOL)isEqualToComponents:(SRRecorderControlStyleComponents *)anObject
{
    if (anObject == self)
        return YES;
    else if (![anObject isKindOfClass:SRRecorderControlStyleComponents.class])
        return NO;
    else
        return self.appearance == anObject.appearance &&
            self.accessibility == anObject.accessibility &&
            self.layoutDirection == anObject.layoutDirection &&
            self.tint == anObject.tint;
}

- (NSComparisonResult)compare:(SRRecorderControlStyleComponents *)anOtherComponents
         relativeToComponents:(SRRecorderControlStyleComponents *)anIdealComponents
{
    static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *AppearanceOrderMap = nil;
    static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *TintOrderMap = nil;
    static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *DirectionOrderMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AppearanceOrderMap = @{
            @(SRRecorderControlStyleComponentsAppearanceAqua): @[@(SRRecorderControlStyleComponentsAppearanceAqua),
                                                       @(SRRecorderControlStyleComponentsAppearanceVibrantLight),
                                                       @(SRRecorderControlStyleComponentsAppearanceDarkAqua),
                                                       @(SRRecorderControlStyleComponentsAppearanceVibrantDark),
                                                       @(SRRecorderControlStyleComponentsAppearanceUnspecified)],
            @(SRRecorderControlStyleComponentsAppearanceDarkAqua): @[@(SRRecorderControlStyleComponentsAppearanceDarkAqua),
                                                           @(SRRecorderControlStyleComponentsAppearanceVibrantDark),
                                                           @(SRRecorderControlStyleComponentsAppearanceAqua),
                                                           @(SRRecorderControlStyleComponentsAppearanceVibrantLight),
                                                           @(SRRecorderControlStyleComponentsAppearanceUnspecified)],
            @(SRRecorderControlStyleComponentsAppearanceVibrantLight): @[@(SRRecorderControlStyleComponentsAppearanceVibrantLight),
                                                               @(SRRecorderControlStyleComponentsAppearanceAqua),
                                                               @(SRRecorderControlStyleComponentsAppearanceVibrantDark),
                                                               @(SRRecorderControlStyleComponentsAppearanceDarkAqua),
                                                               @(SRRecorderControlStyleComponentsAppearanceUnspecified)],
            @(SRRecorderControlStyleComponentsAppearanceVibrantDark): @[@(SRRecorderControlStyleComponentsAppearanceVibrantDark),
                                                              @(SRRecorderControlStyleComponentsAppearanceDarkAqua),
                                                              @(SRRecorderControlStyleComponentsAppearanceVibrantLight),
                                                              @(SRRecorderControlStyleComponentsAppearanceAqua),
                                                              @(SRRecorderControlStyleComponentsAppearanceUnspecified)]
        };

        TintOrderMap = @{
            @(SRRecorderControlStyleComponentsTintBlue): @[@(SRRecorderControlStyleComponentsTintBlue),
                                                 @(SRRecorderControlStyleComponentsTintGraphite),
                                                 @(SRRecorderControlStyleComponentsTintUnspecified)],
            @(SRRecorderControlStyleComponentsTintGraphite): @[@(SRRecorderControlStyleComponentsTintGraphite),
                                                     @(SRRecorderControlStyleComponentsTintBlue),
                                                     @(SRRecorderControlStyleComponentsTintUnspecified)]
        };

        DirectionOrderMap = @{
            @(SRRecorderControlStyleComponentsLayoutDirectionLeftToRight): @[@(SRRecorderControlStyleComponentsLayoutDirectionLeftToRight),
                                                                             @(SRRecorderControlStyleComponentsLayoutDirectionRightToLeft)],
            @(SRRecorderControlStyleComponentsLayoutDirectionRightToLeft): @[@(SRRecorderControlStyleComponentsLayoutDirectionRightToLeft),
                                                                             @(SRRecorderControlStyleComponentsLayoutDirectionLeftToRight)]
        };
    });

    __auto_type CompareEnum = ^(NSUInteger a, NSUInteger b, NSArray<NSNumber *> *order) {
        NSUInteger aIndex = [order indexOfObject:@(a)];
        NSUInteger bIndex = [order indexOfObject:@(b)];

        if (aIndex < bIndex)
            return NSOrderedAscending;
        else if (aIndex > bIndex)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    };

    __auto_type CompareOptions = ^(NSUInteger a, NSUInteger b, NSUInteger ideal) {
        // How many bits match.
        int aSimilarity = __builtin_popcountl(a & ideal);
        int bSimilarity = __builtin_popcountl(b & ideal);

        // How many bits mismatch.
        int aDissimilarity = __builtin_popcountl(a & ~ideal);
        int bDissimilarity = __builtin_popcountl(b & ~ideal);

        if (aSimilarity > bSimilarity)
            return NSOrderedAscending;
        else if (aSimilarity < bSimilarity)
            return NSOrderedDescending;
        else if (aDissimilarity < bDissimilarity)
            return NSOrderedAscending;
        else if (aDissimilarity > bDissimilarity)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    };

    if (self.appearance != anOtherComponents.appearance)
        return CompareEnum(self.appearance,
                           anOtherComponents.appearance,
                           AppearanceOrderMap[@(anIdealComponents.appearance)]);
    else if (self.accessibility != anOtherComponents.accessibility)
        return CompareOptions(self.accessibility,
                              anOtherComponents.accessibility,
                              anIdealComponents.accessibility);
    else if (self.layoutDirection != anOtherComponents.layoutDirection)
        return CompareEnum(self.layoutDirection,
                           anOtherComponents.layoutDirection,
                           AppearanceOrderMap[@(anIdealComponents.layoutDirection)]);
    else if (self.tint != anOtherComponents.tint)
        return CompareEnum(self.tint,
                           anOtherComponents.tint,
                           AppearanceOrderMap[@(anIdealComponents.tint)]);
    else
        return NSOrderedSame;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)aZone
{
    return self;
}

#pragma mark NSObject

- (BOOL)isEqual:(SRRecorderControlStyleComponents *)anObject
{
    return [self SR_isEqual:anObject usingSelector:@selector(isEqualToComponents:) ofCommonAncestor:SRRecorderControlStyleComponents.class];
}

- (NSUInteger)hash
{
    int tintOffset = sizeof(NSUInteger) * CHAR_BIT - __builtin_clzl(SRRecorderControlStyleComponentsTintMax);
    int layoutDirectionOffset = sizeof(NSUInteger) * CHAR_BIT - __builtin_clzl(SRRecorderControlStyleComponentsLayoutDirectionMax);
    int appearanceOffset = sizeof(NSUInteger) * CHAR_BIT - __builtin_clzl(SRRecorderControlStyleComponentsAppearanceMax);
    return self.tint |
        (self.layoutDirection << tintOffset) |
        (self.appearance << (tintOffset + layoutDirectionOffset)) |
        (self.accessibility << (tintOffset + layoutDirectionOffset + appearanceOffset));
}

- (NSString *)description
{
    return [self stringRepresentation];
}

@end


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

- (instancetype)init
{
    return [self initWithIdentifier:nil components:nil];
}

- (instancetype)initWithIdentifier:(NSString *)anIdentifier components:(SRRecorderControlStyleComponents *)aComponents
{
    if (self = [super init])
    {
        if (anIdentifier)
            _identifier = anIdentifier.copy;
        else
        {
            if (@available(macOS 10.14, *))
                _identifier = @"sr-mojave";
            else
                _identifier = @"sr-yosemite";
        }

        _components = aComponents.copy;

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
        _intrinsicContentSize = NSMakeSize(NSViewNoIntrinsicMetric, NSViewNoIntrinsicMetric);
    }

    return self;
}

#pragma mark Properties

- (SRRecorderControlStyleComponents *)effectiveComponents
{
    // Intentional access via instance variable: subclasses should
    // override effectiveComponents for purely computed values.
    SRRecorderControlStyleComponents *current = nil;

    if (!_components.appearance || !_components.tint || _components.accessibility || !_components.layoutDirection)
        current = [SRRecorderControlStyleComponents currentComponentsForView:self.recorderControl];

    __auto_type appearance = _components.appearance;
    if (!appearance)
        appearance = current.appearance ? current.appearance : SRRecorderControlStyleComponentsAppearanceAqua;

    __auto_type tint = _components.tint;
    if (!tint)
        tint = current.tint ? current.tint : SRRecorderControlStyleComponentsTintBlue;

    __auto_type accessibility = _components.accessibility;
    if (!accessibility)
        accessibility = current.accessibility;

    __auto_type layoutDirection = _components.layoutDirection;
    if (!layoutDirection)
        layoutDirection = current.layoutDirection ? current.layoutDirection : NSUserInterfaceLayoutDirectionLeftToRight;

    return [[SRRecorderControlStyleComponents alloc] initWithAppearance:appearance
                                                                   tint:tint
                                                          accessibility:accessibility
                                                        layoutDirection:layoutDirection];
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

    NSAssert(data != nil, @"Missing metrics!");

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

    SRRecorderControlStyleComponents *components = self.effectiveComponents;
    // TODO: cache for effective components.
    NSComparator cmp = ^NSComparisonResult(SRRecorderControlStyleComponents *a, SRRecorderControlStyleComponents *b) {
        return [a compare:b relativeToComponents:components];
    };
    NSArray *allComponents = [SRRecorderControlStyleComponents.allComponents sortedArrayWithOptions:NSSortStable usingComparator:cmp];
    NSMutableArray<NSString *> *lookupPrefixes = [NSMutableArray arrayWithCapacity:allComponents.count];
    for (SRRecorderControlStyleComponents *c in allComponents)
        [lookupPrefixes addObject:[NSString stringWithFormat:@"%@%@", self.identifier, c.stringRepresentation]];
    return lookupPrefixes.copy;
}

- (void)addConstraints
{
    [self.recorderControl addLayoutGuide:self.alignmentGuide];
    [self.recorderControl addLayoutGuide:self.backgroundDrawingGuide];
    [self.recorderControl addLayoutGuide:self.labelDrawingGuide];
    [self.recorderControl addLayoutGuide:self.cancelButtonDrawingGuide];
    [self.recorderControl addLayoutGuide:self.clearButtonDrawingGuide];
    [self.recorderControl addLayoutGuide:self.cancelButtonLayoutGuide];
    [self.recorderControl addLayoutGuide:self.clearButtonLayoutGuide];

    __auto_type SetConstraint = ^(NSLayoutConstraint * __strong *var, NSLayoutConstraint *value) {
        *var = value;
        return value;
    };

    __auto_type MakeConstraint = ^(NSLayoutAnchor * _Nonnull firstItem,
                                   NSLayoutAnchor * _Nullable secondItem,
                                   CGFloat constant,
                                   NSLayoutPriority priority,
                                   NSLayoutRelation relation)
    {
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
            NSAssert([firstItem isKindOfClass:NSLayoutDimension.class],
                     @"Only dimensional anchors allow constant constraints.");

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
        MakeEqConstraint(self.alignmentGuide.topAnchor, self.recorderControl.topAnchor),
        MakeEqConstraint(self.alignmentGuide.leftAnchor, self.recorderControl.leftAnchor),
        MakeEqConstraint(self.alignmentGuide.rightAnchor, self.recorderControl.rightAnchor),
        MakeConstraint(self.alignmentGuide.bottomAnchor, self.recorderControl.bottomAnchor, 0.0, NSLayoutPriorityDefaultHigh, NSLayoutRelationEqual),
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

    self.recorderControl.needsUpdateConstraints = YES;
}

#pragma mark SRRecorderControlStyling
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
@synthesize intrinsicContentSize = _intrinsicContentSize;
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

- (void)prepareForRecorderControl:(SRRecorderControl *)aControl
{
    NSAssert(_recorderControl == nil, @"Style was not removed properly.");

    [self willChangeValueForKey:@"recorderControl"];
    _recorderControl = aControl;
    [self didChangeValueForKey:@"recorderControl"];

    _recorderControl = aControl;
    _lookupPrefixes = nil;
    _metrics = nil;

    if (!_recorderControl)
        return;

    [self addConstraints];
    [self recorderControlAppearanceDidChange:nil];

    _recorderControl.needsDisplay = YES;
}

- (void)prepareForRemoval
{
    NSAssert(_recorderControl != nil, @"Style was not applied properly.");

    [_recorderControl removeLayoutGuide:_alignmentGuide];
    [_recorderControl removeLayoutGuide:_backgroundDrawingGuide];
    [_recorderControl removeLayoutGuide:_labelDrawingGuide];
    [_recorderControl removeLayoutGuide:_cancelButtonDrawingGuide];
    [_recorderControl removeLayoutGuide:_clearButtonDrawingGuide];
    [_recorderControl removeLayoutGuide:_cancelButtonLayoutGuide];
    [_recorderControl removeLayoutGuide:_clearButtonLayoutGuide];

    [self willChangeValueForKey:@"recorderControl"];
    _recorderControl = nil;
    [self didChangeValueForKey:@"recorderControl"];
}

- (void)recorderControlAppearanceDidChange:(nullable id)aReason
{
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
            [self.recorderControl setNeedsDisplayInRect:frame];
    };

    NSRect controlBounds = self.recorderControl.bounds;

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

    NSSize newShapeCornerRadius = NSMakeSize([_metrics[@"FocusRingCornerRadius"][@"Width"] floatValue],
                                             [_metrics[@"FocusRingRadius"][@"Height"] floatValue]);
    if (!NSEqualSizes(newShapeCornerRadius, self.shapeCornerRadius))
    {
        [self setValue:[NSValue valueWithSize:newShapeCornerRadius] forKey:@"shapeCornerRadius"];
        [self.recorderControl noteFocusRingMaskChanged];
    }

    NSEdgeInsets newShapeInsets = NSEdgeInsetsMake([_metrics[@"FocusRingInsets"][@"Top"] floatValue],
                                                   [_metrics[@"FocusRingInsets"][@"Left"] floatValue],
                                                   [_metrics[@"FocusRingInsets"][@"Bottom"] floatValue],
                                                   [_metrics[@"FocusRingInsets"][@"Right"] floatValue]);
    if (!NSEdgeInsetsEqual(newShapeInsets, self.shapeInsets))
    {
        [self setValue:[NSValue valueWithEdgeInsets:newShapeInsets] forKey:@"shapeInsets"];
        [self.recorderControl noteFocusRingMaskChanged];
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
            NSParagraphStyleAttributeName: p.copy,
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
    CGFloat maxExpectedLabelWidth = ceilf([SRLoc(@"Click to record shortcut") sizeWithAttributes:self.normalLabelAttributes].width);
    CGFloat maxExpectedTrailingLabelOffset = MAX(_alignmentToLabelConstraint.constant, _labelToCancelConstraint.constant + _cancelButtonWidthConstraint.constant + _cancelToClearConstraint.constant + _clearButtonWidthConstraint.constant + _clearToAlignmentConstraint.constant);
    _alignmentSuggestedWidthConstraint.constant = maxExpectedLeadingLabelOffset + maxExpectedLabelWidth + maxExpectedTrailingLabelOffset;

    NSSize newIntrinsicContentSize = NSMakeSize(_alignmentSuggestedWidthConstraint.constant + self.alignmentRectInsets.left + self.alignmentRectInsets.right, [_metrics[@"MinSize"][@"Height"] floatValue]);
    if (!NSEqualSizes(newIntrinsicContentSize, self.intrinsicContentSize))
    {
        [self setValue:[NSValue valueWithSize:newIntrinsicContentSize] forKey:@"intrinsicContentSize"];
        [self.recorderControl invalidateIntrinsicContentSize];
    }
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)aZone
{
    return [[self.class alloc] initWithIdentifier:self.identifier components:self.components];
}

@end
