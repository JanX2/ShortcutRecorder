//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Carbon/Carbon.h>
#import <os/trace.h>
#import <os/activity.h>

#import "SRShortcutRegistration.h"
#import "SRCommon.h"


const OSType SRShortcutRegistrationSignature = 'SRSR';


static const UInt32 _SRInvalidHotKeyID = 0;


@interface SRShortcutRegistration ()
@property (nullable) EventHotKeyRef carbonHotKey;
@property EventHotKeyID carbonHotKeyID;
- (void)_invalidateRegistration;
- (void)_invalidateObserving;
@end;


@interface _SRShortcutRegistrationMonitor : NSObject
@property (class, nonnull, readonly) _SRShortcutRegistrationMonitor *shared;
- (void)enable;
- (void)disable;

- (void)installEventHandlerIfNeeded;
- (void)removeEventHandlerIfNeeded;

- (void)addRegistration:(nonnull SRShortcutRegistration *)aRegistration;
- (void)removeRegistration:(nonnull SRShortcutRegistration *)aRegistration;

- (OSStatus)sendCarbonEvent:(nullable EventRef)anEvent;
@end


static OSStatus SRCarbonEventHandler(EventHandlerCallRef aHandler, EventRef anEvent, void *aUserData)
{
    __auto_type *monitor = (__bridge _SRShortcutRegistrationMonitor *)aUserData;
    return [monitor sendCarbonEvent:anEvent];
}


@implementation _SRShortcutRegistrationMonitor
{
    NSMutableArray<SRShortcutRegistration *> *_registrations;
    EventHandlerRef _carbonEventHandler;
    NSInteger _disableCounter;
}

+ (_SRShortcutRegistrationMonitor *)shared
{
    static _SRShortcutRegistrationMonitor *Shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Shared = [_SRShortcutRegistrationMonitor new];
    });
    return Shared;
}

- (instancetype)init
{
    self = [super init];

    if (self)
        _registrations = NSMutableArray.array;

    return self;
}

- (void)enable
{
    @synchronized (self)
    {
        os_trace_debug("%ld -> %ld", _disableCounter, _disableCounter - 1);
        _disableCounter -= 1;
        [self installEventHandlerIfNeeded];
    }

}

- (void)disable
{
    @synchronized (self)
    {
        os_trace_debug("%ld -> %ld", _disableCounter, _disableCounter + 1);
        _disableCounter += 1;
        [self removeEventHandlerIfNeeded];
    }
}

- (void)installEventHandlerIfNeeded
{
    if (!_registrations.count)
        return;

    if (_disableCounter)
        return;

    if (!_carbonEventHandler)
    {
        static const EventTypeSpec eventSpec[1] = { { kEventClassKeyboard, kEventHotKeyPressed } };
        os_trace("Installing event handler");
        OSStatus error = InstallEventHandler(GetEventDispatcherTarget(),
                                             (EventHandlerProcPtr)SRCarbonEventHandler,
                                             1,
                                             eventSpec,
                                             (__bridge void *)self,
                                             &_carbonEventHandler);

        if (error != noErr)
        {
            os_trace_error("#Critical Failed to install event handler: %d", error);
            return;
        }
    }

    for (SRShortcutRegistration *r in _registrations)
    {
        if (r.carbonHotKey)
            continue;

        @synchronized (r)
        {
            SRShortcut *shortcut = r.shortcut;

            if (!shortcut)
                continue;

            EventHotKeyRef hotKey = NULL;
            static UInt32 CarbonID = _SRInvalidHotKeyID;
            EventHotKeyID hotKeyID = {SRShortcutRegistrationSignature, ++CarbonID};
            os_trace("Registering hot key");
            OSStatus error = RegisterEventHotKey(shortcut.carbonKeyCode,
                                                 shortcut.carbonModifierFlags,
                                                 hotKeyID,
                                                 GetEventDispatcherTarget(),
                                                 0,
                                                 &hotKey);

            if (error != noErr)
            {
                os_trace_error_with_payload("#Critical Failed to register hot key: %d", error, ^(xpc_object_t d) {
                    xpc_dictionary_set_uint64(d, "keyCode", shortcut.keyCode);
                    xpc_dictionary_set_uint64(d, "modifierFlags", shortcut.modifierFlags);
                });
                continue;
            }
            else
            {
                os_trace_with_payload("Registered hot key: %u", hotKeyID.id, ^(xpc_object_t d) {
                    xpc_dictionary_set_uint64(d, "keyCode", shortcut.keyCode);
                    xpc_dictionary_set_uint64(d, "modifierFlags", shortcut.modifierFlags);
                });
            }

            r.carbonHotKey = hotKey;
            r.carbonHotKeyID = hotKeyID;
        }
    }
}

