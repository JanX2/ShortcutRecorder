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
typedef void (^SRShortcutAction)(SRShortcutRegistration *aRegistration) NS_SWIFT_NAME(SRShortcutRegistration.Action);

/*!
 Signature of a Carbon system-wide hot key.
 */
extern const OSType SRShortcutRegistrationSignature NS_SWIFT_NAME(SRShortcutRegistration.Signature);


/*!
 Registration of the system-wide shortcut.

 Use one of the factory methods to register a shortcut. Registration stays valid until
 either invalidated or deallocated.
 */
NS_SWIFT_NAME(ShortcutRegistration)
@interface SRShortcutRegistration : NSObject

/*!
 Target dispatch queue for the action.

 @discussion:
 Defaults to the main queue.

 The action block is detached and submitted asynchronously to the given queue.

 @seealso DISPATCH_BLOCK_DETACHED
 */
@property dispatch_queue_t dispatchQueue;

/*!
 Shortcut associated with the registration
 */
@property (nullable, readonly) SRShortcut *shortcut;

/*!
 Whether registration is still valid.
 */
@property (readonly) BOOL isValid;

/*!
 Register the shortcut.

 @param aShortcut The shortcut to register

 @param anAction The action to invoke in response to the shortcut.

 @param outError An optional error object to be set if registration fails.

 @return Newly created registration object or nil if error has happened.

 @discussion
 Registration may fail in which case nil is returned and outError is set.

 The underlying Carbon API (InstallEventHandler / RemoveEventHandler, RegisterEventHotKey / UnregisterEventHotKey)
 is not thread safe. SRShortcutRegistration serializes its own access, but there may still
 be race conditions with outer code.
 For safety, stick to using these API from the main thread only.
 */
+ (nullable instancetype)registerShortcut:(SRShortcut *)aShortcut
                               withAction:(SRShortcutAction)anAction
                                    error:(NSError * _Nullable *)outError;

/*!
 Same as the +registerShortcut:withAction:error: but uses KVO and KVC to obtain and update the shortcut.

 @discussion
 The registration expects anObject to return one of:
    - An instance of SRShortcut
    - A compatible dictionary representation
    - An instance of NSData of encoded SRShortcut
 */
+ (nullable instancetype)registerAutoupdatingShortcutWithKeyPath:(NSString *)aKeyPath
                                                        toObject:(NSObject *)anObject
                                                          action:(SRShortcutAction)anAction
                                                           error:(NSError * _Nullable *)outError NS_SWIFT_NAME(register(autoupdatingShortcutWithKeyPath:to:action:));

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

/*!
 Unregister the shortcut.
 */
- (void)invalidate;

@end


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
