//
//  Copyright 2012 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <os/trace.h>
#import <os/activity.h>

#import "SRCommon.h"
#import "SRShortcut.h"
#import "SRKeyCodeTransformer.h"


FOUNDATION_STATIC_INLINE NSString* _SRUnicharToString(unichar aChar)
{
    return [NSString stringWithFormat: @"%C", aChar];
}


/*!
 Return a retained isntance of Keyboard Layout Input Source.
 */
typedef TISInputSourceRef (*_SRKeyCodeTransformerCacheInputSourceCreate)(void);


@interface _SRKeyCodeTranslatorCacheKey : NSObject <NSCopying>
@property (copy, readonly) NSString *identifier;
@property (readonly) NSEventModifierFlags implicitModifierFlags;
@property (readonly) NSEventModifierFlags explicitModifierFlags;
@property (readonly) unsigned short keyCode;
- (instancetype)initWithIdentifier:(NSString *)anIdentifier
             implicitModifierFlags:(NSEventModifierFlags)anImplicitModifierFlags
             explicitModifierFlags:(NSEventModifierFlags)anExplicitModifierFlags
                           keyCode:(unsigned short)aKeyCode;
@end


@implementation _SRKeyCodeTranslatorCacheKey

- (instancetype)initWithIdentifier:(NSString *)anIdentifier
             implicitModifierFlags:(NSEventModifierFlags)anImplicitModifierFlags
             explicitModifierFlags:(NSEventModifierFlags)anExplicitModifierFlags
                           keyCode:(unsigned short)aKeyCode
{
    self = [super init];

    if (self)
    {
        _identifier = [anIdentifier copy];
        _implicitModifierFlags = anImplicitModifierFlags & SRCocoaModifierFlagsMask;
        _explicitModifierFlags = anExplicitModifierFlags & SRCocoaModifierFlagsMask;
        _keyCode = aKeyCode;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)aZone
{
    return self;
}

- (BOOL)isEqual:(_SRKeyCodeTranslatorCacheKey *)anObject
{
    return self.keyCode == anObject.keyCode &&
        self.explicitModifierFlags == anObject.explicitModifierFlags &&
        self.implicitModifierFlags == anObject.implicitModifierFlags &&
        [self.identifier isEqual:anObject.identifier];
}

- (NSUInteger)hash
{
    NSUInteger implicitFlagsBitSize = 4;
    NSUInteger explicitFlagsBitSize = 4;
    NSUInteger keyCodeBitSize = sizeof(unsigned short) * CHAR_BIT;

    NSUInteger identifierHash = _identifier.hash;
    NSUInteger implicitFlagsHash = _implicitModifierFlags >> 17;
    NSUInteger explicitFlagsHash = _explicitModifierFlags >> 17;
    NSUInteger keyCodeHash = _keyCode;

    return keyCodeHash |
        (implicitFlagsHash << keyCodeBitSize) |
        (explicitFlagsHash << (keyCodeBitSize + implicitFlagsBitSize)) |
        (identifierHash << (keyCodeBitSize + implicitFlagsBitSize + explicitFlagsBitSize));
}

@end


/*!
 Cache of the key code translation with respect to input source identifier.
 */
@interface _SRKeyCodeTranslator : NSObject
{
    NSCache<_SRKeyCodeTranslatorCacheKey *, NSString *> *_translationCache;
    _SRKeyCodeTransformerCacheInputSourceCreate _inputSourceCreator;
    id _inputSource;
}
@property (class, readonly) _SRKeyCodeTranslator *shared;
@property (readonly) id inputSource;
- (instancetype)initWithInputSourceCreator:(_SRKeyCodeTransformerCacheInputSourceCreate)aCreator NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithInputSource:(id)anInputSource NS_DESIGNATED_INITIALIZER;
- (nullable NSString *)translateKeyCode:(unsigned short)aKeyCode
                  implicitModifierFlags:(NSEventModifierFlags)anImplicitModifierFlags
                  explicitModifierFlags:(NSEventModifierFlags)anExplicitModifierFlags
                             usingCache:(BOOL)anIsUsingCache;
@end


@implementation _SRKeyCodeTranslator

+ (_SRKeyCodeTranslator *)shared
{
    static _SRKeyCodeTranslator *Cache = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Cache = [_SRKeyCodeTranslator new];
    });
    return Cache;
}

- (instancetype)init
{
    return [self initWithInputSourceCreator:TISCopyCurrentKeyboardLayoutInputSource];
}

- (instancetype)initWithInputSourceCreator:(_SRKeyCodeTransformerCacheInputSourceCreate)aCreator
{
    self = [super init];

    if (self)
    {
        _inputSourceCreator = aCreator;
        _translationCache = [NSCache new];
    }

    return self;
}

- (instancetype)initWithInputSource:(id)anInputSource
{
    self = [super init];

    if (self)
    {
        _inputSource = anInputSource;
        _translationCache = [NSCache new];
    }

    return self;
}

- (id)inputSource
{
    if (_inputSource)
        return _inputSource;
    else
        return (__bridge_transfer id)_inputSourceCreator();
}

