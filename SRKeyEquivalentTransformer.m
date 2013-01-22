//
//  SRKeyEquivalentTransformer.m
//  ShortcutRecorder
//
//  Copyright 2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import "SRKeyEquivalentTransformer.h"
#import "SRKeyCodeTransformer.h"
#import "SRRecorderControl.h"


@implementation SRKeyEquivalentTransformer

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [NSString class];
}

- (NSString *)transformedValue:(NSDictionary *)aValue
{
    if (![aValue isKindOfClass:[NSDictionary class]])
        return @"";

    NSNumber *keyCode = aValue[SRShortcutKeyCode];

    if (![keyCode isKindOfClass:[NSNumber class]])
        return @"";

    SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedASCIITransformer];

    if (![t isKeyCodeSpecial:[keyCode unsignedShortValue]])
        return [[t transformedValue:keyCode] uppercaseString];
    else
        return [t transformedValue:keyCode];
}

@end
