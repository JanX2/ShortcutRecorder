//
//  Copyright 2012 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

@class SRLiteralModifierFlagsTransformer;

/*!
 Deprecated. Use SRLiteralModifierFlagsTransformer and SRSymbolicModifierFlagsTransformer instead.
 */
@interface SRModifierFlagsTransformer : NSValueTransformer
@property (class, readonly) SRModifierFlagsTransformer* sharedTransformer NS_SWIFT_NAME(shared);
+ (SRLiteralModifierFlagsTransformer *)sharedPlainTransformer __attribute__((deprecated("", "SRLiteralModifierFlagsTransformer.shared")));
- (instancetype)initWithPlainStrings:(BOOL)aUsesPlainStrings __attribute__((deprecated));
@property (readonly) BOOL usesPlainStrings __attribute__((deprecated));

/*!
 Order modifier flags according to the user interface layout direction of the view.

 @param aView View whose userInterfaceLayoutDirection is considered. If nil, NSApp's default is used.
 */
- (nullable NSString *)transformedValue:(NSNumber *)aValue forView:(nullable NSView *)aView;
@end


/*!
 Transform modifier flags into a univesal symbolic string such as ⌘⌥.

 @note Allows reverse transformation.
 */
NS_SWIFT_NAME(LiteralModifierFlagsTransformer)
@interface SRLiteralModifierFlagsTransformer: SRModifierFlagsTransformer
@end


/*!
 Transform modifier flags into a localized literal string such as Command-Option.

 @note Does not allow reverse transformation.
 */
NS_SWIFT_NAME(SymbolicModifierFlagsTransformer)
@interface SRSymbolicModifierFlagsTransformer: SRModifierFlagsTransformer
@end

NS_ASSUME_NONNULL_END
