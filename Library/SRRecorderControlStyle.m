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


NSAppearanceName SRRecorderControlStyleComponentsAppearanceToSystem(SRRecorderControlStyleComponentsAppearance anAppearance)
{
    switch (anAppearance)
    {
        case SRRecorderControlStyleComponentsAppearanceAqua:
            return NSAppearanceNameAqua;
        case SRRecorderControlStyleComponentsAppearanceVibrantLight:
            return NSAppearanceNameVibrantLight;
        case SRRecorderControlStyleComponentsAppearanceVibrantDark:
            return NSAppearanceNameVibrantDark;
        case SRRecorderControlStyleComponentsAppearanceDarkAqua:
        {
            if (@available(macOS 10.14, *))
                return NSAppearanceNameDarkAqua;
        }
        case SRRecorderControlStyleComponentsAppearanceUnspecified:
        default:
            [NSException raise:NSInvalidArgumentException format:@"%lu cannot be represented as NSAppearanceName", anAppearance];
            __builtin_unreachable();
    }
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


NSControlTint SRRecorderControlStyleComponentsTintToSystem(SRRecorderControlStyleComponentsTint aTint)
{
    switch (aTint) {
        case SRRecorderControlStyleComponentsTintBlue:
            return NSBlueControlTint;
            break;
        case SRRecorderControlStyleComponentsTintGraphite:
            return NSGraphiteControlTint;
        case SRRecorderControlStyleComponentsTintUnspecified:
        default:
            [NSException raise:NSInvalidArgumentException format:@"%lu cannot be represented as NSControlTint", aTint];
            __builtin_unreachable();
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


NSUserInterfaceLayoutDirection SRRecorderControlStyleComponentsLayoutDirectionToSystem(SRRecorderControlStyleComponentsLayoutDirection aLayoutDirection)
{
    switch (aLayoutDirection)
    {
        case SRRecorderControlStyleComponentsLayoutDirectionLeftToRight:
            return NSUserInterfaceLayoutDirectionLeftToRight;
        case SRRecorderControlStyleComponentsLayoutDirectionRightToLeft:
            return NSUserInterfaceLayoutDirectionRightToLeft;
        case SRRecorderControlStyleComponentsLayoutDirectionUnspecified:
        default:
            [NSException raise:NSInvalidArgumentException format:@"%lu cannot be represented as NSUserInterfaceLayoutDirection", aLayoutDirection];
            __builtin_unreachable();
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
                                                          accessibility:accessibility
                                                        layoutDirection:layoutDirection
                                                                   tint:tint];
}

- (instancetype)initWithAppearance:(SRRecorderControlStyleComponentsAppearance)anAppearance
                     accessibility:(SRRecorderControlStyleComponentsAccessibility)anAccessibility
                   layoutDirection:(SRRecorderControlStyleComponentsLayoutDirection)aDirection
                              tint:(SRRecorderControlStyleComponentsTint)aTint
{
    NSAssert(anAppearance >= SRRecorderControlStyleComponentsAppearanceUnspecified && anAppearance < SRRecorderControlStyleComponentsAppearanceMax,
             @"anAppearance is outside of the allowed range.");
    NSAssert(aTint >= SRRecorderControlStyleComponentsTintUnspecified && aTint < SRRecorderControlStyleComponentsTintMax,
             @"aTint is outside of the allowed range.");
    NSAssert((anAccessibility & ~SRRecorderControlStyleComponentsAccessibilityMask) == 0,
             @"anAccessibility is outside of the allowed range.");
    NSAssert(anAccessibility == SRRecorderControlStyleComponentsAccessibilityNone ||
             (anAccessibility & SRRecorderControlStyleComponentsAccessibilityNone) == 0, @"None cannot be combined with other accessibility options.");
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
                      accessibility:SRRecorderControlStyleComponentsAccessibilityUnspecified
                    layoutDirection:SRRecorderControlStyleComponentsLayoutDirectionUnspecified
                               tint:SRRecorderControlStyleComponentsTintUnspecified];
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

        default:
            NSAssert(NO, @"Unexpected appearance.");
            break;
    }

    switch (self.accessibility)
    {
        case SRRecorderControlStyleComponentsAccessibilityHighContrast:
            acc = @"-acc";
            break;
        case SRRecorderControlStyleComponentsAccessibilityNone:
        case SRRecorderControlStyleComponentsAccessibilityUnspecified:
            acc = @"";
            break;

        default:
            NSAssert(NO, @"Unexpected appearance.");
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

        default:
            NSAssert(NO, @"Unexpected appearance.");
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

        default:
            NSAssert(NO, @"Unexpected appearance.");
            break;
    }

    return [NSString stringWithFormat:@"%@%@%@%@", appearance, acc, direction, tint];
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
    return [self SR_isEqual:anObject
              usingSelector:@selector(isEqualToComponents:)
           ofCommonAncestor:SRRecorderControlStyleComponents.class];
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


@interface SRRecorderControlStyleResourceLoaderCacheLookupPrefixesKey: NSObject
@property NSString *identifier;
@property SRRecorderControlStyleComponents *components;
@end


@implementation SRRecorderControlStyleResourceLoaderCacheLookupPrefixesKey

- (NSUInteger)hash
{
    return (self.components.hash << 32) ^ self.identifier.hash;
}

- (BOOL)isEqual:(SRRecorderControlStyleResourceLoaderCacheLookupPrefixesKey *)anObject
{
    if (![anObject isKindOfClass:self.class])
        return NO;

    return [self.identifier isEqual:anObject.identifier] && [self.components isEqual:anObject.components];
}

@end


@interface SRRecorderControlStyleResourceLoaderCacheImageKey: NSObject
@property NSString *identifier;
@property SRRecorderControlStyleComponents *components;
@property NSString *name;
@end


@implementation SRRecorderControlStyleResourceLoaderCacheImageKey

- (NSUInteger)hash
{
    return (self.components.hash << 32) ^ (self.name.hash << 32) ^ self.components.hash;
}

- (BOOL)isEqual:(SRRecorderControlStyleResourceLoaderCacheImageKey *)anObject
{
    if (![anObject isKindOfClass:self.class])
        return NO;

    return [self.identifier isEqual:anObject.identifier] &&
        [self.components isEqual:anObject.components] &&
        [self.name isEqual:anObject];
}

@end


@implementation SRRecorderControlStyleResourceLoader
{
    NSCache *_cache;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _cache = [NSCache new];
        _cache.name = @"SRRecorderControlStyleResourceLoader";
    }

    return self;
}

- (NSDictionary<NSString *, NSObject *> *)infoForStyle:(SRRecorderControlStyle *)aStyle
{
    typedef id (^Transformer)(id anObject, NSString *aKey);
    typedef void (^Verifier)(id anObject, NSString *aKey);

    __auto_type VerifyIsType = ^(NSObject *anObject, NSString *aKey, Class aType) {
        if (![anObject isKindOfClass:aType])
            [NSException raise:NSInternalInconsistencyException
                        format:@"%@: expected %@ but got %@", aKey, NSStringFromClass(aType), NSStringFromClass(anObject.class)];
    };

    __auto_type VerifyNumberInInterval = ^(NSNumber *anObject, NSString *aKey, NSNumber *aMin, NSNumber *aMax) {
        VerifyIsType(anObject, aKey, NSNumber.class);

        if ([anObject compare:aMax] != NSOrderedAscending)
            [NSException raise:NSInternalInconsistencyException format:@"%@: value >= %@", aKey, aMax];

        if ([anObject compare:aMin] == NSOrderedAscending)
            [NSException raise:NSInternalInconsistencyException format:@"%@: value < %@", aKey, aMin];
    };

    __auto_type VerifyNumberWithMask = ^(NSNumber *anObject, NSString *aKey, NSUInteger aMask) {
        if (!anObject)
            return;

        VerifyIsType(anObject, aKey, NSNumber.class);

        if ((anObject.unsignedIntegerValue & ~aMask) != 0)
            [NSException raise:NSInternalInconsistencyException format:@"%@: value must be with mask %lu", aKey, aMask];
    };

    __auto_type VerifyDictionaryHasKey = ^(NSDictionary *anObject, NSString *aKey, NSString *aSubKey) {
        if (!anObject[aSubKey])
            [NSException raise:NSInternalInconsistencyException format:@"%@: missing %@", aKey, aSubKey];
    };

    Verifier VerifyIsArray = ^(NSArray *anObject, NSString *aKey) {
        VerifyIsType(anObject, aKey, NSArray.class);
    };

    Verifier VerifyIsDictionary = ^(NSDictionary *anObject, NSString *aKey) {
        VerifyIsType(anObject, aKey, NSDictionary.class);
    };

    Verifier VerifyIsNumber = ^(NSNumber *anObject, NSString *aKey) {
        VerifyIsType(anObject, aKey, NSNumber.class);
    };

    Verifier VerifyIsString = ^(NSString *anObject, NSString *aKey) {
        VerifyIsType(anObject, aKey, NSString.class);
    };

    Verifier VerifyIsComponents = ^(NSDictionary *anObject, NSString *aKey) {
        VerifyIsDictionary(anObject, aKey);

        if (anObject[@"appearance"])
            VerifyNumberInInterval(anObject[@"appearance"],
                                   [NSString stringWithFormat:@"%@.appearance", aKey],
                                   @(SRRecorderControlStyleComponentsAppearanceUnspecified),
                                   @(SRRecorderControlStyleComponentsAppearanceMax));

        if (anObject[@"accessibility"])
            VerifyNumberWithMask(anObject[@"accessibility"],
                                 [NSString stringWithFormat:@"%@.accessibility", aKey],
                                 SRRecorderControlStyleComponentsAccessibilityMask);

        if (anObject[@"layoutDirection"])
            VerifyNumberInInterval(anObject[@"layoutDirection"],
                                   [NSString stringWithFormat:@"%@.layoutDirection", aKey],
                                   @(SRRecorderControlStyleComponentsLayoutDirectionUnspecified),
                                   @(SRRecorderControlStyleComponentsLayoutDirectionMax));

        if (anObject[@"tint"])
            VerifyNumberInInterval(anObject[@"tint"],
                                   [NSString stringWithFormat:@"%@.tint", aKey],
                                   @(SRRecorderControlStyleComponentsTintUnspecified),
                                   @(SRRecorderControlStyleComponentsTintMax));
    };

    Verifier VerifyIsSize = ^(NSDictionary *anObject, NSString *aKey) {
        VerifyIsDictionary(anObject, aKey);

        if (anObject.count != 2)
            [NSException raise:NSInternalInconsistencyException format:@"%@: unexpected keys", aKey];

        VerifyDictionaryHasKey(anObject, aKey, @"width");
        VerifyIsNumber(anObject[@"width"], [NSString stringWithFormat:@"%@.width", aKey]);

        VerifyDictionaryHasKey(anObject, aKey, @"height");
        VerifyIsNumber(anObject[@"height"], [NSString stringWithFormat:@"%@.height", aKey]);
    };

    Verifier VerifyIsEdgeInsets = ^(NSDictionary *anObject, NSString *aKey) {
        VerifyIsDictionary(anObject, aKey);

        if (anObject.count != 4)
            [NSException raise:NSInternalInconsistencyException format:@"%@: unexpected keys", aKey];

        VerifyDictionaryHasKey(anObject, aKey, @"top");
        VerifyIsNumber(anObject[@"top"], [NSString stringWithFormat:@"%@.top", aKey]);

        VerifyDictionaryHasKey(anObject, aKey, @"left");
        VerifyIsNumber(anObject[@"left"], [NSString stringWithFormat:@"%@.left", aKey]);

        VerifyDictionaryHasKey(anObject, aKey, @"bottom");
        VerifyIsNumber(anObject[@"bottom"], [NSString stringWithFormat:@"%@.bottom", aKey]);

        VerifyDictionaryHasKey(anObject, aKey, @"right");
        VerifyIsNumber(anObject[@"right"], [NSString stringWithFormat:@"%@.right", aKey]);
    };

    Verifier VerifyIsLabelAttributes = ^(NSDictionary *anObject, NSString *aKey) {
        VerifyIsDictionary(anObject, aKey);

        if (anObject.count != 4)
            [NSException raise:NSInternalInconsistencyException format:@"%@: unexpected keys", aKey];

        VerifyDictionaryHasKey(anObject, aKey, @"fontName");
        VerifyIsString(anObject[@"fontName"], [NSString stringWithFormat:@"%@.fontName", aKey]);

        VerifyDictionaryHasKey(anObject, aKey, @"fontSize");
        VerifyIsNumber(anObject[@"fontSize"], [NSString stringWithFormat:@"%@.fontSize", aKey]);

        VerifyDictionaryHasKey(anObject, aKey, @"fontColorCatalogName");
        VerifyIsString(anObject[@"fontColorCatalogName"], [NSString stringWithFormat:@"%@.fontColorCatalogName", aKey]);

        VerifyDictionaryHasKey(anObject, aKey, @"fontColorName");
        VerifyIsString(anObject[@"fontColorName"], [NSString stringWithFormat:@"%@.fontColorName", aKey]);
    };

    Transformer TransformComponents = ^(NSDictionary<NSString *, NSNumber *> *anObject, NSString *aKey) {
        return [[SRRecorderControlStyleComponents alloc] initWithAppearance:anObject[@"appearance"].unsignedIntegerValue
                                                              accessibility:anObject[@"accessibility"].unsignedIntegerValue
                                                            layoutDirection:anObject[@"layoutDirection"].unsignedIntegerValue
                                                                       tint:anObject[@"tint"].unsignedIntegerValue];
    };

    Transformer TransformSize = ^(NSDictionary<NSString *, NSNumber *> *anObject, NSString *aKey) {
        return [NSValue valueWithSize:NSMakeSize(anObject[@"width"].doubleValue, anObject[@"height"].doubleValue)];
    };

    Transformer TransformEdgeInsets = ^(NSDictionary<NSString *, NSNumber *> *anObject, NSString *aKey) {
        return [NSValue valueWithEdgeInsets:NSEdgeInsetsMake(anObject[@"top"].doubleValue,
                                                             anObject[@"left"].doubleValue,
                                                             anObject[@"bottom"].doubleValue,
                                                             anObject[@"right"].doubleValue)];
    };

    Transformer TransformLabelAttributes = ^(NSDictionary<NSString *, id> *anObject, NSString *aKey) {
        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        p.alignment = NSTextAlignmentCenter;
        p.lineBreakMode = NSLineBreakByTruncatingMiddle;

        NSFont *font = [NSFont fontWithName:anObject[@"fontName"] size:[anObject[@"fontSize"] doubleValue]];
        NSColor *fontColor = [NSColor colorWithCatalogName:anObject[@"fontColorCatalogName"] colorName:anObject[@"fontColorName"]];

        return @{
            NSParagraphStyleAttributeName: p.copy,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: fontColor
        };
    };

    __auto_type Get = ^(NSDictionary *aSource, NSString *aKey, Verifier aVerifier, Transformer aTransformer) {
        id value = aSource[aKey];

        if (aVerifier)
            aVerifier(value, aKey);

        if (aTransformer)
            value = aTransformer(value, aKey);

        return value;
    };

    __auto_type Set = ^(NSMutableDictionary *aDestination, NSDictionary *aSource, NSString *aKey, Verifier aVerifier, Transformer aTransformer) {
        aDestination[aKey] = Get(aSource, aKey, aVerifier, aTransformer);
    };

    @synchronized (self)
    {
        NSDictionary *info = [_cache objectForKey:aStyle.identifier];

        if (!info)
        {
            NSString *resourceName = [NSString stringWithFormat:@"%@-info", aStyle.identifier];
            NSData *data = [[NSDataAsset alloc] initWithName:resourceName bundle:SRBundle()].data;

            if (!data)
                data = [[NSDataAsset alloc] initWithName:resourceName bundle:SRBundle()].data;

            if (!data)
                [NSException raise:NSInternalInconsistencyException format:@"Missing %@", resourceName];

            NSError *error = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!json)
                [NSException raise:NSInternalInconsistencyException
                            format:@"%@ is an invalid JSON: %@", resourceName, error.localizedFailureReason];

            NSMutableDictionary *infoInProgress = NSMutableDictionary.dictionary;

            Set(infoInProgress, json, @"supportedComponents", VerifyIsArray, ^(NSArray *anObject, NSString *aKey) {
                NSMutableArray *components = [NSMutableArray arrayWithCapacity:anObject.count];

                [anObject enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *subkey = [NSString stringWithFormat:@"%@.[%lu]", aKey, idx];
                    VerifyIsComponents(obj, subkey);
                    [components addObject:TransformComponents(obj, subkey)];
                }];

                [components addObject:[SRRecorderControlStyleComponents new]];

                return (NSArray *)components.copy;
            });

            Set(infoInProgress, json, @"metrics", VerifyIsDictionary, ^(NSDictionary *anObject, NSString *aKey) {
                NSMutableDictionary *metricsInProgress = [NSMutableDictionary dictionaryWithCapacity:anObject.count];

                Set(metricsInProgress, anObject, @"minSize", VerifyIsSize, TransformSize);
                Set(metricsInProgress, anObject, @"labelToCancel", VerifyIsNumber, nil);
                Set(metricsInProgress, anObject, @"cancelToClear", VerifyIsNumber, nil);
                Set(metricsInProgress, anObject, @"buttonToAlignment", VerifyIsNumber, nil);
                Set(metricsInProgress, anObject, @"baselineFromTop", VerifyIsNumber, nil);
                Set(metricsInProgress, anObject, @"alignmentToLabel", VerifyIsNumber, nil);
                Set(metricsInProgress, anObject, @"labelToAlignment", VerifyIsNumber, nil);
                Set(metricsInProgress, anObject, @"baselineLayoutOffsetFromBottom", VerifyIsNumber, nil);
                Set(metricsInProgress, anObject, @"baselineDrawingOffsetFromBottom", VerifyIsNumber, nil);
                Set(metricsInProgress, anObject, @"focusRingCornerRadius", VerifyIsSize, TransformSize);
                Set(metricsInProgress, anObject, @"focusRingInsets", VerifyIsEdgeInsets, TransformEdgeInsets);
                Set(metricsInProgress, anObject, @"alignmentInsets", VerifyIsEdgeInsets, TransformEdgeInsets);
                Set(metricsInProgress, anObject, @"normalLabelAttributes", VerifyIsLabelAttributes, TransformLabelAttributes);
                Set(metricsInProgress, anObject, @"recordingLabelAttributes", VerifyIsLabelAttributes, TransformLabelAttributes);
                Set(metricsInProgress, anObject, @"disabledLabelAttributes", VerifyIsLabelAttributes, TransformLabelAttributes);

                return (NSDictionary *)metricsInProgress.copy;
            });

            info = infoInProgress.copy;
            [_cache setObject:info forKey:aStyle.identifier];
        }

        return info;
    }
}

