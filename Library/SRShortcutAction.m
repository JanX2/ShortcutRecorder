//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Carbon/Carbon.h>
#import <os/trace.h>
#import <os/activity.h>

#import "SRShortcutAction.h"
#import "SRCommon.h"


static void *_SRShortcutActionContext = &_SRShortcutActionContext;


@implementation SRShortcutAction
{
    SRShortcut *_shortcut;
    SRShortcutActionHandler _actionHandler;
    __weak id _target;
}

+ (instancetype)shortcutActionWithShortcut:(SRShortcut *)aShortcut
                                    target:(id)aTarget
                                    action:(SEL)anAction
                                       tag:(NSInteger)aTag
{
    SRShortcutAction *action = [self new];
    action.shortcut = aShortcut;
    action.target = aTarget;
    action.action = anAction;
    action.tag = aTag;
    return action;
}

+ (instancetype)shortcutActionWithShortcut:(SRShortcut *)aShortcut
                             actionHandler:(SRShortcutActionHandler)anActionHandler
{
    SRShortcutAction *action = [self new];
    action.shortcut = aShortcut;
    action.actionHandler = anActionHandler;
    return action;
}

+ (instancetype)shortcutActionWithKeyPath:(NSString *)aKeyPath
                                 ofObject:(id)anObject
                                   target:(id)aTarget
                                   action:(nullable SEL)anAction
                                      tag:(NSInteger)aTag
{
    SRShortcutAction *action = [self new];
    [action setObservedObject:anObject withKeyPath:aKeyPath];
    action.target = aTarget;
    action.action = anAction;
    action.tag = aTag;
    return action;
}

+ (instancetype)shortcutActionWithKeyPath:(NSString *)aKeyPath
                                 ofObject:(id)anObject
                            actionHandler:(SRShortcutActionHandler)anActionHandler
{
    SRShortcutAction *action = [self new];
    [action setObservedObject:anObject withKeyPath:aKeyPath];
    action.actionHandler = anActionHandler;
    return action;
}

- (instancetype)init
{
    self = [super init];

    if (self)
        _enabled = YES;

    return self;
}

- (void)dealloc
{
    [self _invalidateObserving];
}

#pragma mark Properties
@synthesize identifier;
@synthesize tag;

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
    os_activity_initiate("Setting raw shortcut", OS_ACTIVITY_FLAG_DEFAULT, ^{
        @synchronized (self)
        {
            [self willChangeValueForKey:@"observedObject"];
            [self willChangeValueForKey:@"observedKeyPath"];

            if (self->_shortcut != aShortcut && ![self->_shortcut isEqual:aShortcut])
            {
                [self willChangeValueForKey:@"shortcut"];
                [self _invalidateObserving];
                self->_shortcut = aShortcut;
                [self didChangeValueForKey:@"shortcut"];
            }
            else
                [self _invalidateObserving];

            [self didChangeValueForKey:@"observedKeyPath"];
            [self didChangeValueForKey:@"observedObject"];
        }
    });
}

- (void)setObservedObject:(id)newObservedObject withKeyPath:(NSString *)newKeyPath
{
    os_activity_initiate("Setting autoupdating shortcut", OS_ACTIVITY_FLAG_DEFAULT, ^{
        @synchronized (self)
        {
            if (newObservedObject == self->_observedObject && [self->_observedKeyPath isEqualToString:newKeyPath])
                return;

            [self willChangeValueForKey:@"observedObject"];
            [self willChangeValueForKey:@"observedKeyPath"];

            [self _invalidateObserving];
            self->_observedObject = newObservedObject;
            self->_observedKeyPath = newKeyPath;
            [newObservedObject addObserver:self
                                forKeyPath:newKeyPath
                                   options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                   context:_SRShortcutActionContext];

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
        return _target != nil ? _target : NSApplication.sharedApplication;
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

- (BOOL)performActionOnTarget:(id)aTarget
{
    __block BOOL isPerformed = NO;
    os_activity_initiate("Performing shortcut action", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (!self.isEnabled)
        {
            os_trace_debug("Not performed: disabled");
            return;
        }

        SRShortcutActionHandler actionHandler = self.actionHandler;

        if (actionHandler)
        {
            os_trace_debug("Using action handler");
            isPerformed = actionHandler(self);
        }
        else
        {
            id target = aTarget != nil ? aTarget : self.target;
            if (!target)
            {
                os_trace_debug("Not performed: no associated target");
                return;
            }

            SEL action = self.action;
            
            BOOL canPerformAction = NO;
            BOOL canPerformProtocol = NO;
            if (!(canPerformAction = action && [target respondsToSelector:action]) && !(canPerformProtocol = [target respondsToSelector:@selector(performShortcutAction:)]))
            {
                os_trace_debug("Not performed: target cannot respond to action");
                return;
            }
            else if ([target respondsToSelector:@selector(validateUserInterfaceItem:)] && ![target validateUserInterfaceItem:self])
            {
                os_trace_debug("Not performed: target ignored action");
                return;
            }

            if (canPerformAction)
            {
                os_trace_debug("Using action");
                NSMethodSignature *sig = [target methodSignatureForSelector:action];
                IMP actionMethod = [target methodForSelector:action];
                BOOL returnsBool = strncmp(sig.methodReturnType, @encode(BOOL), 2) == 0;
                switch (sig.numberOfArguments)
                {
                    case 2:
                    {
                        if (returnsBool)
                            isPerformed = ((BOOL (*)(id, SEL))actionMethod)(target, action);
                        else
                        {
                            ((void (*)(id, SEL))actionMethod)(target, action);
                            isPerformed = YES;
                        }
                        break;
                    }
                    case 3:
                    {
                        if (returnsBool)
                            isPerformed = ((BOOL (*)(id, SEL, id))actionMethod)(target, action, self);
                        else
                        {
                            ((void (*)(id, SEL, id))actionMethod)(target, action, self);
                            isPerformed = YES;
                        }
                        break;
                    }
                    default:
                        break;
                }
            }
            else if (canPerformProtocol)
            {
                os_trace_debug("Using protocol");
                isPerformed = [(id<SRShortcutActionTarget>)target performShortcutAction:self];
            }
        }
    });
    return isPerformed;
}

#pragma mark Private

- (void)_invalidateObserving
{
    if (_observedObject)
        [_observedObject removeObserver:self forKeyPath:_observedKeyPath context:_SRShortcutActionContext];

    _observedObject = nil;
    _observedKeyPath = nil;
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(NSObject *)anObject
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)aChange
                       context:(void *)aContext
{
    if (aContext != _SRShortcutActionContext)
    {
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
        return;
    }

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
            self->_shortcut = newShortcut;
            [self didChangeValueForKey:@"shortcut"];
        }
    });
}