- (nullable NSString *)translateKeyCode:(unsigned short)aKeyCode
                  implicitModifierFlags:(NSEventModifierFlags)anImplicitModifierFlags
                  explicitModifierFlags:(NSEventModifierFlags)anExplicitModifierFlags
                             usingCache:(BOOL)anIsUsingCache
{
    anImplicitModifierFlags &= SRCocoaModifierFlagsMask;
    anExplicitModifierFlags &= SRCocoaModifierFlagsMask;

    TISInputSourceRef inputSource = (__bridge TISInputSourceRef)self.inputSource;

    if (!inputSource)
    {
        os_trace_error("#Critical Failed to create an input source");
        return nil;
    }

    _SRKeyCodeTranslatorCacheKey *cacheKey = nil;

    if (anIsUsingCache)
    {
        NSString *sourceIdentifier = (__bridge NSString *)TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID);

        if (sourceIdentifier)
        {
            cacheKey = [[_SRKeyCodeTranslatorCacheKey alloc] initWithIdentifier:sourceIdentifier
                                                          implicitModifierFlags:anImplicitModifierFlags
                                                          explicitModifierFlags:anExplicitModifierFlags
                                                                        keyCode:aKeyCode];
        }
        else
            os_trace_error("#Error Input source misses an ID");
    }

    @synchronized (self)
    {
        NSString *translation = nil;

        if (cacheKey)
        {
            translation = [_translationCache objectForKey:cacheKey];

            if (translation)
            {
                os_trace_debug("Translation cache hit");
                return translation;
            }
            else
                os_trace_debug("Translation cache miss");
        }

        CFDataRef layoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData);
        const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
        static const UniCharCount MaxLength = 255;
        UniCharCount actualLength = 0;
        UniChar chars[MaxLength] = {0};
        UInt32 deadKeyState = 0;
        OSStatus error = UCKeyTranslate(keyLayout,
                                        aKeyCode,
                                        kUCKeyActionDisplay,
                                        SRCocoaToCarbonFlags(anImplicitModifierFlags) >> 8,
                                        LMGetKbdType(),
                                        kUCKeyTranslateNoDeadKeysBit,
                                        &deadKeyState,
                                        sizeof(chars) / sizeof(UniChar),
                                        &actualLength,
                                        chars);
        if (error != noErr)
        {
            os_trace_error("#Error Unable to translate keyCode %hu and modifierFlags %lu: %d",
                           aKeyCode,
                           anImplicitModifierFlags,
                           error);
            return nil;
        }
        else if (actualLength == 0)
        {
            os_trace("#Error No translation exists for keyCode %hu and modifierFlags %lu",
                           aKeyCode,
                           anImplicitModifierFlags);
            return nil;
        }

        translation = [NSString stringWithCharacters:chars length:actualLength];

        if (cacheKey)
            [_translationCache setObject:translation forKey:cacheKey];

        return translation;
    }
}

@end


/*!
 ASCII Cache of the key code translation with respect to input source identifier capable of reverse transform.
 */
@interface _SRKeyCodeASCIITranslator : _SRKeyCodeTranslator
@property (class, readonly) _SRKeyCodeASCIITranslator *shared;
- (nullable NSNumber *)keyCodeForTranslation:(NSString *)aTranslation;
@end


@implementation _SRKeyCodeASCIITranslator
{
    NSDictionary<NSString *, NSNumber *> *_translationToKeyCode;
    NSString *_inputSourceIdentifier;
}

+ (_SRKeyCodeASCIITranslator *)shared
{
    static _SRKeyCodeASCIITranslator *Cache = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Cache = [[_SRKeyCodeASCIITranslator alloc] initWithInputSourceCreator:TISCopyCurrentASCIICapableKeyboardLayoutInputSource];
    });
    return Cache;
}

- (NSNumber *)keyCodeForTranslation:(NSString *)aTranslation
{
    NSAssert([aTranslation.lowercaseString isEqualToString:aTranslation], @"aTranslation must be a lowercase string");

    TISInputSourceRef inputSource = _inputSourceCreator();

    if (!inputSource)
    {
        os_trace_error("#Critical Failed to create an input source");
        return nil;
    }

    inputSource = (TISInputSourceRef)CFAutorelease(inputSource);

    NSString *sourceIdentifier = (__bridge NSString *)TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID);

    if (!sourceIdentifier)
    {
        os_trace_error("#Error Input source misses an ID");
        return nil;
    }

    @synchronized (self)
    {
        if ([_inputSourceIdentifier isEqualToString:sourceIdentifier])
            return _translationToKeyCode[aTranslation];

        os_trace_debug("Updating translation -> key code mapping");

        __auto_type knownKeyCodes = SRASCIILiteralKeyCodeTransformer.knownKeyCodes;
        NSMutableDictionary *newTranslationToKeyCode = [NSMutableDictionary dictionaryWithCapacity:knownKeyCodes.count];

        for (NSNumber *keyCode in knownKeyCodes)
        {
            NSString *translation = [self translateKeyCode:keyCode.unsignedShortValue
                                     implicitModifierFlags:0
                                     explicitModifierFlags:0
                                                usingCache:YES];

            if (translation.length)
                newTranslationToKeyCode[translation] = keyCode;
        }

        _translationToKeyCode = [newTranslationToKeyCode copy];
        _inputSourceIdentifier = [sourceIdentifier copy];

        return _translationToKeyCode[aTranslation];
    }
}

