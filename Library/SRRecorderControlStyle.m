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


@implementation SRRecorderControlStyleLookupOption

+ (NSSet<NSNumber *> *)supportedAppearences
{
    static NSSet<NSNumber *> *S = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        S = [NSSet setWithObjects:
             @(SRRecorderControlStyleLookupOptionAppearanceNone),
             @(SRRecorderControlStyleLookupOptionAppearanceAqua),
             @(SRRecorderControlStyleLookupOptionAppearanceDarkAqua),
             @(SRRecorderControlStyleLookupOptionAppearanceVibrantLight),
             @(SRRecorderControlStyleLookupOptionAppearanceVibrantDark),
             nil];
    });
    return S;
}

+ (NSSet<NSNumber *> *)supportedTints
{
    static NSSet<NSNumber *> *S = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        S = [NSSet setWithObjects:
             @(SRRecorderControlStyleLookupOptionTintNone),
             @(SRRecorderControlStyleLookupOptionTintBlue),
             @(SRRecorderControlStyleLookupOptionTintGraphite),
             nil];
    });
    return S;
}

+ (NSSet<NSNumber *> *)supportedAccessibilities
{
    static NSSet<NSNumber *> *S = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        S = [NSSet setWithObjects:
             @(SRRecorderControlStyleLookupOptionAccessibilityNone),
             @(SRRecorderControlStyleLookupOptionAccessibilityHighContrast),
             nil];
    });
    return S;
}

+ (NSSet<NSAppearanceName> *)supportedSystemAppearences
{
    static NSSet<NSAppearanceName> *S = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        S = [NSMutableSet setWithObjects:
             NSAppearanceNameAqua,
             NSAppearanceNameVibrantLight,
             NSAppearanceNameVibrantDark,
             nil];

        if (@available(macOS 10.14, *))
            [(NSMutableSet *)S addObject:NSAppearanceNameDarkAqua];

        S = S.copy;
    });
    return S;
}

+ (NSArray<SRRecorderControlStyleLookupOption *> *)allOptions
{
    static NSArray<SRRecorderControlStyleLookupOption *> *A = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        A = NSMutableArray.array;

        for (NSNumber *appearance in self.supportedAppearences)
        {
            for (NSNumber *tint in self.supportedTints)
            {
                for (NSNumber *acc in self.supportedAccessibilities)
                {
                    SRRecorderControlStyleLookupOption *o = [[SRRecorderControlStyleLookupOption alloc] initWithAppearance:appearance.unsignedIntegerValue
                                                                                                                      tint:tint.unsignedIntegerValue
                                                                                                             accessibility:acc.unsignedIntegerValue];
                    [(NSMutableArray *)A addObject:o];
                }
            }
        }

        A = A.copy;
    });
    return A;
}

+ (SRRecorderControlStyleLookupOptionAppearance)appearanceForSystemAppearanceName:(NSAppearanceName)aSystemAppearance
{
    static NSDictionary<NSAppearanceName, NSNumber *> *Map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Map = @{
            NSAppearanceNameAqua: @(SRRecorderControlStyleLookupOptionAppearanceAqua),
            NSAppearanceNameVibrantLight: @(SRRecorderControlStyleLookupOptionAppearanceVibrantLight),
            NSAppearanceNameVibrantDark: @(SRRecorderControlStyleLookupOptionAppearanceVibrantDark)
        }.mutableCopy;

        if (@available(macOS 10.14, *))
            [(NSMutableDictionary *)Map setObject:@(SRRecorderControlStyleLookupOptionAppearanceDarkAqua) forKey:NSAppearanceNameDarkAqua];

        NSAssert([[NSSet setWithArray:Map.allKeys] isEqualToSet:self.supportedSystemAppearences], @"Map is missing keys.");
    });
    return Map[aSystemAppearance].unsignedIntegerValue;
}