@end


#pragma mark -


static void *_SRShortcutMonitorContext = &_SRShortcutMonitorContext;


@interface SRShortcutMonitor ()
{
    @protected
    NSMapTable<SRShortcut *, NSMutableArray<SRShortcutAction *> *> *_shortcutToActions;
    NSHashTable<SRShortcutAction *> *_shortcutActions;
}
@end


@implementation SRShortcutMonitor

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _shortcutToActions = [NSMapTable strongToStrongObjectsMapTable];
        _shortcutActions = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality];
    }

    return self;
}

- (void)dealloc
{
    for (SRShortcutAction *action in _shortcutActions)
    {
        [action removeObserver:self forKeyPath:@"shortcut" context:_SRShortcutMonitorContext];
    }
}

#pragma mark Properties

- (NSArray<SRShortcutAction *> *)shortcutActions
{
    return _shortcutActions.allObjects;
}

- (NSSet<SRShortcut *> *)allShortcuts
{
    NSMutableSet *shortcuts = [NSMutableSet new];

    for (SRShortcutAction *action in _shortcutActions)
    {
        if (action.shortcut)
            [shortcuts addObject:action.shortcut];
    }

    return [shortcuts copy];
}

#pragma mark Methods

- (void)addShortcutAction:(SRShortcutAction *)anAction
{
    @synchronized (_shortcutToActions)
    {
        if ([_shortcutActions containsObject:anAction])
            return;

        [_shortcutActions addObject:anAction];
        [anAction addObserver:self
                   forKeyPath:@"shortcut"
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                      context:_SRShortcutMonitorContext];
    }
}

- (void)removeShortcutAction:(SRShortcutAction *)anAction
{
    @synchronized (_shortcutToActions)
    {
        if (![_shortcutActions containsObject:anAction])
            return;

        [_shortcutActions removeObject:anAction];
        [[_shortcutToActions objectForKey:anAction.shortcut] removeObject:anAction];
        [anAction removeObserver:self forKeyPath:@"shortcut" context:_SRShortcutMonitorContext];
    }
}

- (SRShortcutAction *)actionForShortcut:(SRShortcut *)aShortcut
{
    @synchronized (_shortcutToActions)
    {
        return [[_shortcutToActions objectForKey:aShortcut] lastObject];
    }
}

- (NSArray<SRShortcutAction *> *)allActionsForShortcut:(SRShortcut *)aShortcut
{
    @synchronized (_shortcutToActions)
    {
        NSMutableArray *actions = [_shortcutToActions objectForKey:aShortcut];
        return actions != nil ? [actions copy] : @[];
    }
}

- (void)didAddShortcut:(SRShortcut *)aShortcut
{
}

- (void)didRemoveShortcut:(SRShortcut *)aShortcut
{
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(NSObject *)anObject
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)aChange
                       context:(void *)aContext
{
    if (aContext != _SRShortcutMonitorContext)
    {
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
        return;
    }

    SRShortcut *oldShortcut = aChange[NSKeyValueChangeOldKey];
    SRShortcut *newShortcut = aChange[NSKeyValueChangeNewKey];

    @synchronized (_shortcutToActions)
    {
        if (oldShortcut && (id)oldShortcut != NSNull.null)
        {
            NSMutableArray *actions = [_shortcutToActions objectForKey:oldShortcut];
            [actions removeObject:(SRShortcutAction *)anObject];

            if (!actions.count)
            {
                [_shortcutToActions removeObjectForKey:oldShortcut];
                [self didRemoveShortcut:oldShortcut];
            }
        }

        if (newShortcut && (id)newShortcut != NSNull.null)
        {
            NSMutableArray *actions = [_shortcutToActions objectForKey:newShortcut];

            if (!actions)
            {
                actions = [NSMutableArray new];
                [_shortcutToActions setObject:actions forKey:newShortcut];
            }

            [actions addObject:(SRShortcutAction *)anObject];

            if (actions.count == 1)
                [self didAddShortcut:newShortcut];
        }
    }
}