@end


@interface SRKeyCodeTransformer ()
{
@protected
    _SRKeyCodeTranslator *_translator;
}

@end


@implementation SRKeyCodeTransformer

- (instancetype)init
{
    if (self.class == SRKeyCodeTransformer.class)
        return SRSymbolicKeyCodeTransformer.sharedTransformer;
    else
        return [super init];
}

- (instancetype)initWithInputSource:(id)anInputSource
{
    if (self.class == SRKeyCodeTransformer.class)
        return [[SRSymbolicKeyCodeTransformer alloc] initWithInputSource:anInputSource];
    else
    {
        self = [super init];

        if (self)
        {
            _translator = [[_SRKeyCodeTranslator alloc] initWithInputSource:anInputSource];
        }

        return self;
    }
}

#pragma mark Properties

+ (NSArray<NSNumber *> *)knownKeyCodes
{
    static NSArray<NSNumber *> *ExpectedKeyCodes = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        ExpectedKeyCodes = @[
            @(kVK_ANSI_0),
            @(kVK_ANSI_1),
            @(kVK_ANSI_2),
            @(kVK_ANSI_3),
            @(kVK_ANSI_4),
            @(kVK_ANSI_5),
            @(kVK_ANSI_6),
            @(kVK_ANSI_7),
            @(kVK_ANSI_8),
            @(kVK_ANSI_9),
            @(kVK_ANSI_A),
            @(kVK_ANSI_B),
            @(kVK_ANSI_Backslash),
            @(kVK_ANSI_C),
            @(kVK_ANSI_Comma),
            @(kVK_ANSI_D),
            @(kVK_ANSI_E),
            @(kVK_ANSI_Equal),
            @(kVK_ANSI_F),
            @(kVK_ANSI_G),
            @(kVK_ANSI_Grave),
            @(kVK_ANSI_H),
            @(kVK_ANSI_I),
            @(kVK_ANSI_J),
            @(kVK_ANSI_K),
            @(kVK_ANSI_Keypad0),
            @(kVK_ANSI_Keypad1),
            @(kVK_ANSI_Keypad2),
            @(kVK_ANSI_Keypad3),
            @(kVK_ANSI_Keypad4),
            @(kVK_ANSI_Keypad5),
            @(kVK_ANSI_Keypad6),
            @(kVK_ANSI_Keypad7),
            @(kVK_ANSI_Keypad8),
            @(kVK_ANSI_Keypad9),
            @(kVK_ANSI_KeypadDecimal),
            @(kVK_ANSI_KeypadDivide),
            @(kVK_ANSI_KeypadEnter),
            @(kVK_ANSI_KeypadEquals),
            @(kVK_ANSI_KeypadMinus),
            @(kVK_ANSI_KeypadMultiply),
            @(kVK_ANSI_KeypadPlus),
            @(kVK_ANSI_L),
            @(kVK_ANSI_LeftBracket),
            @(kVK_ANSI_M),
            @(kVK_ANSI_Minus),
            @(kVK_ANSI_N),
            @(kVK_ANSI_O),
            @(kVK_ANSI_P),
            @(kVK_ANSI_Period),
            @(kVK_ANSI_Q),
            @(kVK_ANSI_Quote),
            @(kVK_ANSI_R),
            @(kVK_ANSI_RightBracket),
            @(kVK_ANSI_S),
            @(kVK_ANSI_Semicolon),
            @(kVK_ANSI_Slash),
            @(kVK_ANSI_T),
            @(kVK_ANSI_U),
            @(kVK_ANSI_V),
            @(kVK_ANSI_W),
            @(kVK_ANSI_X),
            @(kVK_ANSI_Y),
            @(kVK_ANSI_Z),
            @(kVK_CapsLock),
            @(kVK_Command),
            @(kVK_Control),
            @(kVK_Delete),
            @(kVK_DownArrow),
            @(kVK_End),
            @(kVK_Escape),
            @(kVK_F1),
            @(kVK_F2),
            @(kVK_F3),
            @(kVK_F4),
            @(kVK_F5),
            @(kVK_F6),
            @(kVK_F7),
            @(kVK_F8),
            @(kVK_F9),
            @(kVK_F10),
            @(kVK_F11),
            @(kVK_F12),
            @(kVK_F13),
            @(kVK_F14),
            @(kVK_F15),
            @(kVK_F16),
            @(kVK_F17),
            @(kVK_F18),
            @(kVK_F19),
            @(kVK_F20),
            @(kVK_ForwardDelete),
            @(kVK_Function),
            @(kVK_Help),
            @(kVK_Home),
            @(kVK_ISO_Section),
            @(kVK_JIS_Eisu),
            @(kVK_JIS_Kana),
            @(kVK_JIS_KeypadComma),
            @(kVK_JIS_Underscore),
            @(kVK_JIS_Yen),
            @(kVK_LeftArrow),
            @(kVK_Mute),
            @(kVK_Option),
            @(kVK_PageDown),
            @(kVK_PageUp),
            @(kVK_Return),
            @(kVK_RightArrow),
            @(kVK_RightCommand),
            @(kVK_RightControl),
            @(kVK_RightOption),
            @(kVK_RightShift),
            @(kVK_Shift),
            @(kVK_Space),
            @(kVK_Tab),
            @(kVK_UpArrow),
            @(kVK_VolumeDown),
            @(kVK_VolumeUp)
        ];
    });

    return ExpectedKeyCodes;
}

