//
//  Copyright 2012 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <os/trace.h>

#import "SRModifierFlagsTransformer.h"
#import "SRCommon.h"


@implementation SRModifierFlagsTransformer

- (id)init
{
    if (self.class == SRModifierFlagsTransformer.class)
        return (id)SRSymbolicModifierFlagsTransformer.sharedTransformer;
    else
        return [super init];
}

+ (id)sharedTransformer
{
    return SRSymbolicModifierFlagsTransformer.sharedTransformer;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (id)sharedPlainTransformer
{
    return SRLiteralModifierFlagsTransformer.sharedTransformer;
}

- (id)initWithPlainStrings:(BOOL)aUsesPlainStrings
{
    if (aUsesPlainStrings)
        return (id)SRLiteralModifierFlagsTransformer.sharedTransformer;
    else
        return (id)SRSymbolicModifierFlagsTransformer.sharedTransformer;
}

- (BOOL)usesPlainStrings
{
    return [self isKindOfClass:SRSymbolicModifierFlagsTransformer.class];
}

#pragma clang diagnostic pop

+ (Class)transformedValueClass
{
    return NSString.class;
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (NSString *)transformedValue:(NSNumber *)aValue layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    return nil;
}

- (id)transformedValue:(id)aValue
{
    return [self transformedValue:aValue layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
}

@end


@implementation SRLiteralModifierFlagsTransformer

+ (SRLiteralModifierFlagsTransformer *)sharedTransformer
{
    static dispatch_once_t OnceToken;
    static SRLiteralModifierFlagsTransformer *Transformer = nil;
    dispatch_once(&OnceToken, ^{
        Transformer = [SRLiteralModifierFlagsTransformer new];
    });
    return Transformer;
}

#pragma mark NSValueTransformer

- (NSString *)transformedValue:(NSNumber *)aValue layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    if (![aValue isKindOfClass:NSNumber.class])
    {
        os_trace_error("#Error Invalid value for transformation");
        return nil;
    }

    NSEventModifierFlags flags = aValue.unsignedIntegerValue;
    NSMutableArray<NSString *> *flagsStringComponents = NSMutableArray.array;

    if (flags & NSControlKeyMask)
        [flagsStringComponents addObject:SRLoc(@"Control")];

    if (flags & NSAlternateKeyMask)
        [flagsStringComponents addObject:SRLoc(@"Option")];

    if (flags & NSShiftKeyMask)
        [flagsStringComponents addObject:SRLoc(@"Shift")];

    if (flags & NSCommandKeyMask)
        [flagsStringComponents addObject:SRLoc(@"Command")];

    if (aDirection == NSUserInterfaceLayoutDirectionRightToLeft)
        return [[[flagsStringComponents reverseObjectEnumerator] allObjects] componentsJoinedByString:@"-"];
    else
        return [flagsStringComponents componentsJoinedByString:@"-"];
}

@end


@implementation SRSymbolicModifierFlagsTransformer

+ (SRSymbolicModifierFlagsTransformer *)sharedTransformer
{
    static dispatch_once_t OnceToken;
    static SRSymbolicModifierFlagsTransformer *Transformer = nil;
    dispatch_once(&OnceToken, ^{
        Transformer = [SRSymbolicModifierFlagsTransformer new];
    });
    return Transformer;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (NSString *)transformedValue:(NSNumber *)aValue layoutDirection:(NSUserInterfaceLayoutDirection)aDirection
{
    if (![aValue isKindOfClass:NSNumber.class])
    {
        os_trace_error("#Error Invalid value for transformation");
        return nil;
    }

    NSEventModifierFlags flags = aValue.unsignedIntegerValue;
    NSMutableArray<NSString *> *flagsStringFragments = NSMutableArray.array;

    if (flags & NSControlKeyMask)
        [flagsStringFragments addObject:SRModifierFlagStringControl];

    if (flags & NSAlternateKeyMask)
        [flagsStringFragments addObject:SRModifierFlagStringOption];

    if (flags & NSShiftKeyMask)
        [flagsStringFragments addObject:SRModifierFlagStringShift];

    if (flags & NSCommandKeyMask)
        [flagsStringFragments addObject:SRModifierFlagStringCommand];

    if (aDirection == NSUserInterfaceLayoutDirectionRightToLeft)
        return [[[flagsStringFragments reverseObjectEnumerator] allObjects] componentsJoinedByString:@""];
    else
        return [flagsStringFragments componentsJoinedByString:@""];
}

- (NSNumber *)reverseTransformedValue:(NSString *)aValue
{
    if (![aValue isKindOfClass:NSString.class])
    {
        os_trace_error("#Error Invalid value for reverse transformation");
        return nil;
    }

    __block NSEventModifierFlags flags = 0;
    __block BOOL foundInvalidSubstring = NO;

    [aValue enumerateSubstringsInRange:NSMakeRange(0, aValue.length)
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
    {
        if ([substring isEqualToString:SRModifierFlagStringControl] && (flags & NSControlKeyMask) == 0)
            flags |= NSControlKeyMask;
        else if ([substring isEqualToString:SRModifierFlagStringOption] && (flags & NSAlternateKeyMask) == 0)
            flags |= NSAlternateKeyMask;
        else if ([substring isEqualToString:SRModifierFlagStringShift] && (flags & NSShiftKeyMask) == 0)
            flags |= NSShiftKeyMask;
        else if ([substring isEqualToString:SRModifierFlagStringCommand] && (flags & NSCommandKeyMask) == 0)
            flags |= NSCommandKeyMask;
        else
        {
            foundInvalidSubstring = YES;
            *stop = YES;
        }
    }];

    if (foundInvalidSubstring)
    {
        os_trace_error("#Error Invalid value for reverse transformation");
        return nil;
    }

    return @(flags);
}

@end