@end


@implementation SRShortcutMonitor (SRShortcutMonitorConveniences)

- (SRShortcutAction *)addAction:(SEL)anAction forKeyEquivalent:(NSString *)aKeyEquivalent tag:(NSInteger)aTag
{
    SRShortcut *shortcut = [SRShortcut shortcutWithKeyEquivalent:aKeyEquivalent];

    if (!shortcut)
        return nil;

    SRShortcutAction *action = [SRShortcutAction shortcutActionWithShortcut:shortcut target:nil action:anAction tag:aTag];
    [self addShortcutAction:action];
    return action;
}

@end


const OSType SRShortcutActionSignature = 'SRSR';

static const UInt32 _SRInvalidHotKeyID = 0;

static OSStatus SRCarbonEventHandler(EventHandlerCallRef aHandler, EventRef anEvent, void *aUserData)
{
    return [(__bridge SRGlobalShortcutMonitor *)aUserData handleEvent:anEvent];
}


@implementation SRGlobalShortcutMonitor
{
    NSMapTable<NSNumber *, SRShortcut *> *_hotKeyIdToShortcut;
    NSMapTable<SRShortcut *, id> *_shortcutToHotKeyRef;
    NSMapTable<SRShortcut *, NSNumber *> *_shortcutToHotKeyId;
    EventHandlerRef _carbonEventHandler;
    NSInteger _disableCounter;
}

+ (SRGlobalShortcutMonitor *)sharedMonitor
{
    static SRGlobalShortcutMonitor *Shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Shared = [SRGlobalShortcutMonitor new];
    });
    return Shared;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _hotKeyIdToShortcut = [NSMapTable strongToStrongObjectsMapTable];
        _shortcutToHotKeyRef = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                                                     valueOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality];
        _shortcutToHotKeyId = [NSMapTable strongToStrongObjectsMapTable];
        _dispatchQueue = dispatch_get_main_queue();
    }

    return self;
}

#pragma mark Methods

- (void)resume
{
    @synchronized (_shortcutToActions)
    {
        os_trace_debug("Global Shortcut Monitor counter: %ld -> %ld", _disableCounter, _disableCounter - 1);
        _disableCounter -= 1;

        if (_disableCounter == 0)
        {
            [self installEventHandlerIfNeeded];

            for (SRShortcut *shortcut in self.allShortcuts)
                [self registerHotKeyForShortcutIfNeeded:shortcut];
        }
    }
}

- (void)pause
{
    @synchronized (_shortcutToActions)
    {
        os_trace_debug("Global Shortcut Monitor counter: %ld -> %ld", _disableCounter, _disableCounter + 1);
        _disableCounter += 1;

        if (_disableCounter == 1)
        {
            [self unregisterAllHotKeys];
            [self removeEventHandlerIfNeeded];
        }
    }
}

- (OSStatus)handleEvent:(EventRef)anEvent
{
    __block OSStatus error = noErr;

    os_activity_initiate("Handling Carbon event", OS_ACTIVITY_FLAG_DETACHED, ^{
        if (self->_disableCounter > 0)
        {
            os_trace_debug("Monitoring is currently disabled");
            error = eventNotHandledErr;
            return;
        }
        else if (!anEvent)
        {
            os_trace_error("#Error Event is NULL");
            error = eventNotHandledErr;
            return;
        }
        else if (GetEventClass(anEvent) != kEventClassKeyboard)
        {
            os_trace_error("#Error Not a keyboard event");
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
            os_trace_error("#Critical Failed to get hot key ID: %d", error);
            error = eventNotHandledErr;
            return;
        }
        else if (hotKeyID.id == 0 || hotKeyID.signature != SRShortcutActionSignature)
        {
            os_trace_error("#Error Unexpected hot key with id %u and signature: %u", hotKeyID.id, hotKeyID.signature);
            error = eventNotHandledErr;
            return;
        }

        @synchronized (self->_shortcutToActions)
        {
            SRShortcut *shortcut = [self->_hotKeyIdToShortcut objectForKey:@(hotKeyID.id)];

            if (!shortcut)
            {
                os_trace("Unregistered hot key with id %u and signature %u", hotKeyID.id, hotKeyID.signature);
                error = eventNotHandledErr;
                return;
            }

            __auto_type actions = [self allActionsForShortcut:shortcut];

            if (!actions.count)
            {
                os_trace("No actions for the shortcut");
                error = eventNotHandledErr;
                return;
            }

            dispatch_async(self.dispatchQueue, dispatch_block_create(DISPATCH_BLOCK_NO_QOS_CLASS, ^{
                [actions enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SRShortcutAction *obj, NSUInteger idx, BOOL *stop) {
                    *stop = [obj performActionOnTarget:nil];
                }];
            }));
        }
    });

    return error;
}