- (void)removeEventHandlerIfNeeded
{
    if (!_carbonEventHandler)
        return;

    if (_disableCounter || !_registrations.count)
    {
        os_trace("Removing event handler");
        OSStatus error = RemoveEventHandler(_carbonEventHandler);

        if (error != noErr)
            os_trace_error("Failed to remove event handler: %d", error);
        else
            _carbonEventHandler = NULL;
    }

    if (_disableCounter)
    {
        for (SRShortcutRegistration *r in _registrations)
        {
            if (!r.carbonHotKey)
                continue;

            @synchronized (r)
            {
                os_trace("Removing hot key");
                OSStatus error = UnregisterEventHotKey(r.carbonHotKey);
                SRShortcut *shortcut = r.shortcut;

                if (error != noErr)
                {
                    os_trace_error_with_payload("#Critical Failed to unregister hot key: %d", error, ^(xpc_object_t d) {
                        xpc_dictionary_set_uint64(d, "keyCode", shortcut.keyCode);
                        xpc_dictionary_set_uint64(d, "modifierFlags", shortcut.modifierFlags);
                    });
                }
                else
                {
                    os_trace_with_payload("Unregistered hot key: %u", r.carbonHotKeyID.id, ^(xpc_object_t d) {
                        xpc_dictionary_set_uint64(d, "keyCode", shortcut.keyCode);
                        xpc_dictionary_set_uint64(d, "modifierFlags", shortcut.modifierFlags);
                    });
                    r.carbonHotKey = NULL;
                    r.carbonHotKeyID = (EventHotKeyID){SRShortcutRegistrationSignature, _SRInvalidHotKeyID};
                }
            }
        }
    }
}

- (void)addRegistration:(nonnull SRShortcutRegistration *)aRegistration
{
    @synchronized (self)
    {
        [_registrations addObject:aRegistration];
        [self installEventHandlerIfNeeded];
    }
}

- (void)removeRegistration:(SRShortcutRegistration *)aRegistration
{
    @synchronized (self)
    {
        [_registrations removeObjectIdenticalTo:aRegistration];

        if (aRegistration.carbonHotKey)
        {
            UnregisterEventHotKey(aRegistration.carbonHotKey);
            aRegistration.carbonHotKey = NULL;
            aRegistration.carbonHotKeyID = (EventHotKeyID){SRShortcutRegistrationSignature, _SRInvalidHotKeyID};
        }

        [self removeEventHandlerIfNeeded];
    }
}

- (OSStatus)sendCarbonEvent:(EventRef)anEvent
{
    __block OSStatus error = noErr;

    os_activity_initiate("Handeling carbon event", OS_ACTIVITY_FLAG_DETACHED, ^{
        if (self->_disableCounter > 0)
        {
            os_trace_debug("Registrations are currently disabled");
            error = eventNotHandledErr;
            return;
        }

        if (!anEvent)
        {
            os_trace_error("#Error Event is NULL");
            error = eventNotHandledErr;
            return;
        }

        if (GetEventClass(anEvent) != kEventClassKeyboard)
        {
            os_trace_error("#Error Event is of wrong class");
            error = eventNotHandledErr;
            return;
        }

        EventHotKeyID hotKeyID;
        error = GetEventParameter(anEvent,
                                  kEventParamDirectObject,
                                  typeEventHotKeyID,
                                  NULL,
                                  sizeof(hotKeyID),
                                  NULL,
                                  &hotKeyID);

        if (error != noErr)
        {
            os_trace_error("#Critical Failed to get hot key parameters: %d", error);
            error = eventNotHandledErr;
            return;
        }

        if (hotKeyID.id == 0 || hotKeyID.signature != SRShortcutRegistrationSignature)
        {
            os_trace_error("#Error Unexpected hot key with id %u and signature: %u", hotKeyID.id, hotKeyID.signature);
            error = eventNotHandledErr;
            return;
        }

        @synchronized (self)
        {
            NSUInteger i = [self->_registrations indexOfObjectPassingTest:^(SRShortcutRegistration *obj, NSUInteger idx, BOOL *stop) {
                return (BOOL)(obj.carbonHotKeyID.id == hotKeyID.id);
            }];

            if (i != NSNotFound)
            {
                [self->_registrations[i] fire];
                error = noErr;
            }
            else
            {
                os_trace("Unregistered hot key with id %u and signature %u", hotKeyID.id, hotKeyID.signature);
                error = eventNotHandledErr;
            }
        }
    });

    return error;
}

@end


static void *_SRShortcutRegistrationContext = &_SRShortcutRegistrationContext;