+ (instancetype)sharedTransformer
{
    return SRSymbolicKeyCodeTransformer.sharedTransformer;
}

- (id)inputSource
{
    return _translator.inputSource;
}

#pragma mark Methods

- (NSString *)literalForKeyCode:(unsigned short)aValue
      withImplicitModifierFlags:(NSEventModifierFlags)anImplicitModifierFlags
          explicitModifierFlags:(NSEventModifierFlags)anExplicitModifierFlags
                layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    switch (aValue) {
        case kVK_F1:
            return @"F1";
        case kVK_F2:
            return @"F2";
        case kVK_F3:
            return @"F3";
        case kVK_F4:
            return @"F4";
        case kVK_F5:
            return @"F5";
        case kVK_F6:
            return @"F6";
        case kVK_F7:
            return @"F7";
        case kVK_F8:
            return @"F8";
        case kVK_F9:
            return @"F9";
        case kVK_F10:
            return @"F10";
        case kVK_F11:
            return @"F11";
        case kVK_F12:
            return @"F12";
        case kVK_F13:
            return @"F13";
        case kVK_F14:
            return @"F14";
        case kVK_F15:
            return @"F15";
        case kVK_F16:
            return @"F16";
        case kVK_F17:
            return @"F17";
        case kVK_F18:
            return @"F18";
        case kVK_F19:
            return @"F19";
        case kVK_F20:
            return @"F20";
        case kVK_Space:
            return SRLoc(@"Space");
        case kVK_Delete:
            return aDirection == NSUserInterfaceLayoutDirectionRightToLeft ? SRKeyCodeStringDeleteRight : SRKeyCodeStringDeleteLeft;
        case kVK_ForwardDelete:
            return aDirection == NSUserInterfaceLayoutDirectionRightToLeft ? SRKeyCodeStringDeleteLeft : SRKeyCodeStringDeleteRight;
        case kVK_ANSI_KeypadClear:
            return SRKeyCodeStringPadClear;
        case kVK_LeftArrow:
            return SRKeyCodeStringLeftArrow;
        case kVK_RightArrow:
            return SRKeyCodeStringRightArrow;
        case kVK_UpArrow:
            return SRKeyCodeStringUpArrow;
        case kVK_DownArrow:
            return SRKeyCodeStringDownArrow;
        case kVK_End:
            return SRKeyCodeStringSoutheastArrow;
        case kVK_Home:
            return SRKeyCodeStringNorthwestArrow;
        case kVK_Escape:
            return SRKeyCodeStringEscape;
        case kVK_PageDown:
            return SRKeyCodeStringPageDown;
        case kVK_PageUp:
            return SRKeyCodeStringPageUp;
        case kVK_Return:
            return SRKeyCodeStringReturnR2L;
        case kVK_ANSI_KeypadEnter:
            return SRKeyCodeStringReturn;
        case kVK_Tab:
        {
            if (anImplicitModifierFlags & NSEventModifierFlagShift)
                return aDirection == NSUserInterfaceLayoutDirectionRightToLeft ? SRKeyCodeStringTabRight : SRKeyCodeStringTabLeft;
            else
                return aDirection == NSUserInterfaceLayoutDirectionRightToLeft ? SRKeyCodeStringTabLeft : SRKeyCodeStringTabRight;
        }
        case kVK_Help:
            return @"?⃝";
        default:
            return [_translator translateKeyCode:aValue
                           implicitModifierFlags:anImplicitModifierFlags
                           explicitModifierFlags:anExplicitModifierFlags
                                      usingCache:YES].uppercaseString;
    }
}

