//
//  SRModifierFlagsTransformer.h
//  ShortcutRecorder
//
//  Copyright 2006-2018 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

/*!
    Transform Cocoa modifier flags into a string of unicode characters.
 */
NS_SWIFT_NAME(ModifierFlagsTransformer)
@interface SRModifierFlagsTransformer : NSValueTransformer

/*!
    Shared symbolic transformer.
 */
@property (class, readonly) SRModifierFlagsTransformer *sharedSymbolicTransformer;

/*!
    Shared literal transformer.
 */
@property (class, readonly) SRModifierFlagsTransformer *sharedLiteralTransformer;

- (instancetype)init:(BOOL)aIsLiteral NS_DESIGNATED_INITIALIZER;

/*!
    Whether modifier flags are transformed into unicode characters or literal strings.
 */
@property (readonly) BOOL isLiteral;

@end


@interface SRModifierFlagsTransformer (Deprecated)

+ (instancetype)sharedTransformer __attribute__((deprecated("", "sharedSymbolicTransformer")));
+ (instancetype)sharedPlainTransformer __attribute__((deprecated("", "sharedLiteralTransformer")));

- (instancetype)initWithPlainStrings:(BOOL)aUsesPlainStrings __attribute__((deprecated("", "initWithPlainStrings:")));

@property (readonly, getter=isLiteral) BOOL usesPlainStrings __attribute__((deprecated("", "isLiteral")));

@end


NS_ASSUME_NONNULL_END