@implementation SRShortcutRegistration
{
    SRShortcut *_shortcut;
    SRShortcutActionHandler _actionHandler;
    __weak id _target;
}

+ (void)enableShortcutRegistrations
{
    os_activity_initiate("Enabling registrations", OS_ACTIVITY_FLAG_DEFAULT, ^{
        [_SRShortcutRegistrationMonitor.shared enable];
    });
}

+ (void)disableShortcutRegistrations
{
    os_activity_initiate("Disabling registrations", OS_ACTIVITY_FLAG_DEFAULT, ^{
        [_SRShortcutRegistrationMonitor.shared disable];
    });
}

+ (instancetype)shortcutRegistrationWithShortcut:(SRShortcut *)aShortcut actionHandler:(SRShortcutActionHandler)anActionHandler
{
    SRShortcutRegistration *registration = [self new];
    registration.actionHandler = anActionHandler;
    registration.shortcut = aShortcut;
    return registration;
}

+ (instancetype)shortcutRegistrationWithKeyPath:(NSString *)aKeyPath
                                       ofObject:(id)anObject
                                  actionHandler:(SRShortcutActionHandler)anActionHandler
{
    SRShortcutRegistration *registration = [self new];
    registration.actionHandler = anActionHandler;
    [registration setObservedObject:anObject withKeyPath:aKeyPath];
    return registration;
}

- (instancetype)init
{
    self = [super init];

    if (self)
        _dispatchQueue = dispatch_get_main_queue();

    return self;
}

- (void)dealloc
{
    [self invalidate];
}

#pragma mark Properties

+ (BOOL)automaticallyNotifiesObserversOfCarbonHotKey
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfCarbonHotKeyID
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfShortcut
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfActionHandler
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfTarget
{
    return NO;
}

- (SRShortcut *)shortcut
{
    @synchronized (self)
    {
        return _shortcut;
    }
}

- (void)setShortcut:(SRShortcut *)aShortcut
{
    os_activity_initiate("Registering raw shortcut", OS_ACTIVITY_FLAG_DEFAULT, ^{
        @synchronized (self)
        {
            if (self->_shortcut == aShortcut || [self->_shortcut isEqual:aShortcut])
                return;

            [self willChangeValueForKey:@"observedObject"];
            [self willChangeValueForKey:@"observedKeyPath"];
            [self willChangeValueForKey:@"shortcut"];
            [self willChangeValueForKey:@"isValid"];

            [self _invalidateObserving];
            [self _invalidateRegistration];
            self->_shortcut = aShortcut;
            self->_isValid = YES;
            [_SRShortcutRegistrationMonitor.shared addRegistration:self];

            [self didChangeValueForKey:@"isValid"];
            [self didChangeValueForKey:@"shortcut"];
            [self didChangeValueForKey:@"observedKeyPath"];
            [self didChangeValueForKey:@"observedObject"];
        }
    });
}

- (void)setObservedObject:(id)anObservedObject withKeyPath:(NSString *)aKeyPath
{
    os_activity_initiate("Registering autoupdating shortcut", OS_ACTIVITY_FLAG_DEFAULT, ^{
        @synchronized (self)
        {
            [self willChangeValueForKey:@"observedObject"];
            [self willChangeValueForKey:@"observedKeyPath"];
            [self willChangeValueForKey:@"shortcut"];
            [self willChangeValueForKey:@"isValid"];
            [self _invalidateRegistration];
            [anObservedObject addObserver:self
                               forKeyPath:aKeyPath
                                  options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                  context:_SRShortcutRegistrationContext];
            self->_observedObject = anObservedObject;
            self->_observedKeyPath = aKeyPath;
            self->_isValid = YES; // registration is valid as long as observation continues
            [self didChangeValueForKey:@"isValid"];
            [self didChangeValueForKey:@"shortcut"];
            [self didChangeValueForKey:@"observedKeyPath"];
            [self didChangeValueForKey:@"observedObject"];
        }
    });
}

- (SRShortcutActionHandler)actionHandler
{
    @synchronized (self)
    {
        return _actionHandler;
    }
}

- (void)setActionHandler:(SRShortcutActionHandler)newActionHandler
{
    @synchronized (self)
    {
        [self willChangeValueForKey:@"actionHandler"];
        _actionHandler = newActionHandler;

        if (_actionHandler && _target)
        {
            [self willChangeValueForKey:@"target"];
            _target = nil;
            [self didChangeValueForKey:@"target"];
        }

        [self didChangeValueForKey:@"actionHandler"];
    }
}

- (id)target
{
    @synchronized (self)
    {
        return _target;
    }
}

