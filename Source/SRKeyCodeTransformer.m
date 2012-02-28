//
//  SRKeyCodeTransformer.h
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
//      Silvio Rizzi

#import "SRKeyCodeTransformer.h"
#import "SRCommon.h"


static NSString *const _SRReverseTransformDictionaryCacheKey = @"reverseTransform";

static NSString *const _SRPadKeysCacheKey = @"padKeys";

static NSString *const _SRSpecialKeyCodeStringsDictionaryCacheKey = @"specialKeyCodeStrings";


@implementation SRKeyCodeTransformer

+ (SRKeyCodeTransformer *)sharedTransformer
{
    static dispatch_once_t onceToken;
    static SRKeyCodeTransformer *sharedTransformer = nil;
    dispatch_once(&onceToken, ^
    {
        sharedTransformer = [[self alloc] init];
    });
    return sharedTransformer;
}

- (id)init
{
    if ((self = [super init]))
    {
        _cache = [[NSCache alloc] init];
        [_cache setName:@"SRKeyCodeTransformer's cache"];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(_keyboardInputSourceDidChange)
                                                                name:(NSString *)kTISNotifySelectedKeyboardInputSourceChanged
                                                              object:nil];
    }
    return self;
}

- (void)dealloc
{
    [_cache release];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Methods

- (BOOL)isSpecialKeyCode:(NSInteger)aKeyCode
{
    return ([self._specialKeyCodeStringsDictionary objectForKey:SRInt(aKeyCode)] != nil);
}

+ (TISInputSourceRef)preferredKeyboardInputSource
{
    return TISCopyCurrentKeyboardInputSource();
}

+ (TISInputSourceRef)ASCIICapableKeyboardInputSource
{
    return TISCopyCurrentASCIICapableKeyboardInputSource();
}


#pragma mark Private
@dynamic _reverseTransformDictionary;
@dynamic _padKeys;
@dynamic _specialKeyCodeStringsDictionary;

- (NSDictionary *)_reverseTransformDictionary
{
    @synchronized (self)
    {
        NSMutableDictionary *d = [[[_cache objectForKey:_SRReverseTransformDictionaryCacheKey] retain] autorelease];
        if (d == nil)
        {
            static const NSUInteger NumberOfPrecalculatedKeyCodes = 128U;
            d = [NSMutableDictionary dictionaryWithCapacity:NumberOfPrecalculatedKeyCodes];
            for (NSUInteger i = 0U; i < NumberOfPrecalculatedKeyCodes; ++i)
            {
                NSNumber *keyCode = [NSNumber numberWithUnsignedInteger:i];
                NSString *string = [self transformedValue:keyCode];
                if ([string length] > 0)
                    [d setObject:keyCode forKey:string];
            }
            [_cache setObject:d forKey:_SRReverseTransformDictionaryCacheKey];
        }
        return d;
    }
}

- (void)set_reverseTransformDictionary:(NSDictionary *)newReverseTransformDictionary
{
    NSParameterAssert(newReverseTransformDictionary == nil);

    [_cache removeObjectForKey:_SRReverseTransformDictionaryCacheKey];
}

- (NSArray *)_padKeys
{
    @synchronized (self)
    {
        NSArray *a = [[[_cache objectForKey:_SRPadKeysCacheKey] retain] autorelease];
        if (a == nil)
        {
            a = [NSArray arrayWithObjects:
                             SRInt(65), // ,
                             SRInt(67), // *
                             SRInt(69), // +
                             SRInt(75), // /
                             SRInt(78), // -
                             SRInt(81), // =
                             SRInt(82), // 0
                             SRInt(83), // 1
                             SRInt(84), // 2
                             SRInt(85), // 3
                             SRInt(86), // 4
                             SRInt(87), // 5
                             SRInt(88), // 6
                             SRInt(89), // 7
                             SRInt(91), // 8
                             SRInt(92), // 9
                             nil];
            [_cache setObject:a forKey:_SRPadKeysCacheKey];
        }
        return a;
    }
}

- (void)set_padKeys:(NSArray *)newPadKeys
{
    NSParameterAssert(newPadKeys == nil);

    [_cache removeObjectForKey:_SRPadKeysCacheKey];
}

- (NSDictionary *)_specialKeyCodeStringsDictionary
{
    @synchronized (self)
    {
        NSDictionary *d = [[[_cache objectForKey:_SRSpecialKeyCodeStringsDictionaryCacheKey] retain] autorelease];
        if (d == nil)
        {
            d = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"F1", SRInt(122),
                                  @"F2", SRInt(120),
                                  @"F3", SRInt(99),
                                  @"F4", SRInt(118),
                                  @"F5", SRInt(96),
                                  @"F6", SRInt(97),
                                  @"F7", SRInt(98),
                                  @"F8", SRInt(100),
                                  @"F9", SRInt(101),
                                  @"F10", SRInt(109),
                                  @"F11", SRInt(103),
                                  @"F12", SRInt(111),
                                  @"F13", SRInt(105),
                                  @"F14", SRInt(107),
                                  @"F15", SRInt(113),
                                  @"F16", SRInt(106),
                                  @"F17", SRInt(64),
                                  @"F18", SRInt(79),
                                  @"F19", SRInt(80),
                                  SRChar(KeyboardSpaceGlyph), SRInt(49),
                                  SRChar(KeyboardDeleteLeftGlyph), SRInt(51),
                                  SRChar(KeyboardDeleteRightGlyph), SRInt(117),
                                  SRChar(KeyboardPadClearGlyph), SRInt(71),
                                  SRChar(KeyboardLeftArrowGlyph), SRInt(123),
                                  SRChar(KeyboardRightArrowGlyph), SRInt(124),
                                  SRChar(KeyboardUpArrowGlyph), SRInt(126),
                                  SRChar(KeyboardDownArrowGlyph), SRInt(125),
                                  SRChar(KeyboardSoutheastArrowGlyph), SRInt(119),
                                  SRChar(KeyboardNorthwestArrowGlyph), SRInt(115),
                                  SRChar(KeyboardEscapeGlyph), SRInt(53),
                                  SRChar(KeyboardPageDownGlyph), SRInt(121),
                                  SRChar(KeyboardPageUpGlyph), SRInt(116),
                                  SRChar(KeyboardReturnR2LGlyph), SRInt(36),
                                  SRChar(KeyboardReturnGlyph), SRInt(76),
                                  SRChar(KeyboardTabRightGlyph), SRInt(48),
                                  SRChar(KeyboardHelpGlyph), SRInt(114),
                                  nil];
        }
        return d;
    }
}

