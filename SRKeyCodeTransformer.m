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

+ (instancetype)sharedTransformer
{
    static dispatch_once_t onceToken;
    static SRKeyCodeTransformer *t = nil;
    dispatch_once(&onceToken, ^{
        t = [[self alloc] initWithASCIICapableKeyboardInputSource:NO
                                                     plainStrings:NO];
    });
    return t;
}

+ (instancetype)sharedASCIITransformer
{
    static dispatch_once_t onceToken;
    static SRKeyCodeTransformer *t = nil;
    dispatch_once(&onceToken, ^{
        t = [[self alloc] initWithASCIICapableKeyboardInputSource:YES
                                                     plainStrings:NO];
    });
    return t;
}

+ (instancetype)sharedPlainTransformer
{
    static dispatch_once_t onceToken;
    static SRKeyCodeTransformer *t = nil;
    dispatch_once(&onceToken, ^{
        t = [[self alloc] initWithASCIICapableKeyboardInputSource:NO
                                                     plainStrings:YES];
    });
    return t;
}

+ (SRKeyCodeTransformer *)sharedPlainASCIITransformer
{
    static dispatch_once_t onceToken;
    static SRKeyCodeTransformer *t = nil;
    dispatch_once(&onceToken, ^{
        t = [[self alloc] initWithASCIICapableKeyboardInputSource:YES
                                                     plainStrings:YES];
    });
    return t;
}

- (instancetype)init
{
    return [self initWithASCIICapableKeyboardInputSource:NO plainStrings:NO];
}