- (NSString *)symbolForKeyCode:(unsigned short)aValue
     withImplicitModifierFlags:(NSEventModifierFlags)anImplicitModifierFlags
         explicitModifierFlags:(NSEventModifierFlags)anExplicitModifierFlags
               layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    switch (aValue) {
        case kVK_F1:
            return _SRUnicharToString(NSF1FunctionKey);
        case kVK_F2:
            return _SRUnicharToString(NSF2FunctionKey);
        case kVK_F3:
            return _SRUnicharToString(NSF3FunctionKey);
        case kVK_F4:
            return _SRUnicharToString(NSF4FunctionKey);
        case kVK_F5:
            return _SRUnicharToString(NSF5FunctionKey);
        case kVK_F6:
            return _SRUnicharToString(NSF6FunctionKey);
        case kVK_F7:
            return _SRUnicharToString(NSF7FunctionKey);
        case kVK_F8:
            return _SRUnicharToString(NSF8FunctionKey);
        case kVK_F9:
            return _SRUnicharToString(NSF9FunctionKey);
        case kVK_F10:
            return _SRUnicharToString(NSF10FunctionKey);
        case kVK_F11:
            return _SRUnicharToString(NSF11FunctionKey);
        case kVK_F12:
            return _SRUnicharToString(NSF12FunctionKey);
        case kVK_F13:
            return _SRUnicharToString(NSF13FunctionKey);
        case kVK_F14:
            return _SRUnicharToString(NSF14FunctionKey);
        case kVK_F15:
            return _SRUnicharToString(NSF15FunctionKey);
        case kVK_F16:
            return _SRUnicharToString(NSF16FunctionKey);
        case kVK_F17:
            return _SRUnicharToString(NSF17FunctionKey);
        case kVK_F18:
            return _SRUnicharToString(NSF18FunctionKey);
        case kVK_F19:
            return _SRUnicharToString(NSF19FunctionKey);
        case kVK_F20:
            return _SRUnicharToString(NSF20FunctionKey);
        case kVK_Space:
            return _SRUnicharToString(' ');
        case kVK_Delete:
            return _SRUnicharToString(NSBackspaceCharacter);
        case kVK_ForwardDelete:
            return _SRUnicharToString(NSDeleteCharacter);
        case kVK_ANSI_KeypadClear:
            return _SRUnicharToString(NSClearLineFunctionKey);
        case kVK_LeftArrow:
            return _SRUnicharToString(NSLeftArrowFunctionKey);
        case kVK_RightArrow:
            return _SRUnicharToString(NSRightArrowFunctionKey);
        case kVK_UpArrow:
            return _SRUnicharToString(NSUpArrowFunctionKey);
        case kVK_DownArrow:
            return _SRUnicharToString(NSDownArrowFunctionKey);
        case kVK_End:
            return _SRUnicharToString(NSEndFunctionKey);
        case kVK_Home:
            return _SRUnicharToString(NSHomeFunctionKey);
        case kVK_Escape:
            return _SRUnicharToString('\e');
        case kVK_PageDown:
            return _SRUnicharToString(NSPageDownFunctionKey);
        case kVK_PageUp:
            return _SRUnicharToString(NSPageUpFunctionKey);
        case kVK_Return:
            return _SRUnicharToString(NSCarriageReturnCharacter);
        case kVK_ANSI_KeypadEnter:
            return _SRUnicharToString(NSEnterCharacter);
        case kVK_Tab:
            return _SRUnicharToString(NSTabCharacter);
        case kVK_Help:
            return _SRUnicharToString(NSHelpFunctionKey);
        default:
            return [_translator translateKeyCode:aValue
                           implicitModifierFlags:anImplicitModifierFlags
                           explicitModifierFlags:anExplicitModifierFlags
                                      usingCache:YES];
    }
}

- (NSString *)transformedValue:(NSNumber *)aValue
     withImplicitModifierFlags:(NSNumber *)anImplicitModifierFlags
         explicitModifierFlags:(NSNumber *)anExplicitModifierFlags
               layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    return nil;
}

#pragma mark Deprecated

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (instancetype)sharedASCIITransformer
{
    return SRASCIISymbolicKeyCodeTransformer.sharedTransformer;
}

+ (instancetype)sharedPlainTransformer
{
    return SRLiteralKeyCodeTransformer.sharedTransformer;
}

+ (SRKeyCodeTransformer *)sharedPlainASCIITransformer
{
    return SRASCIILiteralKeyCodeTransformer.sharedTransformer;
}

+ (NSDictionary<NSNumber *, NSString *> *)specialKeyCodeToSymbolMapping
{
    // Most of these keys are system constans.
    // Values for rest of the keys were given by setting key equivalents in IB.
    static NSDictionary *Mapping = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Mapping = @{
            @(kVK_F1): _SRUnicharToString(NSF1FunctionKey),
            @(kVK_F2): _SRUnicharToString(NSF2FunctionKey),
            @(kVK_F3): _SRUnicharToString(NSF3FunctionKey),
            @(kVK_F4): _SRUnicharToString(NSF4FunctionKey),
            @(kVK_F5): _SRUnicharToString(NSF5FunctionKey),
            @(kVK_F6): _SRUnicharToString(NSF6FunctionKey),
            @(kVK_F7): _SRUnicharToString(NSF7FunctionKey),
            @(kVK_F8): _SRUnicharToString(NSF8FunctionKey),
            @(kVK_F9): _SRUnicharToString(NSF9FunctionKey),
            @(kVK_F10): _SRUnicharToString(NSF10FunctionKey),
            @(kVK_F11): _SRUnicharToString(NSF11FunctionKey),
            @(kVK_F12): _SRUnicharToString(NSF12FunctionKey),
            @(kVK_F13): _SRUnicharToString(NSF13FunctionKey),
            @(kVK_F14): _SRUnicharToString(NSF14FunctionKey),
            @(kVK_F15): _SRUnicharToString(NSF15FunctionKey),
            @(kVK_F16): _SRUnicharToString(NSF16FunctionKey),
            @(kVK_F17): _SRUnicharToString(NSF17FunctionKey),
            @(kVK_F18): _SRUnicharToString(NSF18FunctionKey),
            @(kVK_F19): _SRUnicharToString(NSF19FunctionKey),
            @(kVK_F20): _SRUnicharToString(NSF20FunctionKey),
            @(kVK_Space): _SRUnicharToString(' '),
            @(kVK_Delete): _SRUnicharToString(NSBackspaceCharacter),
            @(kVK_ForwardDelete): _SRUnicharToString(NSDeleteCharacter),
            @(kVK_ANSI_KeypadClear): _SRUnicharToString(NSClearLineFunctionKey),
            @(kVK_LeftArrow): _SRUnicharToString(NSLeftArrowFunctionKey),
            @(kVK_RightArrow): _SRUnicharToString(NSRightArrowFunctionKey),
            @(kVK_UpArrow): _SRUnicharToString(NSUpArrowFunctionKey),
            @(kVK_DownArrow): _SRUnicharToString(NSDownArrowFunctionKey),
            @(kVK_End): _SRUnicharToString(NSEndFunctionKey),
            @(kVK_Home): _SRUnicharToString(NSHomeFunctionKey),
            @(kVK_Escape): _SRUnicharToString('\e'),
            @(kVK_PageDown): _SRUnicharToString(NSPageDownFunctionKey),
            @(kVK_PageUp): _SRUnicharToString(NSPageUpFunctionKey),
            @(kVK_Return): _SRUnicharToString(NSCarriageReturnCharacter),
            @(kVK_ANSI_KeypadEnter): _SRUnicharToString(NSEnterCharacter),
            @(kVK_Tab): _SRUnicharToString(NSTabCharacter),
            @(kVK_Help): _SRUnicharToString(NSHelpFunctionKey)
        };
    });
    return Mapping;
}