- (void)set_specialKeyCodeStringsDictionary:(NSDictionary *)newSpecialKeyCodeStringsDictionary
{
    NSParameterAssert(newSpecialKeyCodeStringsDictionary == nil);

    [_cache removeObjectForKey:_SRSpecialKeyCodeStringsDictionaryCacheKey];
}

- (void)_keyboardInputSourceDidChange
{
    self._reverseTransformDictionary = nil;
}


#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass;
{
    return [NSString class];
}

- (id)transformedValue:(id)value
{
    if (![value isKindOfClass:[NSNumber class]])
        return nil;

    // Can be -1 when empty
    NSInteger keyCode = [value shortValue];
    if (keyCode < 0)
        return nil;

    // We have some special gylphs for some special keys...
    NSString *unmappedString = [self._specialKeyCodeStringsDictionary objectForKey:SRInt(keyCode)];
    if (unmappedString != nil)
        return unmappedString;

    BOOL isPadKey = [self._padKeys containsObject:SRInt(keyCode)];

    OSStatus err = noErr;
    TISInputSourceRef tisSource = [[self class] preferredKeyboardInputSource];
    if (tisSource == nil)
        return nil;
    CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
    UInt32 keysDown = 0;
    CFRelease(tisSource);

    // For non-unicode layouts such as Chinese, Japanese, and Korean, get the ASCII capable layout
    if (layoutData == nil)
    {
        tisSource = [[self class] ASCIICapableKeyboardInputSource];
        layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
        CFRelease(tisSource);
    }

    if (layoutData == nil)
        return nil;

    const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);

    UniCharCount length = 4;
    UniCharCount realLength = 0;
    UniChar chars[4] = {0};

    err = UCKeyTranslate(keyLayout,
                         keyCode,
                         kUCKeyActionDisplay,
                         0,
                         LMGetKbdType(),
                         kUCKeyTranslateNoDeadKeysBit,
                         &keysDown,
                         length,
                         &realLength,
                         chars);
    if (err != noErr)
        return nil;

    NSString *keyString = [[NSString stringWithCharacters:chars length:1] uppercaseString];

    if (isPadKey)
        return [NSString stringWithFormat:SRLoc(@"Pad %@"), keyString];
    else
        return keyString;
}

- (id)reverseTransformedValue:(id)value
{
    if (![value isKindOfClass:[NSString class]])
        return nil;
    else
        return [self._reverseTransformDictionary objectForKey:value];
}

@end
