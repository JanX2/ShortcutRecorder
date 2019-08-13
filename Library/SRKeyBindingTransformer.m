//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <os/trace.h>

#import "SRKeyBindingTransformer.h"
#import "SRKeyCodeTransformer.h"


@implementation SRKeyBindingTransformer

#pragma mark Methods

+ (instancetype)sharedTransformer
{
    static dispatch_once_t OnceToken;
    static SRKeyBindingTransformer *Transformer = nil;
    dispatch_once(&OnceToken, ^{
        Transformer = [SRKeyBindingTransformer new];
    });
    return Transformer;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass
{
    return NSString.class;
}

- (SRShortcut *)transformedValue:(NSString *)aValue
{
    if (![aValue isKindOfClass:NSString.class] || !aValue.length)
        return nil;

    static NSCharacterSet *FlagsCharacters = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        FlagsCharacters = [NSCharacterSet characterSetWithCharactersInString:@"^~$@#"];
    });

    NSScanner *parser = [NSScanner scannerWithString:aValue];
    parser.caseSensitive = NO;

    NSString *modifierFlagsString = nil;
    [parser scanCharactersFromSet:FlagsCharacters intoString:&modifierFlagsString];
    NSString *keyCodeString = [aValue substringFromIndex:parser.scanLocation];

    if (keyCodeString.length != 1)
    {
        os_trace_error("#Error unexpected key symbol");
        return nil;
    }

    NSEventModifierFlags modifierFlags = 0;

    if ([modifierFlagsString containsString:@"^"])
        modifierFlags |= NSEventModifierFlagControl;

    if ([modifierFlagsString containsString:@"~"])
        modifierFlags |= NSEventModifierFlagOption;

    if ([modifierFlagsString containsString:@"$"] || ![keyCodeString.lowercaseString isEqualToString:keyCodeString])
        modifierFlags |= NSEventModifierFlagShift;

    if ([modifierFlagsString containsString:@"@"])
        modifierFlags |= NSEventModifierFlagCommand;

    keyCodeString = keyCodeString.lowercaseString;
    NSNumber *keyCode = [SRASCIISymbolicKeyCodeTransformer.sharedTransformer reverseTransformedValue:keyCodeString];

    if (!keyCode)
    {
        os_trace_error("#Error unexpected key symbol");
        return nil;
    }

    BOOL isNumPad = [modifierFlagsString containsString:@"#"];
    if (isNumPad)
    {
        switch (keyCode.unsignedShortValue) {
            case kVK_ANSI_0:
                keyCode = @(kVK_ANSI_Keypad0);
                break;
            case kVK_ANSI_1:
                keyCode = @(kVK_ANSI_Keypad1);
                break;
            case kVK_ANSI_2:
                keyCode = @(kVK_ANSI_Keypad2);
                break;
            case kVK_ANSI_3:
                keyCode = @(kVK_ANSI_Keypad3);
                break;
            case kVK_ANSI_4:
                keyCode = @(kVK_ANSI_Keypad4);
                break;
            case kVK_ANSI_5:
                keyCode = @(kVK_ANSI_Keypad5);
                break;
            case kVK_ANSI_6:
                keyCode = @(kVK_ANSI_Keypad6);
                break;
            case kVK_ANSI_7:
                keyCode = @(kVK_ANSI_Keypad7);
                break;
            case kVK_ANSI_8:
                keyCode = @(kVK_ANSI_Keypad8);
                break;
            case kVK_ANSI_9:
                keyCode = @(kVK_ANSI_Keypad9);
                break;
            case kVK_ANSI_Minus:
                keyCode = @(kVK_ANSI_KeypadMinus);
                break;
            case kVK_ANSI_Equal:
                keyCode = @(kVK_ANSI_KeypadEquals);
                break;
            default:
                break;
        }
    }

    NSString *characters = [SRASCIISymbolicKeyCodeTransformer.sharedTransformer transformedValue:keyCode
                                                                       withImplicitModifierFlags:@(modifierFlags)
                                                                           explicitModifierFlags:nil
                                                                                 layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
    NSString *charactersIgnoringModifiers = [SRASCIISymbolicKeyCodeTransformer.sharedTransformer transformedValue:keyCode
                                                                                        withImplicitModifierFlags:nil
                                                                                            explicitModifierFlags:@(modifierFlags)
                                                                                                  layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];

    return [SRShortcut shortcutWithCode:keyCode.unsignedShortValue
                          modifierFlags:modifierFlags
                             characters:characters
            charactersIgnoringModifiers:charactersIgnoringModifiers];
}

- (NSString *)reverseTransformedValue:(SRShortcut *)aValue
{
    if (![aValue isKindOfClass:NSDictionary.class] && ![aValue isKindOfClass:SRShortcut.class])
    {
        os_trace_error("#Error invalid class of the value");
        return nil;
    }

    NSNumber *keyCode = aValue[SRShortcutKeyKeyCode];
    if (![keyCode isKindOfClass:NSNumber.class])
    {
        os_trace_error("#Error invalid key code");
        return nil;
    }

    NSString *keyCodeSymbol = [SRASCIISymbolicKeyCodeTransformer.sharedTransformer transformedValue:keyCode];

    if (!keyCodeSymbol)
    {
        os_trace_error("#Error unexpected key code");
        return nil;
    }

    NSNumber *modifierFlags = aValue[SRShortcutKeyModifierFlags];

    if (![modifierFlags isKindOfClass:NSNumber.class])
        modifierFlags = @(0);

    unsigned short keyCodeValue = keyCode.unsignedShortValue;
    NSEventModifierFlags modifierFlagsValue = modifierFlags.unsignedIntegerValue;

    BOOL isNumPad = NO;
    switch (keyCodeValue)
    {
        case kVK_ANSI_Keypad0:
        case kVK_ANSI_Keypad1:
        case kVK_ANSI_Keypad2:
        case kVK_ANSI_Keypad3:
        case kVK_ANSI_Keypad4:
        case kVK_ANSI_Keypad5:
        case kVK_ANSI_Keypad6:
        case kVK_ANSI_Keypad7:
        case kVK_ANSI_Keypad8:
        case kVK_ANSI_Keypad9:
        case kVK_ANSI_KeypadDecimal:
        case kVK_ANSI_KeypadMultiply:
        case kVK_ANSI_KeypadPlus:
        case kVK_ANSI_KeypadClear:
        case kVK_ANSI_KeypadDivide:
        case kVK_ANSI_KeypadEnter:
        case kVK_ANSI_KeypadMinus:
        case kVK_ANSI_KeypadEquals:
            isNumPad = YES;
        default:
            break;
    }

    NSMutableString *keyBinding = [NSMutableString new];

    if (modifierFlagsValue & NSEventModifierFlagControl)
        [keyBinding appendString:@"^"];

    if (modifierFlagsValue & NSEventModifierFlagOption)
        [keyBinding appendString:@"~"];

    if (modifierFlagsValue & NSEventModifierFlagShift)
        [keyBinding appendString:@"$"];

    if (modifierFlagsValue & NSEventModifierFlagCommand)
        [keyBinding appendString:@"@"];

    if (isNumPad)
        [keyBinding appendString:@"#"];

    [keyBinding appendString:keyCodeSymbol];

    return [keyBinding copy];
}

@end