+ (SRRecorderControlStyleLookupOptionTint)tintForSystemTint:(NSControlTint)aSystemTint
{
    static NSDictionary<NSNumber *, NSNumber *> *Map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Map = @{
            @(NSBlueControlTint): @(SRRecorderControlStyleLookupOptionTintBlue),
            @(NSGraphiteControlTint): @(SRRecorderControlStyleLookupOptionTintGraphite),
        };
    });
    return Map[@(aSystemTint)].unsignedIntegerValue;
}

- (instancetype)initWithAppearance:(SRRecorderControlStyleLookupOptionAppearance)anAppearance
                              tint:(SRRecorderControlStyleLookupOptionTint)aTint
                     accessibility:(SRRecorderControlStyleLookupOptionAccessibility)anAccessibility
{
    NSAssert(anAppearance >= SRRecorderControlStyleLookupOptionAppearanceNone && anAppearance < SRRecorderControlStyleLookupOptionAppearanceMax,
             @"anAppearance is outside of allowed range.");
    NSAssert(aTint >= SRRecorderControlStyleLookupOptionTintNone && aTint < SRRecorderControlStyleLookupOptionTintMax,
             @"aTint is outside of allowed range.");
    NSAssert((anAccessibility & ~SRRecorderControlStyleLookupOptionAccessibilityMask) == 0,
             @"anAccessibility is outside of allowed range.");

    self = [super init];

    if (self)
    {
        _appearance = anAppearance;
        _tint = aTint;
        _accessibility = anAccessibility;
    }

    return self;
}

- (instancetype)init
{
    return [self initWithAppearance:SRRecorderControlStyleLookupOptionAppearanceNone
                               tint:SRRecorderControlStyleLookupOptionTintBlue
                      accessibility:SRRecorderControlStyleLookupOptionAccessibilityNone];
}

- (NSString *)stringRepresentation
{
    NSString *appearance = nil;
    NSString *tint = nil;
    NSString *acc = nil;

    switch (self.appearance)
    {
        case SRRecorderControlStyleLookupOptionAppearanceDarkAqua:
            appearance = @"-darkaqua";
            break;
        case SRRecorderControlStyleLookupOptionAppearanceAqua:
            appearance = @"-aqua";
            break;
        case SRRecorderControlStyleLookupOptionAppearanceVibrantDark:
            appearance = @"-vibrantdark";
            break;
        case SRRecorderControlStyleLookupOptionAppearanceVibrantLight:
            appearance = @"-vibrantlight";
            break;
        default:
            appearance = @"";
            break;
    }

    switch (self.tint)
    {
        case SRRecorderControlStyleLookupOptionTintBlue:
            tint = @"-blue";
            break;
        case SRRecorderControlStyleLookupOptionTintGraphite:
            tint = @"-graphite";
            break;
        default:
            tint = @"";
            break;
    }

    switch (self.accessibility)
    {
        case SRRecorderControlStyleLookupOptionAccessibilityHighContrast:
            acc = @"-acc";
            break;
        default:
            acc = @"";
            break;
    }

    return [NSString stringWithFormat:@"%@%@%@", appearance, tint, acc];
}

