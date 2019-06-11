//
//  Copyright 2012 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Foundation/Foundation.h>


/*!
 Transform a shortcut or its dictionary representation into Cocoa's key equivalent modifier mask
 for objects like NSButton and NSMenuItem.
 */
NS_SWIFT_NAME(KeyEquivalentModifierMaskTransformer)
@interface SRKeyEquivalentModifierMaskTransformer : NSValueTransformer

/*!
 Shared transformer.
 */
@property (class, readonly) SRKeyEquivalentModifierMaskTransformer *sharedTransformer NS_SWIFT_NAME(shared);;

@end
