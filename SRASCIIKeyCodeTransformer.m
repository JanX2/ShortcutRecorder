//
//  SRKeyCodeTransformer.h
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import "SRASCIIKeyCodeTransformer.h"


@implementation SRASCIIKeyCodeTransformer

#pragma mark SRKeyCodeTransformer

+ (SRASCIIKeyCodeTransformer *)sharedTransformer
{
    static dispatch_once_t onceToken;
    static SRASCIIKeyCodeTransformer *sharedTransformer = nil;
    dispatch_once(&onceToken, ^
    {
        sharedTransformer = [[self alloc] init];
    });
    return sharedTransformer;
}

+ (SRASCIIKeyCodeTransformer *)sharedPlainTransformer
{
    static dispatch_once_t onceToken;
    static SRASCIIKeyCodeTransformer *sharedTransformer = nil;
    dispatch_once(&onceToken, ^
    {
        sharedTransformer = [[self alloc] init];
        sharedTransformer.transformsfunctionKeysToPlainStrings = YES;
    });
    return sharedTransformer;
}

+ (TISInputSourceRef)preferredKeyboardInputSource
{
    return [self ASCIICapableKeyboardInputSource];
}

@end