#pragma mark Private

- (void)installEventHandlerIfNeeded
{
    if (_carbonEventHandler)
        return;

    static const EventTypeSpec eventSpec[] = { { kEventClassKeyboard, kEventHotKeyPressed } };
    os_trace("Installing Carbon hot key event handler");
    OSStatus error = InstallEventHandler(GetEventDispatcherTarget(),
                                         (EventHandlerProcPtr)SRCarbonEventHandler,
                                         sizeof(eventSpec) / sizeof(EventTypeSpec),
                                         eventSpec,
                                         (__bridge void *)self,
                                         &_carbonEventHandler);

    if (error != noErr)
    {
        os_trace_error("#Critical Failed to install event handler: %d", error);
        _carbonEventHandler = NULL;
    }
}

- (void)removeEventHandlerIfNeeded
{
    if (!_carbonEventHandler)
        return;

    os_trace("Removing Carbon hot key event handler");
    OSStatus error = RemoveEventHandler(_carbonEventHandler);

    if (error != noErr)
        os_trace_error("#Error Failed to remove event handler: %d", error);

    // Assume that an error to remove the handler is due to the latter being invalid.
    _carbonEventHandler = NULL;
}

- (void)registerHotKeyForShortcutIfNeeded:(SRShortcut *)aShortcut
{
    EventHotKeyRef hotKey = (__bridge EventHotKeyRef)([_shortcutToHotKeyRef objectForKey:aShortcut]);

    if (hotKey)
        return;

    static UInt32 CarbonID = _SRInvalidHotKeyID;
    EventHotKeyID hotKeyID = {SRShortcutActionSignature, ++CarbonID};
    os_trace("Registering Carbon hot key");
    OSStatus error = RegisterEventHotKey(aShortcut.carbonKeyCode,
                                         aShortcut.carbonModifierFlags,
                                         hotKeyID,
                                         GetEventDispatcherTarget(),
                                         0,
                                         &hotKey);

    if (error != noErr || !hotKey)
    {
        os_trace_error_with_payload("#Critical Failed to register Carbon hot key: %d", error, ^(xpc_object_t d) {
            xpc_dictionary_set_uint64(d, "keyCode", aShortcut.keyCode);
            xpc_dictionary_set_uint64(d, "modifierFlags", aShortcut.modifierFlags);
        });
        return;
    }

    os_trace_with_payload("Registered Carbon hot key %u", hotKeyID.id, ^(xpc_object_t d) {
        xpc_dictionary_set_uint64(d, "keyCode", aShortcut.keyCode);
        xpc_dictionary_set_uint64(d, "modifierFlags", aShortcut.modifierFlags);
    });

    [_shortcutToHotKeyRef setObject:(__bridge id _Nullable)(hotKey) forKey:aShortcut];
    [_hotKeyIdToShortcut setObject:aShortcut forKey:@(hotKeyID.id)];
    [_shortcutToHotKeyId setObject:@(hotKeyID.id) forKey:aShortcut];
}

- (void)unregisterHotKeyForShortcutIfNeeded:(SRShortcut *)aShortcut
{
    EventHotKeyRef hotKey = (__bridge EventHotKeyRef)([_shortcutToHotKeyRef objectForKey:aShortcut]);

    if (!hotKey)
        return;

    UInt32 hotKeyID = [_shortcutToHotKeyId objectForKey:aShortcut].unsignedIntValue;

    os_trace("Removing Carbon hot key %u", hotKeyID);
    OSStatus error = UnregisterEventHotKey(hotKey);

    if (error != noErr)
    {
        os_trace_error_with_payload("#Critical Failed to unregister Carbon hot key %u: %d", hotKeyID, error, ^(xpc_object_t d) {
            xpc_dictionary_set_uint64(d, "keyCode", aShortcut.keyCode);
            xpc_dictionary_set_uint64(d, "modifierFlags", aShortcut.modifierFlags);
        });
    }
    else
    {
        os_trace_with_payload("Unregistered Carbon hot key %u", hotKeyID, ^(xpc_object_t d) {
            xpc_dictionary_set_uint64(d, "keyCode", aShortcut.keyCode);
            xpc_dictionary_set_uint64(d, "modifierFlags", aShortcut.modifierFlags);
        });
    }

    // Assume that an error to unregister the handler is due to the latter being invalid.
    [_shortcutToHotKeyRef removeObjectForKey:aShortcut];
    [_shortcutToHotKeyId removeObjectForKey:aShortcut];
    [_hotKeyIdToShortcut removeObjectForKey:@(hotKeyID)];
}

- (void)unregisterAllHotKeys
{
    NSEnumerator *hotKeys = [_shortcutToHotKeyRef objectEnumerator];
    EventHotKeyRef hotKey = NULL;

    while ((hotKey = (__bridge EventHotKeyRef)[hotKeys nextObject]))
    {
        UnregisterEventHotKey(hotKey);
    }

    [_shortcutToHotKeyId removeAllObjects];
    [_shortcutToHotKeyRef removeAllObjects];
    [_hotKeyIdToShortcut removeAllObjects];
}