+ (NSDictionary<NSNumber *, NSString *> *)specialKeyCodeToLiteralMapping
{
    static NSDictionary *Mapping = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Mapping = @{
            @(kVK_F1): @"F1",
            @(kVK_F2): @"F2",
            @(kVK_F3): @"F3",
            @(kVK_F4): @"F4",
            @(kVK_F5): @"F5",
            @(kVK_F6): @"F6",
            @(kVK_F7): @"F7",
            @(kVK_F8): @"F8",
            @(kVK_F9): @"F9",
            @(kVK_F10): @"F10",
            @(kVK_F11): @"F11",
            @(kVK_F12): @"F12",
            @(kVK_F13): @"F13",
            @(kVK_F14): @"F14",
            @(kVK_F15): @"F15",
            @(kVK_F16): @"F16",
            @(kVK_F17): @"F17",
            @(kVK_F18): @"F18",
            @(kVK_F19): @"F19",
            @(kVK_F20): @"F20",
            @(kVK_Space): SRLoc(@"Space"),
            @(kVK_Delete): SRKeyCodeStringDeleteLeft,
            @(kVK_ForwardDelete): SRKeyCodeStringDeleteRight,
            @(kVK_ANSI_KeypadClear): SRKeyCodeStringPadClear,
            @(kVK_LeftArrow): SRKeyCodeStringLeftArrow,
            @(kVK_RightArrow): SRKeyCodeStringRightArrow,
            @(kVK_UpArrow): SRKeyCodeStringUpArrow,
            @(kVK_DownArrow): SRKeyCodeStringDownArrow,
            @(kVK_End): SRKeyCodeStringSoutheastArrow,
            @(kVK_Home): SRKeyCodeStringNorthwestArrow,
            @(kVK_Escape): SRKeyCodeStringEscape,
            @(kVK_PageDown): SRKeyCodeStringPageDown,
            @(kVK_PageUp): SRKeyCodeStringPageUp,
            @(kVK_Return): SRKeyCodeStringReturnR2L,
            @(kVK_ANSI_KeypadEnter): SRKeyCodeStringReturn,
            @(kVK_Tab): SRKeyCodeStringTabRight,
            @(kVK_Help): @"?⃝"
        };
    });
    return Mapping;
}

- (instancetype)initWithASCIICapableKeyboardInputSource:(BOOL)aUsesASCII plainStrings:(BOOL)aUsesPlainStrings
{
    if (aUsesASCII && aUsesPlainStrings)
        return SRASCIILiteralKeyCodeTransformer.sharedTransformer;
    else if (aUsesASCII)
        return SRASCIISymbolicKeyCodeTransformer.sharedTransformer;
    else if (aUsesPlainStrings)
        return SRLiteralKeyCodeTransformer.sharedTransformer;
    else
        return SRSymbolicKeyCodeTransformer.sharedTransformer;
}

- (BOOL)usesASCIICapableKeyboardInputSource
{
    return [self isKindOfClass:SRASCIILiteralKeyCodeTransformer.class] || [self isKindOfClass:SRASCIISymbolicKeyCodeTransformer.class];
}

- (BOOL)usesPlainStrings
{
    return [self isKindOfClass:SRLiteralKeyCodeTransformer.class] || [self isKindOfClass:SRASCIILiteralKeyCodeTransformer.class];
}