- (NSComparisonResult)compare:(SRRecorderControlStyleLookupOption *)anOption
             relativeToOption:(SRRecorderControlStyleLookupOption *)anEffectiveOption
{
    static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *AppearanceOrderMap = nil;
    static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *TintOrderMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AppearanceOrderMap = @{
            @(SRRecorderControlStyleLookupOptionAppearanceAqua): @[@(SRRecorderControlStyleLookupOptionAppearanceAqua),
                                                       @(SRRecorderControlStyleLookupOptionAppearanceVibrantLight),
                                                       @(SRRecorderControlStyleLookupOptionAppearanceDarkAqua),
                                                       @(SRRecorderControlStyleLookupOptionAppearanceVibrantDark),
                                                       @(SRRecorderControlStyleLookupOptionAppearanceNone)],
            @(SRRecorderControlStyleLookupOptionAppearanceDarkAqua): @[@(SRRecorderControlStyleLookupOptionAppearanceDarkAqua),
                                                           @(SRRecorderControlStyleLookupOptionAppearanceVibrantDark),
                                                           @(SRRecorderControlStyleLookupOptionAppearanceAqua),
                                                           @(SRRecorderControlStyleLookupOptionAppearanceVibrantLight),
                                                           @(SRRecorderControlStyleLookupOptionAppearanceNone)],
            @(SRRecorderControlStyleLookupOptionAppearanceVibrantLight): @[@(SRRecorderControlStyleLookupOptionAppearanceVibrantLight),
                                                               @(SRRecorderControlStyleLookupOptionAppearanceAqua),
                                                               @(SRRecorderControlStyleLookupOptionAppearanceVibrantDark),
                                                               @(SRRecorderControlStyleLookupOptionAppearanceDarkAqua),
                                                               @(SRRecorderControlStyleLookupOptionAppearanceNone)],
            @(SRRecorderControlStyleLookupOptionAppearanceVibrantDark): @[@(SRRecorderControlStyleLookupOptionAppearanceVibrantDark),
                                                              @(SRRecorderControlStyleLookupOptionAppearanceDarkAqua),
                                                              @(SRRecorderControlStyleLookupOptionAppearanceVibrantLight),
                                                              @(SRRecorderControlStyleLookupOptionAppearanceAqua),
                                                              @(SRRecorderControlStyleLookupOptionAppearanceNone)]
        };

        TintOrderMap = @{
            @(SRRecorderControlStyleLookupOptionTintBlue): @[@(SRRecorderControlStyleLookupOptionTintBlue),
                                                 @(SRRecorderControlStyleLookupOptionTintGraphite),
                                                 @(SRRecorderControlStyleLookupOptionTintNone)],
            @(SRRecorderControlStyleLookupOptionTintGraphite): @[@(SRRecorderControlStyleLookupOptionTintGraphite),
                                                     @(SRRecorderControlStyleLookupOptionTintBlue),
                                                     @(SRRecorderControlStyleLookupOptionTintNone)]
        };
    });

    __auto_type CompareAppearances = ^(SRRecorderControlStyleLookupOptionAppearance a, SRRecorderControlStyleLookupOptionAppearance b) {
        NSArray<NSNumber *> *order = AppearanceOrderMap[@(anEffectiveOption.appearance)];

        NSUInteger aIndex = [order indexOfObject:@(a)];
        NSUInteger bIndex = [order indexOfObject:@(b)];

        if (aIndex < bIndex)
            return NSOrderedAscending;
        else if (aIndex > bIndex)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    };

    __auto_type CompareTints = ^(SRRecorderControlStyleLookupOptionTint a, SRRecorderControlStyleLookupOptionTint b) {
        NSArray<NSNumber *> *order = TintOrderMap[@(anEffectiveOption.tint)];

        NSUInteger aIndex = [order indexOfObject:@(a)];
        NSUInteger bIndex = [order indexOfObject:@(b)];

        if (aIndex < bIndex)
            return NSOrderedAscending;
        else if (aIndex > bIndex)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    };

    __auto_type CompareAccessibilitites = ^(SRRecorderControlStyleLookupOptionAccessibility a, SRRecorderControlStyleLookupOptionAccessibility b) {
        // How many bits match.
        int aSimilarity = __builtin_popcountl(a & anEffectiveOption.accessibility);
        int bSimilarity = __builtin_popcountl(b & anEffectiveOption.accessibility);

        // How many bits mismatch.
        int aDissimilarity = __builtin_popcountl(a & ~anEffectiveOption.accessibility);
        int bDissimilarity = __builtin_popcountl(b & ~anEffectiveOption.accessibility);

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

    if (self.appearance != anOption.appearance)
        return CompareAppearances(self.appearance, anOption.appearance);
    else if (self.tint != anOption.tint)
        return CompareTints(self.tint, anOption.tint);
    else if (self.accessibility != anOption.accessibility)
        return CompareAccessibilitites(self.accessibility, anOption.accessibility);
    else
        return NSOrderedSame;
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
        _intrinsicContentSize = NSMakeSize(NSViewNoIntrinsicMetric, NSViewNoIntrinsicMetric);
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

    NSAppearanceName effectiveSystemAppearance = nil;

    if (@available(macOS 10.14, *))
        effectiveSystemAppearance = [self.recorderControl.effectiveAppearance bestMatchFromAppearancesWithNames:SRRecorderControlStyleLookupOption.supportedSystemAppearences.allObjects];

    if (!effectiveSystemAppearance)
        effectiveSystemAppearance = NSAppearance.currentAppearance.name;

    if (!effectiveSystemAppearance || ![SRRecorderControlStyleLookupOption.supportedSystemAppearences containsObject:effectiveSystemAppearance])
        effectiveSystemAppearance = NSAppearanceNameAqua;

    SRRecorderControlStyleLookupOptionAppearance effectiveAppearance = [SRRecorderControlStyleLookupOption appearanceForSystemAppearanceName:effectiveSystemAppearance];
    SRRecorderControlStyleLookupOptionTint effectiveTint = [SRRecorderControlStyleLookupOption tintForSystemTint:NSColor.currentControlTint];
    SRRecorderControlStyleLookupOptionAccessibility effectiveAccessibility = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast ? SRRecorderControlStyleLookupOptionAccessibilityHighContrast : SRRecorderControlStyleLookupOptionAccessibilityNone;
    SRRecorderControlStyleLookupOption *effectiveOption = [[SRRecorderControlStyleLookupOption alloc] initWithAppearance:effectiveAppearance
                                                                                                                    tint:effectiveTint
                                                                                                           accessibility:effectiveAccessibility];

    return [self makeLookupPrefixesRelativeToOption:effectiveOption];
}

