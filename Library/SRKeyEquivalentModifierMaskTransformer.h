//
//  Copyright 2012 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Foundation/Foundation.h>


/*!
 Transform dictionary representation of a shortcut into a string suitable
 for -setKeyEquivalentModifierMask: of Cocoa objects such as NSButton and NSMenuItem.
 */
NS_SWIFT_NAME(KeyEquivalentModifierMaskTransformer)
@interface SRKeyEquivalentModifierMaskTransformer : NSValueTransformer

/*!
 Shared transformer.
 */
@property (class, readonly) SRKeyEquivalentModifierMaskTransformer *sharedTransformer;

@end