- (NSString *)transformedValue:(NSNumber *)aValue withModifierFlags:(NSNumber *)aModifierFlags
{
    return [self transformedValue:aValue
        withImplicitModifierFlags:aModifierFlags
            explicitModifierFlags:nil
                  layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
}

- (NSString *)transformedValue:(NSNumber *)aValue
     withImplicitModifierFlags:(NSNumber *)anImplicitModifierFlags
         explicitModifierFlags:(NSNumber *)anExplicitModifierFlags
{
    return [self transformedValue:aValue
        withImplicitModifierFlags:anImplicitModifierFlags
            explicitModifierFlags:anExplicitModifierFlags
                  layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
}

- (NSString *)transformedSpecialKeyCode:(NSNumber *)aKeyCode
              withExplicitModifierFlags:(NSNumber *)anExplicitModifierFlags
{
    return [self transformedValue:aKeyCode
        withImplicitModifierFlags:nil
            explicitModifierFlags:anExplicitModifierFlags
                  layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
}

- (BOOL)isKeyCodeSpecial:(unsigned short)aKeyCode
{
    return self.class.specialKeyCodeToSymbolMapping[@(aKeyCode)] != nil;
}

#pragma clang diagnostic pop

#pragma mark NSValueTransformer

+ (Class)transformedValueClass;
{
    return [NSString class];
}

- (NSString *)transformedValue:(id)aValue
{
    if ([aValue isKindOfClass:SRShortcut.class])
    {
        return [self transformedValue:@([(SRShortcut *)aValue keyCode])
            withImplicitModifierFlags:nil
                explicitModifierFlags:@([(SRShortcut *)aValue modifierFlags])
                      layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
    }
    else
    {
        return [self transformedValue:aValue
            withImplicitModifierFlags:nil
                explicitModifierFlags:nil
                      layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
    }
}

@end


@implementation SRLiteralKeyCodeTransformer

+ (SRLiteralKeyCodeTransformer *)sharedTransformer
{
    static SRLiteralKeyCodeTransformer *Transformer = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Transformer = [SRLiteralKeyCodeTransformer new];
    });
    return Transformer;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _translator = _SRKeyCodeTranslator.shared;
    }

    return self;
}

- (NSString *)transformedValue:(NSNumber *)aValue
     withImplicitModifierFlags:(NSNumber *)anImplicitModifierFlags
         explicitModifierFlags:(NSNumber *)anExplicitModifierFlags
               layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    __block NSString *result = nil;
    os_activity_initiate("Key Code -> Literal", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (![aValue isKindOfClass:NSNumber.class])
        {
            os_trace_error("#Error Invalid key code");
            return;
        }

        result = [self literalForKeyCode:aValue.unsignedShortValue
               withImplicitModifierFlags:anImplicitModifierFlags.unsignedIntegerValue
                   explicitModifierFlags:anExplicitModifierFlags.unsignedIntegerValue
                         layoutDirection:aDirection];
    });

    return result;
}

@end


@implementation SRSymbolicKeyCodeTransformer

+ (SRSymbolicKeyCodeTransformer *)sharedTransformer
{
    static SRSymbolicKeyCodeTransformer *Transformer = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Transformer = [SRSymbolicKeyCodeTransformer new];
    });
    return Transformer;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _translator = _SRKeyCodeTranslator.shared;
    }

    return self;
}

- (NSString *)transformedValue:(NSNumber *)aValue
     withImplicitModifierFlags:(NSNumber *)anImplicitModifierFlags
         explicitModifierFlags:(NSNumber *)anExplicitModifierFlags
               layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    __block NSString *result = nil;
    os_activity_initiate("Key Code -> Symbol", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (![aValue isKindOfClass:NSNumber.class])
        {
            os_trace_error("#Error Invalid key code");
            return;
        }

        result = [self symbolForKeyCode:aValue.unsignedShortValue
              withImplicitModifierFlags:anImplicitModifierFlags.unsignedIntegerValue
                  explicitModifierFlags:anExplicitModifierFlags.unsignedIntegerValue
                        layoutDirection:aDirection];
    });

    return result;
}

@end


@implementation SRASCIILiteralKeyCodeTransformer

+ (SRASCIILiteralKeyCodeTransformer *)sharedTransformer
{
    static SRASCIILiteralKeyCodeTransformer *Transformer = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Transformer = [SRASCIILiteralKeyCodeTransformer new];
    });
    return Transformer;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _translator = _SRKeyCodeASCIITranslator.shared;
    }

    return self;
}

