//
//  Copyright 2012 ShortcutRecorder Contributors
//  CC BY 3.0
//

#import "SRModifierFlagsTransformer.h"
#import "SRCommon.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

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

+ (Class)transformedValueClass
{
    return NSString.class;
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (NSString *)transformedValue:(NSNumber *)aValue forView:(NSView *)aView
{
    return nil;
}

- (id)transformedValue:(id)value
{
    return nil;
}

@end

#pragma clang diagnostic pop


@implementation SRLiteralModifierFlagsTransformer

+ (SRLiteralModifierFlagsTransformer *)sharedTransformer
{
    static dispatch_once_t OnceToken;
    static SRLiteralModifierFlagsTransformer *Transformer = nil;
    dispatch_once(&OnceToken, ^{
        Transformer = [[self alloc] init];
    });
    return Transformer;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (NSString *)transformedValue:(NSNumber *)aValue
{
    return [self transformedValue:aValue forView:nil];
}

- (NSString *)transformedValue:(NSNumber *)aValue forView:(NSView *)aView
{
    if (![aValue isKindOfClass:NSNumber.class])
        return nil;

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

    __auto_type layoutDirection = aView ? aView.userInterfaceLayoutDirection : NSApp.userInterfaceLayoutDirection;

    if (layoutDirection == NSUserInterfaceLayoutDirectionRightToLeft)
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
        Transformer = [[self alloc] init];
    });
    return Transformer;
}

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (NSString *)transformedValue:(NSNumber *)aValue
{
    return [self transformedValue:aValue forView:nil];
}

- (NSString *)transformedValue:(NSNumber *)aValue forView:(NSView *)aView
{
    if (![aValue isKindOfClass:NSNumber.class])
        return nil;

    NSEventModifierFlags flags = aValue.unsignedIntegerValue;
    NSMutableArray<NSString *> *flagsStringFragments = NSMutableArray.array;

    if (flags & NSControlKeyMask)
        [flagsStringFragments addObject:@"⌃"];

    if (flags & NSAlternateKeyMask)
        [flagsStringFragments addObject:@"⌥"];

    if (flags & NSShiftKeyMask)
        [flagsStringFragments addObject:@"⇧"];

    if (flags & NSCommandKeyMask)
        [flagsStringFragments addObject:@"⌘"];

    __auto_type layoutDirection = aView ? aView.userInterfaceLayoutDirection : NSApp.userInterfaceLayoutDirection;

    if (layoutDirection == NSUserInterfaceLayoutDirectionRightToLeft)
        return [[[flagsStringFragments reverseObjectEnumerator] allObjects] componentsJoinedByString:@""];
    else
        return [flagsStringFragments componentsJoinedByString:@""];
}

- (NSNumber *)reverseTransformedValue:(NSString *)aValue
{
    if (![aValue isKindOfClass:NSString.class])
        return nil;

    __block NSEventModifierFlags flags = 0;
    __block BOOL foundInvalidSubstring = NO;

    [aValue enumerateSubstringsInRange:NSMakeRange(0, aValue.length)
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
    {
        if ([substring isEqualToString:@"⌃"] && (flags & NSControlKeyMask) == 0)
            flags |= NSControlKeyMask;
        else if ([substring isEqualToString:@"⌥"] && (flags & NSAlternateKeyMask) == 0)
            flags |= NSAlternateKeyMask;
        else if ([substring isEqualToString:@"⇧"] && (flags & NSShiftKeyMask) == 0)
            flags |= NSShiftKeyMask;
        else if ([substring isEqualToString:@"⌘"] && (flags & NSCommandKeyMask) == 0)
            flags |= NSCommandKeyMask;
        else
        {
            foundInvalidSubstring = YES;
            *stop = YES;
        }
    }];

    if (foundInvalidSubstring)
        return nil;

    return @(flags);
}

@end
