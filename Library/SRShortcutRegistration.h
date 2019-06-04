//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 3.0
//

#import <Foundation/Foundation.h>

#import <ShortcutRecorder/SRShortcut.h>


NS_ASSUME_NONNULL_BEGIN

@class SRShortcutRegistration;

/*!
 Action associated with the registered shortcut.

 @param aRegistration The registration that invoked the action.
 */
typedef void (^SRShortcutActionHandler)(SRShortcutRegistration *aRegistration) NS_SWIFT_NAME(SRShortcutRegistration.Action);

/*!
 Signature of a Carbon system-wide hot key.
 */
extern const OSType SRShortcutRegistrationSignature NS_SWIFT_NAME(SRShortcutRegistration.Signature);


/*!
 Registration of the system-wide shortcut.

 The registration aginst happens whenever valid value is set for the shortcut or observed object and key path.
 Changing these values automatically updates the registration.
 */
NS_SWIFT_NAME(ShortcutRegistration)
@interface SRShortcutRegistration : NSObject

/*!
 Shortcut associated with the registration
 */
@property (nullable) SRShortcut *shortcut;

/*!
 The object being observed for autoupdating shortcut.
 */
@property (nullable, weak, readonly) id observedObject;

/*!
 The key path being observed for autoupdating shortcut.
 */
@property (nullable, copy, readonly) NSString *observedKeyPath;

/*!
 The target to receive the -performShortcutActionForRegistration: when shortcut is performed.

 @discussion
 Setting the target resets the action handler to nil.
 */
@property (nullable, weak) IBOutlet id target;

/*!
 The action handler to execute when the shortcut is performed.

 @discussion
 Setting the handler resets the target to nil.
 */
@property (nullable) SRShortcutActionHandler actionHandler;

/*!
 Target dispatch queue for the action.

 @discussion:
 Defaults to the main queue.

 The action block is detached and submitted asynchronously to the given queue.

 @seealso DISPATCH_BLOCK_NO_QOS_CLASS
 */
@property dispatch_queue_t dispatchQueue;

/*!
 Whether registration is currently valid.
 */
@property (readonly) BOOL isValid;

/*!
 Register autoupdating shortcut by observing the given key path of the given object.

 @discussion
 The registration expects anObservedObject to return one of:
 - An instance of SRShortcut
 - A compatible dictionary representation
 - An instance of NSData of encoded SRShortcut
 */
- (void)setObservedObject:(id)anObservedObject withKeyPath:(NSString *)aKeyPath;

/*!
 Either execute the handler or send the action in the configured dispatch queue.
 */
- (void)fire;

/*!
 Unregister the shortcut and reset its properties.
 */
- (void)invalidate;

@end


#pragma mark Target-Action

@interface NSObject (SRShortcutRegistration)

- (void)performShortcutActionForRegistration:(SRShortcutRegistration *)aRegistration NS_SWIFT_NAME(performShortcutAction(_:));

@end


#pragma mark Registration

@interface SRShortcutRegistration (/* Code */)

/*!
 Enable system-wide shortcut monitoring.

 @discussion
 This method increments the counter which when reaches 0 enables monitoring.
 */
+ (void)enableShortcutRegistrations;

/*!
 Disable system-wide shortcut monitoring.

 @discussion
 This method decrements the counter which when reaches 0 disables monitoring.
 */
+ (void)disableShortcutRegistrations;

/*!
 Register the shortcut.

 @param aShortcut The shortcut to register

 @param anActionHandler The action handler to invoke in response to the shortcut.

 @discussion
 The underlying Carbon API (InstallEventHandler / RemoveEventHandler, RegisterEventHotKey / UnregisterEventHotKey)
 is not thread safe. SRShortcutRegistration serializes its own access, but there may still
 be race conditions with outer code. For safety, stick to using these API from the main thread only.
 */
+ (instancetype)registerShortcut:(SRShortcut *)aShortcut
                   actionHandler:(SRShortcutActionHandler)anActionHandler NS_SWIFT_NAME(register(shortcut:action:));

/*!
 Same as the +registerShortcut:actionHandler: but uses KVO and KVC to obtain and update the shortcut.
 */
+ (instancetype)registerShortcutKeyPath:(NSString *)aKeyPath
                               ofObject:(id)anObject
                          actionHandler:(SRShortcutActionHandler)anActionHandler NS_SWIFT_NAME(register(keyPath:of:action:));

@end


#pragma mark Interface Builder

@interface SRShortcutRegistration (/* Nib Loading */)

/*!
 The object being observed for autoupdating shortcut.

 @discussion
 The setter is reserved for Interface Builder. When setting from code, use setObservedObject:withKeyPath:
 otherwise no shortcut will be registered.
 */
@property (nullable, weak) IBOutlet id observedObject;

- (void)setObservedObject:(id)observedObject __attribute__((deprecated("Setter is reserved for Interface Builder")));

/*!
 The key path being observed for autoupdating shortcut.

 @discussion
 The setter is reserved for Interface Builder. When setting from code, use setObservedObject:withKeyPath:
 otherwise no shortcut will be registered.
 */
@property (nullable, copy) IBInspectable NSString *observedKeyPath;

- (void)setObservedKeyPath:(NSString *)observedKeyPath __attribute__((deprecated("Setter is reserved for Interface Builder")));

@end


#pragma mark NSEvent Monitor

@interface NSEvent (SRShortcutRegistration)

/*!
 @seealso addGlobalMonitorForEventsMatchingMask:handler:
 */
+ (id)SR_addGlobalMonitorForShortcut:(SRShortcut *)aShortcut handler:(void (^)(NSEvent *))aHandler;

/*!
 @seealso addLocalMonitorForEventsMatchingMask:handler:
 */
+ (id)SR_addLocalMonitorForShortcut:(SRShortcut *)aShortcut handler:(NSEvent * _Nullable (^)(NSEvent *))aHandler;

@end

NS_ASSUME_NONNULL_END