- (void)setTarget:(id)newTarget
{
    @synchronized (self)
    {
        if (newTarget == _target)
            return;

        [self willChangeValueForKey:@"target"];
        _target = newTarget;

        if (_target && _actionHandler)
        {
            [self willChangeValueForKey:@"actionHandler"];
            _actionHandler = nil;
            [self didChangeValueForKey:@"actionHandler"];
        }

        [self didChangeValueForKey:@"target"];
    }
}

#pragma mark Methods

- (void)fire
{
    os_activity_initiate("Firing shortcut", OS_ACTIVITY_FLAG_DEFAULT, ^{
        dispatch_async(self.dispatchQueue, dispatch_block_create(DISPATCH_BLOCK_NO_QOS_CLASS, ^{
            SRShortcutActionHandler handler = self.actionHandler;
            id target = self.target;

            if (handler)
            {
                os_trace_debug("Using action handler");
                handler(self);
            }
            else if (target)
            {
                os_trace_debug("Using target-action");
                [target performSelector:@selector(performShortcutActionForRegistration:) withObject:self];
            }
        }));
    });
}

- (void)invalidate
{
    os_activity_initiate("Invalidating shortcut registration", OS_ACTIVITY_FLAG_DEFAULT, ^{
        @synchronized (self)
        {
            if (!self->_isValid)
                return;

            [self willChangeValueForKey:@"observedObject"];
            [self willChangeValueForKey:@"observedKeyPath"];
            [self willChangeValueForKey:@"shortcut"];
            [self willChangeValueForKey:@"isValid"];

            [self _invalidateObserving];
            [self _invalidateRegistration];
            self->_isValid = NO;

            [self didChangeValueForKey:@"isValid"];
            [self didChangeValueForKey:@"shortcut"];
            [self didChangeValueForKey:@"observedKeyPath"];
            [self didChangeValueForKey:@"observedObject"];

        }
    });
}

#pragma mark Private

- (void)_invalidateRegistration
{
    [_SRShortcutRegistrationMonitor.shared removeRegistration:self];
    _shortcut = nil;
}

- (void)_invalidateObserving
{
    if (_observedObject)
        [_observedObject removeObserver:self forKeyPath:_observedKeyPath context:_SRShortcutRegistrationContext];

    _observedObject = nil;
    _observedKeyPath = nil;
}

#pragma mark NSUserInterfaceItemIdentification
@synthesize identifier;

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(NSObject *)anObject
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)aChange
                       context:(void *)aContext
{
    if (aContext == _SRShortcutRegistrationContext)
    {
        os_activity_initiate("Observing new shortcut", OS_ACTIVITY_FLAG_DEFAULT, ^{
            SRShortcut *newShortcut = aChange[NSKeyValueChangeNewKey];

            // NSController subclasses are notable for not setting the New and Old keys of the change dictionary.
            if ((!newShortcut || (NSNull *)newShortcut == NSNull.null) && [anObject isKindOfClass:NSController.class])
                newShortcut = [anObject valueForKeyPath:aKeyPath];

            if ([newShortcut isKindOfClass:NSDictionary.class])
                newShortcut = [SRShortcut shortcutWithDictionary:(NSDictionary *)newShortcut];
            else if ([newShortcut isKindOfClass:NSData.class])
                newShortcut = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)newShortcut];
            else if ((NSNull *)newShortcut == NSNull.null)
                newShortcut = nil;

            @synchronized (self)
            {
                if (self->_shortcut == newShortcut || [self->_shortcut isEqual:newShortcut])
                    return;

                [self willChangeValueForKey:@"shortcut"];
                [self _invalidateRegistration];

                if (newShortcut)
                {
                    self->_shortcut = newShortcut;
                    [_SRShortcutRegistrationMonitor.shared addRegistration:self];
                }

                [self didChangeValueForKey:@"shortcut"];
            }
        });
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation NSEvent (SRShortcutRegistration)

+ (id)SR_addGlobalMonitorForShortcut:(SRShortcut *)aShortcut handler:(void (^)(NSEvent * _Nonnull))aHandler
{
    return [self addGlobalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *anEvent) {
        if (aShortcut.keyCode == anEvent.keyCode && aShortcut.modifierFlags == (anEvent.modifierFlags & SRCocoaModifierFlagsMask))
            aHandler(anEvent);
    }];
}

+ (id)SR_addLocalMonitorForShortcut:(SRShortcut *)aShortcut handler:(NSEvent * _Nullable (^)(NSEvent * _Nonnull))aHandler
{
    return [self addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *anEvent) {
        if (aShortcut.keyCode == anEvent.keyCode && aShortcut.modifierFlags == (anEvent.modifierFlags & SRCocoaModifierFlagsMask))
            return aHandler(anEvent);
        else
            return anEvent;
    }];
}

@end