- (instancetype)initWithASCIICapableKeyboardInputSource:(BOOL)aUsesASCII plainStrings:(BOOL)aUsesPlainStrings
{
    self = [super init];
    
    if (self != nil)
    {
        _usesASCIICapableKeyboardInputSource = aUsesASCII;
        _usesPlainStrings = aUsesPlainStrings;
    }
    
    return self;
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Methods

+ (NSDictionary *)specialKeyCodesToUnicodeCharactersMapping
{
    static dispatch_once_t onceToken;
    static NSDictionary *d = nil;
    dispatch_once(&onceToken, ^{
        d = @{
            @(kSRKeysF1): SRChar(NSF1FunctionKey),
            @(kSRKeysF2): SRChar(NSF2FunctionKey),
            @(kSRKeysF3): SRChar(NSF3FunctionKey),
            @(kSRKeysF4): SRChar(NSF4FunctionKey),
            @(kSRKeysF5): SRChar(NSF5FunctionKey),
            @(kSRKeysF6): SRChar(NSF6FunctionKey),
            @(kSRKeysF7): SRChar(NSF7FunctionKey),
            @(kSRKeysF8): SRChar(NSF8FunctionKey),
            @(kSRKeysF9): SRChar(NSF9FunctionKey),
            @(kSRKeysF10): SRChar(NSF10FunctionKey),
            @(kSRKeysF11): SRChar(NSF11FunctionKey),
            @(kSRKeysF12): SRChar(NSF12FunctionKey),
            @(kSRKeysF13): SRChar(NSF13FunctionKey),
            @(kSRKeysF14): SRChar(NSF14FunctionKey),
            @(kSRKeysF15): SRChar(NSF15FunctionKey),
            @(kSRKeysF16): SRChar(NSF16FunctionKey),
            @(kSRKeysF17): SRChar(NSF17FunctionKey),
            @(kSRKeysF18): SRChar(NSF18FunctionKey),
            @(kSRKeysF19): SRChar(NSF19FunctionKey),
            @(kSRKeysSpace): SRChar(KeyboardSpaceGlyph),
            @(kSRKeysDeleteLeft): SRChar(KeyboardDeleteLeftGlyph),
            @(kSRKeysDeleteRight): SRChar(KeyboardDeleteRightGlyph),
            @(kSRKeysPadClear): SRChar(KeyboardPadClearGlyph),
            @(kSRKeysLeftArrow): SRChar(KeyboardLeftArrowGlyph),
            @(kSRKeysRightArrow): SRChar(KeyboardRightArrowGlyph),
            @(kSRKeysUpArrow): SRChar(KeyboardUpArrowGlyph),
            @(kSRKeysDownArrow): SRChar(KeyboardDownArrowGlyph),
            @(kSRKeysSoutheastArrow): SRChar(KeyboardSoutheastArrowGlyph),
            @(kSRKeysNorthwestArrow): SRChar(KeyboardNorthwestArrowGlyph),
            @(kSRKeysEscape): SRChar(KeyboardEscapeGlyph),
            @(kSRKeysPageDown): SRChar(KeyboardPageDownGlyph),
            @(kSRKeysPageUp): SRChar(KeyboardPageUpGlyph),
            @(kSRKeysReturnR2L): SRChar(KeyboardReturnR2LGlyph),
            @(kSRKeysReturn): SRChar(KeyboardReturnGlyph),
            @(kSRKeysTabRight): SRChar(KeyboardTabRightGlyph),
            @(kSRKeysHelp): SRChar(KeyboardHelpGlyph)
        };
    });
    return d;
}

+ (NSDictionary *)specialKeyCodesToPlainStringsMapping
{
    static dispatch_once_t onceToken;
    static NSDictionary *d = nil;
    dispatch_once(&onceToken, ^{
        d = @{
            @(kSRKeysF1): @"F1",
            @(kSRKeysF2): @"F2",
            @(kSRKeysF3): @"F3",
            @(kSRKeysF4): @"F4",
            @(kSRKeysF5): @"F5",
            @(kSRKeysF6): @"F6",
            @(kSRKeysF7): @"F7",
            @(kSRKeysF8): @"F8",
            @(kSRKeysF9): @"F9",
            @(kSRKeysF10): @"F10",
            @(kSRKeysF11): @"F11",
            @(kSRKeysF12): @"F12",
            @(kSRKeysF13): @"F13",
            @(kSRKeysF14): @"F14",
            @(kSRKeysF15): @"F15",
            @(kSRKeysF16): @"F16",
            @(kSRKeysF17): @"F17",
            @(kSRKeysF18): @"F18",
            @(kSRKeysF19): @"F18",
            @(kSRKeysSpace): SRChar(KeyboardSpaceGlyph),
            @(kSRKeysDeleteLeft): SRChar(KeyboardDeleteLeftGlyph),
            @(kSRKeysDeleteRight): SRChar(KeyboardDeleteRightGlyph),
            @(kSRKeysPadClear): SRChar(KeyboardPadClearGlyph),
            @(kSRKeysLeftArrow): SRChar(KeyboardLeftArrowGlyph),
            @(kSRKeysRightArrow): SRChar(KeyboardRightArrowGlyph),
            @(kSRKeysUpArrow): SRChar(KeyboardUpArrowGlyph),
            @(kSRKeysDownArrow): SRChar(KeyboardDownArrowGlyph),
            @(kSRKeysSoutheastArrow): SRChar(KeyboardSoutheastArrowGlyph),
            @(kSRKeysNorthwestArrow): SRChar(KeyboardNorthwestArrowGlyph),
            @(kSRKeysEscape): SRChar(KeyboardEscapeGlyph),
            @(kSRKeysPageDown): SRChar(KeyboardPageDownGlyph),
            @(kSRKeysPageUp): SRChar(KeyboardPageUpGlyph),
            @(kSRKeysReturnR2L): SRChar(KeyboardReturnR2LGlyph),
            @(kSRKeysReturn): SRChar(KeyboardReturnGlyph),
            @(kSRKeysTabRight): SRChar(KeyboardTabRightGlyph),
            @(kSRKeysHelp): SRChar(KeyboardHelpGlyph)
        };
    });
    return d;
}


#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass;
{
    return [NSString class];
}

- (NSString *)transformedValue:(NSNumber *)aValue
{
    if (![aValue isKindOfClass:[NSNumber class]])
        return nil;
    
    unsigned short keyCode = [aValue unsignedShortValue];

    // Some key codes cannot be translated directly.
    NSString *unmappedString = nil;
    
    if (self.usesPlainStrings)
        unmappedString = [[[self class] specialKeyCodesToPlainStringsMapping] objectForKey:@(keyCode)];
    else
        unmappedString = [[[self class] specialKeyCodesToUnicodeCharactersMapping] objectForKey:@(keyCode)];
    
    if (unmappedString != nil)
        return unmappedString;

    CFDataRef layoutData = NULL;
    
    if (self.usesASCIICapableKeyboardInputSource)
    {
        TISInputSourceRef tisSource = TISCopyCurrentASCIICapableKeyboardInputSource();
        
        if (tisSource == NULL)
            return nil;
        
        layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
        CFRelease(tisSource);
    }
    else
    {
        TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
        
        if (tisSource == NULL)
            return nil;
        
        layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
        CFRelease(tisSource);
        
        // For non-unicode layouts such as Chinese, Japanese, and Korean, get the ASCII capable layout
        if (layoutData == NULL)
        {
            tisSource = TISCopyCurrentASCIICapableKeyboardInputSource();
            
            if (tisSource == NULL)
                return nil;
            
            layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
            CFRelease(tisSource);
        }
    }

    if (layoutData == NULL)
        return nil;

    const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);

    static const UniCharCount MaxLength = 255;
    UniCharCount actualLength = 0;
    UniChar chars[MaxLength] = {0};

    UInt32 deadKeyState = 0;
    OSErr err = UCKeyTranslate(keyLayout,
                               keyCode,
                               kUCKeyActionDisplay,
                               0,
                               LMGetKbdType(),
                               kUCKeyTranslateNoDeadKeysBit,
                               &deadKeyState,
                               sizeof(chars) / sizeof(UniChar),
                               &actualLength,
                               chars);
    if (err != noErr)
        return nil;

    return [NSString stringWithCharacters:chars length:actualLength];
}

@end