- (NSArray<NSString *> *)lookupPrefixesForStyle:(SRRecorderControlStyle *)aStyle
{
    @synchronized (self)
    {
        __auto_type key = [SRRecorderControlStyleResourceLoaderCacheLookupPrefixesKey new];
        key.identifier = aStyle.identifier.copy;
        key.components = aStyle.effectiveComponents.copy;

        NSArray *lookupPrefixes = [_cache objectForKey:key];

        if (!lookupPrefixes)
        {
            SRRecorderControlStyleComponents *effectiveComponents = aStyle.effectiveComponents;
            NSComparator cmp = ^NSComparisonResult(SRRecorderControlStyleComponents *a, SRRecorderControlStyleComponents *b) {
                return [a compare:b relativeToComponents:effectiveComponents];
            };
            __auto_type supportedComponents = (NSArray<SRRecorderControlStyleComponents *> *)[self infoForStyle:aStyle][@"supportedComponents"];
            supportedComponents = [supportedComponents sortedArrayWithOptions:NSSortStable usingComparator:cmp];
            lookupPrefixes = [NSMutableArray arrayWithCapacity:supportedComponents.count];

            for (SRRecorderControlStyleComponents *c in supportedComponents)
                [(NSMutableArray *)lookupPrefixes addObject:[NSString stringWithFormat:@"%@%@", aStyle.identifier, c.stringRepresentation]];

            lookupPrefixes = lookupPrefixes.copy;
            [_cache setObject:lookupPrefixes forKey:key];
        }

        return lookupPrefixes;
    }
}

