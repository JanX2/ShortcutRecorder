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

#import <AppKit/AppKit.h>
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

+ (SRKeyCodeTransformer *)sharedPlainTransformer
{
    static dispatch_once_t onceToken;
    static SRKeyCodeTransformer *sharedTransformer = nil;
    dispatch_once(&onceToken, ^
    {
        sharedTransformer = [[self alloc] init];
        sharedTransformer.transformsfunctionKeysToPlainStrings = YES;
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


#pragma mark Properties
@synthesize transformsfunctionKeysToPlainStrings;

- (void)setTransformsfunctionKeysToPlainStrings:(BOOL)newTransformsfunctionKeysToPlainStrings
{
    if (newTransformsfunctionKeysToPlainStrings != transformsfunctionKeysToPlainStrings)
    {
        [self willChangeValueForKey:@"transformsfunctionKeysToPlainStrings"];
        self._specialKeyCodeStringsDictionary = nil;
        transformsfunctionKeysToPlainStrings = newTransformsfunctionKeysToPlainStrings;
        [self didChangeValueForKey:@"transformsfunctionKeysToPlainStrings"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfTransformsfunctionKeysToPlainStrings
{
    return NO;
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
                 self.transformsfunctionKeysToPlainStrings ? @"F1" : SRChar(NSF1FunctionKey),   SRInt(kSRKeysF1),
                 self.transformsfunctionKeysToPlainStrings ? @"F2" : SRChar(NSF2FunctionKey),   SRInt(kSRKeysF2),
                 self.transformsfunctionKeysToPlainStrings ? @"F3" : SRChar(NSF3FunctionKey),   SRInt(kSRKeysF3),
                 self.transformsfunctionKeysToPlainStrings ? @"F4" : SRChar(NSF4FunctionKey),   SRInt(kSRKeysF4),
                 self.transformsfunctionKeysToPlainStrings ? @"F5" : SRChar(NSF5FunctionKey),   SRInt(kSRKeysF5),
                 self.transformsfunctionKeysToPlainStrings ? @"F6" : SRChar(NSF6FunctionKey),   SRInt(kSRKeysF6),
                 self.transformsfunctionKeysToPlainStrings ? @"F7" : SRChar(NSF7FunctionKey),   SRInt(kSRKeysF7),
                 self.transformsfunctionKeysToPlainStrings ? @"F8" : SRChar(NSF8FunctionKey),   SRInt(kSRKeysF8),
                 self.transformsfunctionKeysToPlainStrings ? @"F9" : SRChar(NSF9FunctionKey),   SRInt(kSRKeysF9),
                 self.transformsfunctionKeysToPlainStrings ? @"F10" : SRChar(NSF10FunctionKey), SRInt(kSRKeysF10),
                 self.transformsfunctionKeysToPlainStrings ? @"F11" : SRChar(NSF11FunctionKey), SRInt(kSRKeysF11),
                 self.transformsfunctionKeysToPlainStrings ? @"F12" : SRChar(NSF12FunctionKey), SRInt(kSRKeysF12),
                 self.transformsfunctionKeysToPlainStrings ? @"F13" : SRChar(NSF13FunctionKey), SRInt(kSRKeysF13),
                 self.transformsfunctionKeysToPlainStrings ? @"F14" : SRChar(NSF14FunctionKey), SRInt(kSRKeysF14),
                 self.transformsfunctionKeysToPlainStrings ? @"F15" : SRChar(NSF15FunctionKey), SRInt(kSRKeysF15),
                 self.transformsfunctionKeysToPlainStrings ? @"F16" : SRChar(NSF16FunctionKey), SRInt(kSRKeysF16),
                 self.transformsfunctionKeysToPlainStrings ? @"F17" : SRChar(NSF17FunctionKey), SRInt(kSRKeysF17),
                 self.transformsfunctionKeysToPlainStrings ? @"F18" : SRChar(NSF18FunctionKey), SRInt(kSRKeysF18),
                 self.transformsfunctionKeysToPlainStrings ? @"F19" : SRChar(NSF19FunctionKey), SRInt(kSRKeysF19),
                 SRChar(KeyboardSpaceGlyph),                                                    SRInt(kSRKeysSpace),
                 SRChar(KeyboardDeleteLeftGlyph),                                               SRInt(kSRKeysDeleteLeft),
                 SRChar(KeyboardDeleteRightGlyph),                                              SRInt(kSRKeysDeleteRight),
                 SRChar(KeyboardPadClearGlyph),                                                 SRInt(kSRKeysPadClear),
                 SRChar(KeyboardLeftArrowGlyph),                                                SRInt(kSRKeysLeftArrow),
                 SRChar(KeyboardRightArrowGlyph),                                               SRInt(kSRKeysRightArrow),
                 SRChar(KeyboardUpArrowGlyph),                                                  SRInt(kSRKeysUpArrow),
                 SRChar(KeyboardDownArrowGlyph),                                                SRInt(kSRKeysDownArrow),
                 SRChar(KeyboardSoutheastArrowGlyph),                                           SRInt(kSRKeysSoutheastArrow),
                 SRChar(KeyboardNorthwestArrowGlyph),                                           SRInt(kSRKeysNorthwestArrow),
                 SRChar(KeyboardEscapeGlyph),                                                   SRInt(kSRKeysEscape),
                 SRChar(KeyboardPageDownGlyph),                                                 SRInt(kSRKeysPageDown),
                 SRChar(KeyboardPageUpGlyph),                                                   SRInt(kSRKeysPageUp),
                 SRChar(KeyboardReturnR2LGlyph),                                                SRInt(kSRKeysReturnR2L),
                 SRChar(KeyboardReturnGlyph),                                                   SRInt(kSRKeysReturn),
                 SRChar(KeyboardTabRightGlyph),                                                 SRInt(kSRKeysTabRight),
                 SRChar(KeyboardHelpGlyph),                                                     SRInt(kSRKeysHelp),
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