- (NSArray<NSString *> *)makeLookupPrefixesRelativeToOption:(SRRecorderControlStyleLookupOption *)anOption
{
    NSComparator cmp = ^NSComparisonResult(SRRecorderControlStyleLookupOption *a, SRRecorderControlStyleLookupOption *b)
    {
        return [a compare:b relativeToOption:anOption];
    };
    NSArray *options = [SRRecorderControlStyleLookupOption.allOptions sortedArrayWithOptions:NSSortStable usingComparator:cmp];
    NSMutableArray<NSString *> *loadOrder = [NSMutableArray arrayWithCapacity:options.count];
    for (SRRecorderControlStyleLookupOption *o in options)
        [loadOrder addObject:[NSString stringWithFormat:@"%@%@", self.identifier, o.stringRepresentation]];
    return loadOrder.copy;
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
    if (aControl == _recorderControl)
        return;

    [_recorderControl removeLayoutGuide:_alignmentGuide];
    [_recorderControl removeLayoutGuide:_labelDrawingGuide];
    [_recorderControl removeLayoutGuide:_cancelButtonDrawingGuide];
    [_recorderControl removeLayoutGuide:_clearButtonDrawingGuide];
    [_recorderControl removeLayoutGuide:_cancelButtonLayoutGuide];
    [_recorderControl removeLayoutGuide:_clearButtonLayoutGuide];

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

    NSSize newShapeCornerRadius = NSMakeSize([_metrics[@"Shape"][@"CornerRadius"][@"Width"] floatValue],
                                             [_metrics[@"Shape"][@"CornerRadius"][@"Height"] floatValue]);
    if (!NSEqualSizes(newShapeCornerRadius, self.shapeCornerRadius))
    {
        [self setValue:[NSValue valueWithSize:newShapeCornerRadius] forKey:@"shapeCornerRadius"];
        [self.recorderControl noteFocusRingMaskChanged];
    }

    NSEdgeInsets newShapeInsets = NSEdgeInsetsMake([_metrics[@"Shape"][@"Insets"][@"Top"] floatValue],
                                                   [_metrics[@"Shape"][@"Insets"][@"Left"] floatValue],
                                                   [_metrics[@"Shape"][@"Insets"][@"Bottom"] floatValue],
                                                   [_metrics[@"Shape"][@"Insets"][@"Right"] floatValue]);
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