- (NSImage *)imageNamed:(NSString *)aName forStyle:(SRRecorderControlStyle *)aStyle
{
    @synchronized (self)
    {
        __auto_type key = [SRRecorderControlStyleResourceLoaderCacheImageKey new];
        key.identifier = aStyle.identifier.copy;
        key.components = aStyle.effectiveComponents.copy;
        key.name = aName.copy;
        NSArray *imageNameCache = [_cache objectForKey:key];
        NSImage *image = nil;

        if (!imageNameCache)
        {
            NSString *imageName = nil;
            BOOL usesSRImage = YES;

            for (NSString *p in [self lookupPrefixesForStyle:aStyle])
            {
                imageName = [NSString stringWithFormat:@"%@-%@", p, aName];

                image = SRImage(imageName);
                if (image)
                {
                    usesSRImage = YES;
                    break;
                }

                image = [NSImage imageNamed:imageName];
                if (image)
                {
                    usesSRImage = NO;
                    break;
                }
            }

            if (!image)
                [NSException raise:NSInternalInconsistencyException format:@"Missing image named %@", aName];

            [_cache setObject:@[imageName, @(usesSRImage)] forKey:key];
        }
        else
        {
            NSString *imageName = imageNameCache[0];
            BOOL usesSRImage = [imageNameCache[1] boolValue];

            if (usesSRImage)
                image = SRImage(imageName);
            else
                image = [NSImage imageNamed:imageName];
        }

        return image;
    }
}

