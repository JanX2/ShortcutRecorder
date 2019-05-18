//
//  SRModifierFlagsTransformer.m
//  ShortcutRecorder
//
//  Copyright 2006-2018 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import "SRModifierFlagsTransformer.h"
#import "SRCommon.h"


@implementation SRModifierFlagsTransformer

- (instancetype)init:(BOOL)aIsLiteral
{
    self = [super init];

    if (self)
    {
        _isLiteral = aIsLiteral;
    }

    return self;
}

- (instancetype)init
{
    return [self init:NO];
}


#pragma mark Methods

+ (instancetype)sharedSymbolicTransformer
{
    static dispatch_once_t OnceToken;
    static SRModifierFlagsTransformer *Transformer = nil;
    dispatch_once(&OnceToken, ^{
        Transformer = [[self alloc] init:NO];
    });
    return Transformer;
}

+ (instancetype)sharedLiteralTransformer
{
    static dispatch_once_t OnceToken;
    static SRModifierFlagsTransformer *Transformer = nil;
    dispatch_once(&OnceToken, ^{
        Transformer = [[self alloc] init:YES];
    });
    return Transformer;
}


#pragma mark Deprecated

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (instancetype)sharedTransformer
{
    return self.sharedSymbolicTransformer;
}

+ (instancetype)sharedPlainTransformer
{
    return self.sharedLiteralTransformer;
}

- (instancetype)initWithPlainStrings:(BOOL)aUsesPlainStrings
{
    return [self init:aUsesPlainStrings];
}

#pragma clang diagnostic pop


#pragma mark NSValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (NSString *)transformedValue:(NSNumber *)aValue
{
    if (![aValue isKindOfClass:[NSNumber class]])
        return [super transformedValue:aValue];
    else if (self.isLiteral)
    {
        NSEventModifierFlags modifierFlags = aValue.unsignedIntegerValue;
        NSMutableString *s = [NSMutableString string];

        if (modifierFlags & NSControlKeyMask)
            [s appendString:SRLoc(@"Control-")];

        if (modifierFlags & NSAlternateKeyMask)
            [s appendString:SRLoc(@"Option-")];

        if (modifierFlags & NSShiftKeyMask)
            [s appendString:SRLoc(@"Shift-")];

        if (modifierFlags & NSCommandKeyMask)
            [s appendString:SRLoc(@"Command-")];

        if (s.length > 0)
            [s deleteCharactersInRange:NSMakeRange(s.length - 1, 1)];

        return s;
    }
    else
    {
        NSEventModifierFlags f = aValue.unsignedIntegerValue;
        return [NSString stringWithFormat:@"%@%@%@%@",
                (f & NSControlKeyMask ? @"⌃" : @""),
                (f & NSAlternateKeyMask ? @"⌥" : @""),
                (f & NSShiftKeyMask ? @"⇧" : @""),
                (f & NSCommandKeyMask ? @"⌘" : @"")];
    }
}

@end