- (NSString *)transformedValue:(NSNumber *)aValue
     withImplicitModifierFlags:(NSNumber *)anImplicitModifierFlags
         explicitModifierFlags:(NSNumber *)anExplicitModifierFlags
               layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    __block NSString *result = nil;
    os_activity_initiate("Key Code -> ASCII Literal", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (![aValue isKindOfClass:NSNumber.class])
        {
            os_trace_error("#Error Invalid key code");
            return;
        }

        result = [self literalForKeyCode:aValue.unsignedShortValue
               withImplicitModifierFlags:anImplicitModifierFlags.unsignedIntegerValue
                   explicitModifierFlags:anExplicitModifierFlags.unsignedIntegerValue
                         layoutDirection:aDirection];
    });

    return result;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (NSNumber *)reverseTransformedValue:(NSString *)aValue
{
    __block NSNumber *result = nil;
    os_activity_initiate("ASCII Literal -> Key Code", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (![aValue isKindOfClass:NSString.class] || !aValue.length)
        {
            os_trace_error("#Error Invalid literal");
            return;
        }

        NSString *value = aValue.lowercaseString;

        if (value.length == 1)
        {
            unichar glyph = [value characterAtIndex:0];

            switch (glyph)
            {
                case SRKeyCodeGlyphTabRight:
                case SRKeyCodeGlyphTabLeft:
                    result = @(kVK_Tab);
                    break;
                case SRKeyCodeGlyphReturn:
                    result = @(kVK_ANSI_KeypadEnter);
                    break;
                case SRKeyCodeGlyphReturnR2L:
                    result = @(kVK_Return);
                    break;
                case SRKeyCodeGlyphDeleteLeft:
                    result = @(kVK_Delete);
                    break;
                case SRKeyCodeGlyphDeleteRight:
                    result = @(kVK_ForwardDelete);
                    break;
                case SRKeyCodeGlyphPadClear:
                    result = @(kVK_ANSI_KeypadClear);
                    break;
                case SRKeyCodeGlyphLeftArrow:
                    result = @(kVK_LeftArrow);
                    break;
                case SRKeyCodeGlyphRightArrow:
                    result = @(kVK_RightArrow);
                    break;
                case SRKeyCodeGlyphUpArrow:
                    result = @(kVK_UpArrow);
                    break;
                case SRKeyCodeGlyphDownArrow:
                    result = @(kVK_DownArrow);
                    break;
                case SRKeyCodeGlyphPageDown:
                    result = @(kVK_PageDown);
                    break;
                case SRKeyCodeGlyphPageUp:
                    result = @(kVK_PageUp);
                    break;
                case SRKeyCodeGlyphNorthwestArrow:
                    result = @(kVK_Home);
                    break;
                case SRKeyCodeGlyphSoutheastArrow:
                    result = @(kVK_End);
                    break;
                case SRKeyCodeGlyphEscape:
                    result = @(kVK_Escape);
                    break;
                case SRKeyCodeGlyphSpace:
                    result = @(kVK_Space);
                    break;
                default:
                    break;
            }
        }
        else if ((value.length == 2 || value.length == 3) & [value hasPrefix:@"f"])
        {
            NSInteger fNumber = [value substringFromIndex:1].integerValue;
            if (fNumber > 0 && ((value.length == 2 && fNumber < 10) || (value.length == 3 && fNumber >= 10)))
            {
                switch (fNumber)
                {
                    case 1:
                        result = @(kVK_F1);
                        break;
                    case 2:
                        result = @(kVK_F2);
                        break;
                    case 3:
                        result = @(kVK_F3);
                        break;
                    case 4:
                        result = @(kVK_F4);
                        break;
                    case 5:
                        result = @(kVK_F5);
                        break;
                    case 6:
                        result = @(kVK_F6);
                        break;
                    case 7:
                        result = @(kVK_F7);
                        break;
                    case 8:
                        result = @(kVK_F8);
                        break;
                    case 9:
                        result = @(kVK_F9);
                        break;
                    case 10:
                        result = @(kVK_F10);
                        break;
                    case 11:
                        result = @(kVK_F11);
                        break;
                    case 12:
                        result = @(kVK_F12);
                        break;
                    case 13:
                        result = @(kVK_F13);
                        break;
                    case 14:
                        result = @(kVK_F14);
                        break;
                    case 15:
                        result = @(kVK_F15);
                        break;
                    case 16:
                        result = @(kVK_F16);
                        break;
                    case 17:
                        result = @(kVK_F17);
                        break;
                    case 18:
                        result = @(kVK_F18);
                        break;
                    case 19:
                        result = @(kVK_F19);
                        break;
                    case 20:
                        result = @(kVK_F20);
                        break;
                    default:
                        break;
                }
            }
        }
        else
        {
            if ([aValue caseInsensitiveCompare:SRLoc(@"Space")] == NSOrderedSame ||
                [value isEqualToString:@"space"] ||
                [value isEqualToString:@" "])
            {
                result = @(kVK_Space);
            }
            else if ([value isEqualToString:@"esc"] || [value isEqualToString:@"escape"])
                result = @(kVK_Escape);
            else if ([value isEqualToString:@"tab"])
                result = @(kVK_Tab);
            else if ([value isEqualToString:@"help"] || [value isEqualToString:@"?⃝"])
                result = @(kVK_Help);
        }

        if (result == nil)
            result = [(_SRKeyCodeASCIITranslator *)self->_translator keyCodeForTranslation:value];
    });

    if (!result)
    {
        os_trace_error("#Error Invalid value for reverse transformation");
    }

    return result;
}

@end


@implementation SRASCIISymbolicKeyCodeTransformer

+ (SRASCIISymbolicKeyCodeTransformer *)sharedTransformer
{
    static SRASCIISymbolicKeyCodeTransformer *Transformer = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        Transformer = [SRASCIISymbolicKeyCodeTransformer new];
    });
    return Transformer;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _translator = _SRKeyCodeASCIITranslator.shared;
    }

    return self;
}

- (NSString *)transformedValue:(NSNumber *)aValue
     withImplicitModifierFlags:(NSNumber *)anImplicitModifierFlags
         explicitModifierFlags:(NSNumber *)anExplicitModifierFlags
               layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    __block NSString *result = nil;
    os_activity_initiate("Key Code -> ASCII Symbol", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (![aValue isKindOfClass:NSNumber.class])
        {
            os_trace_error("#Error Invalid key code");
            return;
        }

        result = [self symbolForKeyCode:aValue.unsignedShortValue
              withImplicitModifierFlags:anImplicitModifierFlags.unsignedIntegerValue
                  explicitModifierFlags:anExplicitModifierFlags.unsignedIntegerValue
                        layoutDirection:aDirection];
    });

    return result;
}

@end