@end


@implementation SRRecorderControlStyle
{
    NSArray<NSString *> *_currentLookupPrefixes;

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

        if (aComponents)
            _preferredComponents = aComponents.copy;
        else
            _preferredComponents = [SRRecorderControlStyleComponents new];

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

+ (SRRecorderControlStyleResourceLoader *)resourceLoader
{
    static SRRecorderControlStyleResourceLoader *Loader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Loader = [SRRecorderControlStyleResourceLoader new];
    });
    return Loader;
}

- (SRRecorderControlStyleComponents *)effectiveComponents
{
    if (_preferredComponents.appearance && _preferredComponents.accessibility && _preferredComponents.layoutDirection && _preferredComponents.tint)
        return _preferredComponents.copy;

    SRRecorderControlStyleComponents *current = [SRRecorderControlStyleComponents currentComponentsForView:self.recorderControl];

    __auto_type appearance = _preferredComponents.appearance;
    if (!appearance)
        appearance = current.appearance ? current.appearance : SRRecorderControlStyleComponentsAppearanceAqua;

    __auto_type accessibility = _preferredComponents.accessibility;
    if (!accessibility)
        accessibility = current.accessibility ? current.accessibility : SRRecorderControlStyleComponentsAccessibilityNone;

    __auto_type layoutDirection = _preferredComponents.layoutDirection;
    if (!layoutDirection)
        layoutDirection = current.layoutDirection ? current.layoutDirection : SRRecorderControlStyleComponentsLayoutDirectionLeftToRight;

    __auto_type tint = _preferredComponents.tint;
    if (!tint)
        tint = current.tint ? current.tint : SRRecorderControlStyleComponentsTintBlue;

    return [[SRRecorderControlStyleComponents alloc] initWithAppearance:appearance
                                                          accessibility:accessibility
                                                        layoutDirection:layoutDirection
                                                                   tint:tint];
}

