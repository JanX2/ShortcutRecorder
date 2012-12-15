//
//  SRModifierFlagsTransformer.m
//  ShortcutRecorder
//
//  Created by Илья Кулаков on 14.12.12.
//
//

#import <Carbon/Carbon.h>
#import "SRModifierFlagsTransformer.h"


@implementation SRModifierFlagsTransformer

#pragma mark Methods

+ (instancetype)sharedTransformer
{
    static dispatch_once_t onceToken;
    static SRModifierFlagsTransformer *sharedTransformer = nil;
    dispatch_once(&onceToken, ^{
        sharedTransformer = [[self alloc] init];
    });
    return sharedTransformer;
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
