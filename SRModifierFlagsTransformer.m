//
//  SRModifierFlagsTransformer.m
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import "SRModifierFlagsTransformer.h"


@implementation SRModifierFlagsTransformer

+ (instancetype)sharedTransformer
{
    static dispatch_once_t OnceToken;
    static SRModifierFlagsTransformer *Transfomer = nil;
    dispatch_once(&OnceToken, ^{
        Transfomer = [[self alloc] init];
    });
    return Transfomer;
}

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
        return nil;
    else
    {
        NSUInteger f = [aValue unsignedIntegerValue];
        return [NSString stringWithFormat:@"%@%@%@%@",
                (f & NSControlKeyMask ? [NSString stringWithFormat:@"%C", (unsigned short)kControlUnicode] : @""),
                (f & NSAlternateKeyMask ? [NSString stringWithFormat:@"%C", (unsigned short)kOptionUnicode] : @""),
                (f & NSShiftKeyMask ? [NSString stringWithFormat:@"%C", (unsigned short)kShiftUnicode] : @""),
                (f & NSCommandKeyMask ? [NSString stringWithFormat:@"%C", (unsigned short)kCommandUnicode] : @"")];
    }
}

@end