#pragma mark Methods

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
        MakeEqConstraint(self.cancelButtonLayoutGuide.trailingAnchor, self.alignmentGuide.trailingAnchor),
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
        MakeEqConstraint(self.clearButtonLayoutGuide.trailingAnchor, self.alignmentGuide.trailingAnchor),
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
@synthesize focusRingCornerRadius = _focusRingCornerRadius;
@synthesize focusRingInsets = _focusRingInsets;
@synthesize baselineLayoutOffsetFromBottom = _baselineLayoutOffsetFromBottom;
@synthesize baselineDrawingOffsetFromBottom = _baselineDrawingOffsetFromBottom;
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
    __auto_type newLookupPrefixes = [self.class.resourceLoader lookupPrefixesForStyle:self];
    if ([newLookupPrefixes isEqual:_currentLookupPrefixes])
        return;

    __auto_type UpdateImage = ^(NSString *imageName, NSString *propName, NSRect frame) {
        NSImage *newImage = [self.class.resourceLoader imageNamed:imageName forStyle:self];

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

    if (!_currentLookupPrefixes)
    {
        __auto_type metrics = (NSDictionary *)[self.class.resourceLoader infoForStyle:self][@"metrics"];

        _alignmentRectInsets = [metrics[@"alignmentInsets"] edgeInsetsValue];
        _focusRingCornerRadius = [metrics[@"focusRingCornerRadius"] sizeValue];
        _focusRingInsets = [metrics[@"focusRingInsets"] edgeInsetsValue];
        _baselineLayoutOffsetFromBottom = [metrics[@"baselineLayoutOffsetFromBottom"] doubleValue];
        _baselineDrawingOffsetFromBottom = [metrics[@"baselineDrawingOffsetFromBottom"] doubleValue];
        _normalLabelAttributes = metrics[@"normalLabelAttributes"];
        _recordingLabelAttributes = metrics[@"recordingLabelAttributes"];
        _disabledLabelAttributes = metrics[@"disabledLabelAttributes"];

        NSSize minSize = [metrics[@"minSize"] sizeValue];
        _alignmentWidthConstraint.constant = fdim(minSize.width, _alignmentRectInsets.left + _alignmentRectInsets.right);
        _alignmentHeightConstraint.constant = fdim(minSize.height, _alignmentRectInsets.top + _alignmentRectInsets.bottom);

        _backgroundTopConstraint.constant = -_alignmentRectInsets.top;
        _backgroundLeftConstraint.constant = -_alignmentRectInsets.left;
        _backgroundBottomConstraint.constant = _alignmentRectInsets.bottom;
        _backgroundRightConstraint.constant = _alignmentRectInsets.right;

        _alignmentToLabelConstraint.constant = [metrics[@"alignmentToLabel"] doubleValue];
        _labelToAlignmentConstraint.constant = -[metrics[@"labelToAlignment"] doubleValue];
        _labelToCancelConstraint.constant = -[metrics[@"labelToCancel"] doubleValue];
        _cancelToAlignmentConstraint.constant = -[metrics[@"buttonToAlignment"] doubleValue];
        _clearToAlignmentConstraint.constant = -[metrics[@"buttonToAlignment"] doubleValue];
        _cancelToClearConstraint.constant = -[metrics[@"cancelToClear"] doubleValue];

        CGFloat maxExpectedLeadingLabelOffset = _alignmentToLabelConstraint.constant;
        CGFloat maxExpectedLabelWidth = ceilf([SRLoc(@"Click to record shortcut") sizeWithAttributes:_normalLabelAttributes].width);
        CGFloat maxExpectedTrailingLabelOffset = MAX(_alignmentToLabelConstraint.constant, _labelToCancelConstraint.constant + _cancelButtonWidthConstraint.constant + _cancelToClearConstraint.constant + _clearButtonWidthConstraint.constant + _clearToAlignmentConstraint.constant);
        _alignmentSuggestedWidthConstraint.constant = maxExpectedLeadingLabelOffset + maxExpectedLabelWidth + maxExpectedTrailingLabelOffset;

        _intrinsicContentSize = NSMakeSize(_alignmentSuggestedWidthConstraint.constant, _alignmentHeightConstraint.constant);

        [self.recorderControl noteFocusRingMaskChanged];
        [self.recorderControl invalidateIntrinsicContentSize];
        self.recorderControl.needsDisplay = YES;
    }

    _currentLookupPrefixes = newLookupPrefixes;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)aZone
{
    return [[self.class alloc] initWithIdentifier:self.identifier components:self.preferredComponents];
}

@end