#pragma mark SRShortcutMonitor

- (void)didAddShortcut:(SRShortcut *)aShortcut
{
    [self registerHotKeyForShortcutIfNeeded:aShortcut];

    if (_shortcutToHotKeyRef.count > 0)
        [self installEventHandlerIfNeeded];
}

- (void)didRemoveShortcut:(SRShortcut *)aShortcut
{
    [self unregisterHotKeyForShortcutIfNeeded:aShortcut];

    if (_shortcutToHotKeyRef.count == 0)
        [self removeEventHandlerIfNeeded];
}

@end


@interface NSObject (_SRShortcutAction)
- (void)undo:(id)aSender;
- (void)redo:(id)aSender;
@end


@implementation SRLocalShortcutMonitor

+ (SRLocalShortcutMonitor *)standardShortcuts
{
    SRLocalShortcutMonitor *m = [SRLocalShortcutMonitor new];
    [m addAction:@selector(moveForward:) forKeyEquivalent:@"⌃F" tag:0];
    [m addAction:@selector(moveRight:) forKeyEquivalent:@"→" tag:0];
    [m addAction:@selector(moveBackward:) forKeyEquivalent:@"⌃B" tag:0];
    [m addAction:@selector(moveLeft:) forKeyEquivalent:@"←" tag:0];
    [m addAction:@selector(moveUp:) forKeyEquivalent:@"↑" tag:0];
    [m addAction:@selector(moveUp:) forKeyEquivalent:@"⌃P" tag:0];
    [m addAction:@selector(moveDown:) forKeyEquivalent:@"↓" tag:0];
    [m addAction:@selector(moveDown:) forKeyEquivalent:@"⌃N" tag:0];
    [m addAction:@selector(moveWordForward:) forKeyEquivalent:@"⌥F" tag:0];
    [m addAction:@selector(moveWordBackward:) forKeyEquivalent:@"⌥B" tag:0];
    [m addAction:@selector(moveToBeginningOfLine:) forKeyEquivalent:@"⌃A" tag:0];
    [m addAction:@selector(moveToEndOfLine:) forKeyEquivalent:@"⌃E" tag:0];
    [m addAction:@selector(moveToEndOfDocument:) forKeyEquivalent:@"⌘↓" tag:0];
    [m addAction:@selector(moveToBeginningOfDocument:) forKeyEquivalent:@"⌘↑" tag:0];
    [m addAction:@selector(pageDown:) forKeyEquivalent:@"⌃V" tag:0];
    [m addAction:@selector(pageUp:) forKeyEquivalent:@"⌥V" tag:0];
    [m addAction:@selector(centerSelectionInVisibleArea:) forKeyEquivalent:@"⌃L" tag:0];
    [m addAction:@selector(moveBackwardAndModifySelection:) forKeyEquivalent:@"⇧⌃B" tag:0];
    [m addAction:@selector(moveForwardAndModifySelection:) forKeyEquivalent:@"⇧⌃F" tag:0];
    [m addAction:@selector(moveWordForwardAndModifySelection:) forKeyEquivalent:@"⇧⌥F" tag:0];
    [m addAction:@selector(moveWordBackwardAndModifySelection:) forKeyEquivalent:@"⇧⌥B" tag:0];
    [m addAction:@selector(moveUpAndModifySelection:) forKeyEquivalent:@"⇧↑" tag:0];
    [m addAction:@selector(moveUpAndModifySelection:) forKeyEquivalent:@"⇧⌃P" tag:0];
    [m addAction:@selector(moveDownAndModifySelection:) forKeyEquivalent:@"⇧↓" tag:0];
    [m addAction:@selector(moveDownAndModifySelection:) forKeyEquivalent:@"⇧⌃N" tag:0];
    [m addAction:@selector(moveToBeginningOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌃A" tag:0];
    [m addAction:@selector(moveToBeginningOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌘←" tag:0];
    [m addAction:@selector(moveToEndOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌃E" tag:0];
    [m addAction:@selector(moveToEndOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌘→" tag:0];
    [m addAction:@selector(moveToEndOfDocumentAndModifySelection:) forKeyEquivalent:@"⇧⌘↓" tag:0];
    [m addAction:@selector(moveToBeginningOfDocumentAndModifySelection:) forKeyEquivalent:@"⇧⌘↑" tag:0];
    [m addAction:@selector(pageDownAndModifySelection:) forKeyEquivalent:@"⇧⌃V" tag:0];
    [m addAction:@selector(pageUpAndModifySelection:) forKeyEquivalent:@"⇧⌥V" tag:0];
    [m addAction:@selector(moveWordRight:) forKeyEquivalent:@"⌥→" tag:0];
    [m addAction:@selector(moveWordLeft:) forKeyEquivalent:@"⌥←" tag:0];
    [m addAction:@selector(moveRightAndModifySelection:) forKeyEquivalent:@"⇧→" tag:0];
    [m addAction:@selector(moveLeftAndModifySelection:) forKeyEquivalent:@"⇧←" tag:0];
    [m addAction:@selector(moveWordRightAndModifySelection:) forKeyEquivalent:@"⇧⌥→" tag:0];
    [m addAction:@selector(moveWordLeftAndModifySelection:) forKeyEquivalent:@"⇧⌥←" tag:0];
    [m addAction:@selector(moveToLeftEndOfLine:) forKeyEquivalent:@"⌘←" tag:0];
    [m addAction:@selector(moveToRightEndOfLine:) forKeyEquivalent:@"⌘→" tag:0];
    [m addAction:@selector(moveToLeftEndOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌘←" tag:0];
    [m addAction:@selector(moveToRightEndOfLineAndModifySelection:) forKeyEquivalent:@"⇧⌘→" tag:0];
    [m addAction:@selector(scrollPageUp:) forKeyEquivalent:@"⇞" tag:0];
    [m addAction:@selector(scrollPageDown:) forKeyEquivalent:@"⇟" tag:0];
    [m addAction:@selector(scrollToBeginningOfDocument:) forKeyEquivalent:@"↖" tag:0];
    [m addAction:@selector(scrollToEndOfDocument:) forKeyEquivalent:@"↘" tag:0];
    [m addAction:@selector(transpose:) forKeyEquivalent:@"⌃T" tag:0];
    [m addAction:@selector(transposeWords:) forKeyEquivalent:@"⌥T" tag:0];
    [m addAction:@selector(selectAll:) forKeyEquivalent:@"⌘A" tag:0];
    [m addAction:@selector(insertNewline:) forKeyEquivalent:@"⌃O" tag:0];
    [m addAction:@selector(deleteForward:) forKeyEquivalent:@"⌦" tag:0];
    [m addAction:@selector(deleteBackward:) forKeyEquivalent:@"⌫" tag:0];
    [m addAction:@selector(deleteWordForward:) forKeyEquivalent:@"⌥⌦" tag:0];
    [m addAction:@selector(deleteWordBackward:) forKeyEquivalent:@"⌥⌫" tag:0];
    [m addAction:@selector(deleteToEndOfLine:) forKeyEquivalent:@"⌃K" tag:0];
    [m addAction:@selector(deleteToBeginningOfLine:) forKeyEquivalent:@"⌃W" tag:0];
    [m addAction:@selector(yank:) forKeyEquivalent:@"⌃Y" tag:0];
    [m addAction:@selector(setMark:) forKeyEquivalent:@"⌃Space" tag:0];
    [m addAction:@selector(complete:) forKeyEquivalent:@"⌥⎋" tag:0];
    [m addAction:@selector(cancelOperation:) forKeyEquivalent:@"⌘." tag:0];
    [m updateWithCocoaTextKeyBindings];
    return m;
}

+ (SRLocalShortcutMonitor *)mainMenuShortcuts
{
    SRLocalShortcutMonitor *m = [SRLocalShortcutMonitor new];
    [m addAction:@selector(hide:) forKeyEquivalent:@"⌘H" tag: 0];
    [m addAction:@selector(hideOtherApplications:) forKeyEquivalent:@"⌥⌘H" tag: 0];
    [m addAction:@selector(terminate:) forKeyEquivalent:@"⌘Q" tag: 0];
    [m addAction:@selector(newDocument:) forKeyEquivalent:@"⌘N" tag:0];
    [m addAction:@selector(openDocument:) forKeyEquivalent:@"⌘O" tag:0];
    [m addAction:@selector(performClose:) forKeyEquivalent:@"⌘W" tag:0];
    [m addAction:@selector(saveDocument:) forKeyEquivalent:@"⌘S" tag:0];
    [m addAction:@selector(saveDocumentAs:) forKeyEquivalent:@"⇧⌘S" tag:0];
    [m addAction:@selector(revertDocumentToSaved:) forKeyEquivalent:@"⌘R" tag:0];
    [m addAction:@selector(runPageLayout:) forKeyEquivalent:@"⇧⌘P" tag:0];
    [m addAction:@selector(print:) forKeyEquivalent:@"⌘P" tag:0];
    [m addAction:@selector(undo:) forKeyEquivalent:@"⌘Z" tag:0];
    [m addAction:@selector(redo:) forKeyEquivalent:@"⇧⌘Z" tag:0];
    [m addAction:@selector(cut:) forKeyEquivalent:@"⌘X" tag:0];
    [m addAction:@selector(copy:) forKeyEquivalent:@"⌘C" tag:0];
    [m addAction:@selector(paste:) forKeyEquivalent:@"⌘V" tag:0];
    [m addAction:@selector(pasteAsPlainText:) forKeyEquivalent:@"⌥⇧⌘V" tag:0];
    [m addAction:@selector(selectAll:) forKeyEquivalent:@"⌘A" tag:0];
    [m addAction:@selector(performTextFinderAction:) forKeyEquivalent:@"⌘F" tag:NSTextFinderActionShowFindInterface];
    [m addAction:@selector(performTextFinderAction:) forKeyEquivalent:@"⌥⌘F" tag:NSTextFinderActionShowReplaceInterface];
    [m addAction:@selector(performTextFinderAction:) forKeyEquivalent:@"⌘G" tag:NSTextFinderActionNextMatch];
    [m addAction:@selector(performTextFinderAction:) forKeyEquivalent:@"⇧⌘G" tag:NSTextFinderActionPreviousMatch];
    [m addAction:@selector(performTextFinderAction:) forKeyEquivalent:@"⌘E" tag:NSTextFinderActionSetSearchString];
    [m addAction:@selector(centerSelectionInVisibleArea:) forKeyEquivalent:@"⌘J" tag:0];
    [m addAction:@selector(showGuessPanel:) forKeyEquivalent:@"⇧⌘;" tag:0];
    [m addAction:@selector(checkSpelling:) forKeyEquivalent:@"⌘;" tag:0];
    [m addAction:@selector(orderFrontFontPanel:) forKeyEquivalent:@"⌘T" tag:0];
    [m addAction:@selector(addFontTrait:) forKeyEquivalent:@"⌘B" tag:NSBoldFontMask];
    [m addAction:@selector(addFontTrait:) forKeyEquivalent:@"⌘I" tag:NSItalicFontMask];
    [m addAction:@selector(underline:) forKeyEquivalent:@"⌘U" tag:0];
    [m addAction:@selector(modifyFont:) forKeyEquivalent:@"⌘=" tag:NSSizeUpFontAction];
    [m addAction:@selector(modifyFont:) forKeyEquivalent:@"⇧⌘=" tag:NSSizeUpFontAction];
    [m addAction:@selector(modifyFont:) forKeyEquivalent:@"⌘-" tag:NSSizeDownFontAction];
    [m addAction:@selector(modifyFont:) forKeyEquivalent:@"⇧⌘-" tag:NSSizeDownFontAction];
    [m addAction:@selector(orderFrontColorPanel:) forKeyEquivalent:@"⇧⌘C" tag:0];
    [m addAction:@selector(copyFont:) forKeyEquivalent:@"⌥⌘C" tag:0];
    [m addAction:@selector(pasteFont:) forKeyEquivalent:@"⌥⌘V" tag:0];
    [m addAction:@selector(alignLeft:) forKeyEquivalent:@"⇧⌘[" tag:0];
    [m addAction:@selector(alignCenter:) forKeyEquivalent:@"⇧⌘\\" tag:0];
    [m addAction:@selector(alignRight:) forKeyEquivalent:@"⇧⌘]" tag:0];
    [m addAction:@selector(copyRuler:) forKeyEquivalent:@"⌃⌘C" tag:0];
    [m addAction:@selector(pasteRuler:) forKeyEquivalent:@"⌃⌘V" tag:0];
    [m addAction:@selector(toggleToolbarShown:) forKeyEquivalent:@"⌥⌘T" tag:0];
    [m addAction:@selector(toggleSidebar:) forKeyEquivalent:@"⌃⌘S" tag:0];
    [m addAction:@selector(toggleFullScreen:) forKeyEquivalent:@"⌃⌘F" tag:0];
    [m addAction:@selector(performMiniaturize:) forKeyEquivalent:@"⌘M" tag:0];
    [m addAction:@selector(showHelp:) forKeyEquivalent:@"⇧⌘/" tag:0];
    return m;
}

+ (SRLocalShortcutMonitor *)clipboardShortcuts
{
    SRLocalShortcutMonitor *m = [SRLocalShortcutMonitor new];
    [m addAction:@selector(cut:) forKeyEquivalent:@"⌘X" tag:0];
    [m addAction:@selector(copy:) forKeyEquivalent:@"⌘C" tag:0];
    [m addAction:@selector(paste:) forKeyEquivalent:@"⌘V" tag:0];
    [m addAction:@selector(pasteAsPlainText:) forKeyEquivalent:@"⌥⇧⌘V" tag:0];
    [m addAction:@selector(undo:) forKeyEquivalent:@"⌘Z" tag:0];
    [m addAction:@selector(redo:) forKeyEquivalent:@"⇧⌘Z" tag:0];
    return m;
}

+ (SRLocalShortcutMonitor *)windowShortcuts
{
    SRLocalShortcutMonitor *m = [SRLocalShortcutMonitor new];
    [m addAction:@selector(performClose:) forKeyEquivalent:@"⌘W" tag:0];
    [m addAction:@selector(performMiniaturize:) forKeyEquivalent:@"⌘M" tag:0];
    [m addAction:@selector(toggleFullScreen:) forKeyEquivalent:@"⌃⌘F" tag:0];
    return m;
}

+ (SRLocalShortcutMonitor *)documentShortcuts
{
    SRLocalShortcutMonitor *m = [SRLocalShortcutMonitor new];
    [m addAction:@selector(print:) forKeyEquivalent:@"⌘P" tag:0];
    [m addAction:@selector(runPageLayout:) forKeyEquivalent:@"⇧⌘P" tag:0];
    [m addAction:@selector(revertDocumentToSaved:) forKeyEquivalent:@"⌘R" tag:0];
    [m addAction:@selector(saveDocument:) forKeyEquivalent:@"⌘S" tag:0];
    [m addAction:@selector(saveDocumentAs:) forKeyEquivalent:@"⇧⌥⌘S" tag:0];
    [m addAction:@selector(duplicateDocument:) forKeyEquivalent:@"⇧⌘S" tag:0];
    [m addAction:@selector(openDocument:) forKeyEquivalent:@"⌘O" tag:0];
    return m;
}

+ (SRLocalShortcutMonitor *)appShortcuts
{
    SRLocalShortcutMonitor *m = [SRLocalShortcutMonitor new];
    [m addAction:@selector(hide:) forKeyEquivalent:@"⌘H" tag:0];
    [m addAction:@selector(hideOtherApplications:) forKeyEquivalent:@"⌥⌘H" tag:0];
    [m addAction:@selector(terminate:) forKeyEquivalent:@"⌘Q" tag:0];
    return m;
}

#pragma mark Methods

- (BOOL)handleEvent:(nullable NSEvent *)anEvent withTarget:(nullable id)aTarget
{
    SRShortcut *shortcut = [SRShortcut shortcutWithEvent:anEvent];

    if (!shortcut)
    {
        os_trace_error("#Error Not a keyboard event");
        return NO;
    }

    __auto_type actions = [self allActionsForShortcut:shortcut];
    __block BOOL isHandled = NO;
    [actions enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SRShortcutAction *obj, NSUInteger idx, BOOL *stop) {
        *stop = isHandled = [obj performActionOnTarget:aTarget];
    }];
    return isHandled;
}

- (void)updateWithCocoaTextKeyBindings
{
    __auto_type systemKeyBindings = [self.class _parseSystemKeyBindings];
    __auto_type userKeyBindings = [self.class _parseUserKeyBindings];

    NSMutableDictionary *keyBindings = [systemKeyBindings mutableCopy];
    [keyBindings addEntriesFromDictionary:userKeyBindings];

    @synchronized (_shortcutToActions) {
        [keyBindings enumerateKeysAndObjectsUsingBlock:^(NSString *aKey, id aValue, BOOL *aStop) {
            if (![aKey isKindOfClass:NSString.class] || !aKey.length)
                return;

            SRShortcut *shortcut = [SRShortcut shortcutWithKeyBinding:aKey];
            if (!shortcut)
                return;

            if (![aValue isKindOfClass:NSArray.class])
                aValue = @[aValue];

            for (NSString *keyBinding in (NSArray *)aValue)
            {
                if (![keyBinding isKindOfClass:NSString.class])
                    continue;
                else if (!keyBinding.length || [keyBinding isEqualToString:@"noop:"])
                {
                    // Only remove actions with non-observed shortcuts.
                    __auto_type actions = [self->_shortcutToActions objectForKey:shortcut];
                    NSIndexSet *actionsToRemove = [actions indexesOfObjectsPassingTest:^BOOL(SRShortcutAction *obj, NSUInteger idx, BOOL *stop) {
                        return obj.observedObject == nil;
                    }];
                    [actions removeObjectsAtIndexes:actionsToRemove];
                }
                else
                    [self addShortcutAction:[SRShortcutAction shortcutActionWithShortcut:shortcut target:nil action:NSSelectorFromString(aValue) tag:0]];
            }
        }];
    }
}

#pragma mark Private

+ (NSDictionary<NSString *, id> *)_parseSystemKeyBindings
{
    NSBundle *appKitBundle = [NSBundle bundleWithIdentifier:@"com.apple.AppKit"];
    NSURL *systemKeyBindingsURL = [appKitBundle URLForResource:@"StandardKeyBinding" withExtension:@"dict"];
    NSDictionary *systemKeyBindings = nil;

    if (@available(macOS 10.13, *))
    {
        NSError *error = nil;
        systemKeyBindings = [NSDictionary dictionaryWithContentsOfURL:systemKeyBindingsURL error:&error];
        if (!systemKeyBindings)
        {
            os_trace_error_with_payload("#Error unable to read system key bindings", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "error", error.localizedDescription.UTF8String);
            });
            systemKeyBindings = @{};
        }
    }
    else
    {
        systemKeyBindings = [NSDictionary dictionaryWithContentsOfURL:systemKeyBindingsURL];
        if (!systemKeyBindings)
        {
            os_trace_error("#Error unable to read system key bindings");
            systemKeyBindings = @{};
        }
    }

    return systemKeyBindings;
}

+ (NSDictionary<NSString *, id> *)_parseUserKeyBindings
{
    NSURL *userKeyBindingsURL = [NSURL fileURLWithPath:[@"~/Library/KeyBindings/DefaultKeyBinding.dict" stringByExpandingTildeInPath]];
    NSDictionary *userKeyBindings = nil;

    if (@available(macOS 10.13, *))
    {
        NSError *error = nil;
        userKeyBindings = [NSDictionary dictionaryWithContentsOfURL:userKeyBindingsURL error:&error];
        if (!userKeyBindings)
        {
            os_trace_debug_with_payload("#Error unable to read user key bindings", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "error", error.localizedDescription.UTF8String);
            });
            userKeyBindings = @{};
        }
    }
    else
    {
        userKeyBindings = [NSDictionary dictionaryWithContentsOfURL:userKeyBindingsURL];
        if (!userKeyBindings)
        {
            os_trace_debug("#Error unable to read user key bindings");
            userKeyBindings = @{};
        }
    }

    return userKeyBindings;
}

@end
