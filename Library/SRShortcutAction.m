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
    os_activity_initiate("-[SRShortcutAction setShortcut:]", OS_ACTIVITY_FLAG_DEFAULT, ^{
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
    os_activity_initiate("-[SRShortcutAction setObservedObject:withKeyPath:]", OS_ACTIVITY_FLAG_DEFAULT, ^{
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
    os_activity_initiate("-[SRShortcutAction performActionOnTarget:]", OS_ACTIVITY_FLAG_DEFAULT, ^{
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

    os_activity_initiate("-[SRShortcutAction observeValueForKeyPath:ofObject:change:context:]", OS_ACTIVITY_FLAG_DEFAULT, ^{
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
    NSMutableDictionary<SRShortcut *, NSMutableOrderedSet<SRShortcutAction *> *> *_shortcutToKeyDownActions;
    NSMutableDictionary<SRShortcut *, NSMutableOrderedSet<SRShortcutAction *> *> *_shortcutToKeyUpActions;
    NSCountedSet<SRShortcut *> *_shortcuts;
    NSCountedSet<SRShortcutAction *> *_actions;
    NSMutableSet<SRShortcutAction *> *_keyUpActions;
    NSMutableSet<SRShortcutAction *> *_keyDownActions;
}
@end


@implementation SRShortcutMonitor

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _shortcutToKeyDownActions = [NSMutableDictionary new];
        _shortcutToKeyUpActions = [NSMutableDictionary new];
        _shortcuts = [NSCountedSet new];
        _actions = [NSCountedSet new];
        _keyUpActions = [NSMutableSet new];
        _keyDownActions = [NSMutableSet new];
    }

    return self;
}

- (void)dealloc
{
    for (SRShortcutAction *action in _actions)
    {
        [action removeObserver:self forKeyPath:@"shortcut" context:_SRShortcutMonitorContext];
    }
}

#pragma mark Properties

- (NSArray<SRShortcutAction *> *)actions
{
    @synchronized (_actions)
    {
        return _actions.allObjects;
    }
}

- (NSArray<SRShortcut *> *)shortcuts
{
    @synchronized (_actions)
    {
        return _shortcuts.allObjects;
    }
}

#pragma mark Methods

- (NSArray<SRShortcutAction *> *)actionsForKeyEvent:(SRKeyEventType)aKeyEvent
{
    @synchronized (_actions)
    {
        return [self _actionsForKeyEvent:aKeyEvent].allObjects;
    }
}

- (NSArray<SRShortcutAction *> *)actionsForShortcut:(SRShortcut *)aShortcut keyEvent:(SRKeyEventType)aKeyEvent
{
    @synchronized (_actions)
    {
        __auto_type result = [self _actionsForShortcut:aShortcut keyEvent:aKeyEvent];
        return result != nil ? [NSArray arrayWithArray:result.array] : [NSArray new];
    }
}

- (SRShortcutAction *)actionForShortcut:(SRShortcut *)aShortcut keyEvent:(SRKeyEventType)aKeyEvent
{
    @synchronized (_actions)
    {
        return [[self _actionsForShortcut:aShortcut keyEvent:aKeyEvent] lastObject];
    }
}

- (void)addAction:(SRShortcutAction *)anAction forKeyEvent:(SRKeyEventType)aKeyEvent
{
    @synchronized (_actions)
    {
        __auto_type keyEventActions = [self _actionsForKeyEvent:aKeyEvent];

        if (![keyEventActions containsObject:anAction])
        {
            [_actions addObject:anAction];
            NSAssert([_actions countForObject:anAction] <= 2, @"Action is added too many times");
            [keyEventActions addObject:anAction];

            if ([_actions countForObject:anAction] == 1)
            {
                [anAction addObserver:self
                           forKeyPath:@"shortcut"
                              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                              context:_SRShortcutMonitorContext];
            }

            if (anAction.shortcut)
                [self _addAction:anAction toShortcut:anAction.shortcut forKeyEvent:aKeyEvent];
        }
        else if (anAction.shortcut)
        {
            __auto_type shortcutActions = [self _actionsForShortcut:anAction.shortcut keyEvent:aKeyEvent];
            NSAssert(shortcutActions.count, @"Action was not added to the shortcut");
            NSUInteger fromIndex = [shortcutActions indexOfObject:anAction];
            NSAssert(fromIndex != NSNotFound, @"Action was not added to the shortcut");
            [shortcutActions moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] toIndex:shortcutActions.count - 1];
        }
    }
}

- (void)removeAction:(SRShortcutAction *)anAction forKeyEvent:(SRKeyEventType)aKeyEvent
{
    @synchronized (_actions)
    {
        __auto_type keyEventActions = [self _actionsForKeyEvent:aKeyEvent];
        if (![keyEventActions containsObject:anAction])
            return;

        [keyEventActions removeObject:anAction];
        [_actions removeObject:anAction];

        if (![_actions countForObject:anAction])
            [anAction removeObserver:self forKeyPath:@"shortcut" context:_SRShortcutMonitorContext];

        if (anAction.shortcut)
            [self _removeAction:anAction fromShortcut:anAction.shortcut forKeyEvent:aKeyEvent];
    }
}

- (void)removeAction:(SRShortcutAction *)anAction
{
    @synchronized (_actions)
    {
        [self removeAction:anAction forKeyEvent:SRKeyEventTypeDown];
        [self removeAction:anAction forKeyEvent:SRKeyEventTypeUp];
    }
}

- (void)removeAllActionsForShortcut:(SRShortcut *)aShortcut keyEvent:(SRKeyEventType)aKeyEvent
{
    @synchronized (_actions)
    {
        for (SRShortcutAction *action in [self actionsForShortcut:aShortcut keyEvent:aKeyEvent])
        {
            [self removeAction:action forKeyEvent:aKeyEvent];
        }
    }
}

- (void)removeAllActionsForKeyEvent:(SRKeyEventType)aKeyEvent
{
    @synchronized (_actions)
    {
        for (SRShortcutAction *action in [self actionsForKeyEvent:aKeyEvent])
        {
            [self removeAction:action forKeyEvent:aKeyEvent];
        }
    }
}

- (void)removeAllActionsForShortcut:(SRShortcut *)aShortcut
{
    @synchronized (_actions)
    {
        [self removeAllActionsForShortcut:aShortcut keyEvent:SRKeyEventTypeDown];
        [self removeAllActionsForShortcut:aShortcut keyEvent:SRKeyEventTypeUp];
    }
}

- (void)removeAllActions
{
    @synchronized (_actions)
    {
        for (SRShortcutAction *action in _actions)
        {
            [action removeObserver:self forKeyPath:@"shortcut" context:_SRShortcutMonitorContext];
        }

        [_shortcutToKeyDownActions removeAllObjects];
        [_shortcutToKeyUpActions removeAllObjects];
        [_actions removeAllObjects];
        [_keyUpActions removeAllObjects];
        [_keyDownActions removeAllObjects];

        __auto_type oldShortcuts = _shortcuts;
        _shortcuts = [NSCountedSet new];

        for (SRShortcut *shortcut in oldShortcuts)
        {
            [self didRemoveShortcut:shortcut];
        }
    }
}

- (void)didAddShortcut:(SRShortcut *)aShortcut
{
}

- (void)didRemoveShortcut:(SRShortcut *)aShortcut
{
}

#pragma mark Private

- (NSMutableSet<SRShortcutAction *> *)_actionsForKeyEvent:(SRKeyEventType)aKeyEvent
{
    switch (aKeyEvent)
    {
        case SRKeyEventTypeDown:
            return _keyDownActions;
        case SRKeyEventTypeUp:
            return _keyUpActions;
        default:
            [NSException raise:NSInvalidArgumentException format:@"Unexpected keyboard event type %lu", aKeyEvent];
            return nil;
    }
}

- (NSMutableDictionary<SRShortcut *, NSMutableOrderedSet<SRShortcutAction *> *> *)_shortcutToActionsForKeyEvent:(SRKeyEventType)aKeyEvent
{
    switch (aKeyEvent)
    {
        case SRKeyEventTypeDown:
            return _shortcutToKeyDownActions;
        case SRKeyEventTypeUp:
            return _shortcutToKeyUpActions;
        default:
            [NSException raise:NSInvalidArgumentException format:@"Unexpected keyboard event type %lu", aKeyEvent];
            return nil;
    }
}

- (nullable NSMutableOrderedSet<SRShortcutAction *> *)_actionsForShortcut:(SRShortcut *)aShortcut keyEvent:(SRKeyEventType)aKeyEvent
{
    return [[self _shortcutToActionsForKeyEvent:aKeyEvent] objectForKey:aShortcut];
}

- (void)_actionDidChangeShortcut:(SRShortcutAction *)anAction from:(SRShortcut *)oldShortcut to:(SRShortcut *)newShortcut
{
    BOOL isKeyDownAction = [_keyDownActions containsObject:anAction];
    BOOL isKeyUpAction = [_keyUpActions containsObject:anAction];

    if (oldShortcut)
    {
        if (isKeyDownAction)
            [self _removeAction:anAction fromShortcut:oldShortcut forKeyEvent:SRKeyEventTypeDown];

        if (isKeyUpAction)
            [self _removeAction:anAction fromShortcut:oldShortcut forKeyEvent:SRKeyEventTypeUp];
    }

    if (newShortcut)
    {
        if (isKeyDownAction)
            [self _addAction:anAction toShortcut:newShortcut forKeyEvent:SRKeyEventTypeDown];

        if (isKeyUpAction)
            [self _addAction:anAction toShortcut:newShortcut forKeyEvent:SRKeyEventTypeUp];
    }
}

/*!
 Add the action to the shortcut, optionally calling the hook.
 */
- (void)_addAction:(SRShortcutAction *)anAction toShortcut:(SRShortcut *)aShortcut forKeyEvent:(SRKeyEventType)aKeyEvent
{
    __auto_type shortcutToActions = [self _shortcutToActionsForKeyEvent:aKeyEvent];
    __auto_type shortcutActions = shortcutToActions[aShortcut];
    NSParameterAssert(![shortcutActions containsObject:anAction]);

    BOOL isNewShortcut = [_shortcuts countForObject:aShortcut] == 0;

    if (!shortcutActions)
    {
        shortcutActions = [NSMutableOrderedSet orderedSetWithObject:anAction];
        shortcutToActions[aShortcut] = shortcutActions;
        [_shortcuts addObject:aShortcut];
    }
    else
        [shortcutActions addObject:anAction];

    if (isNewShortcut)
        [self didAddShortcut:aShortcut];
}

/*!
 Remove the action from the shortcut, optionally calling the hook.
 */
- (void)_removeAction:(SRShortcutAction *)anAction fromShortcut:(SRShortcut *)aShortcut forKeyEvent:(SRKeyEventType)aKeyEvent
{
    NSParameterAssert([_shortcuts containsObject:aShortcut]);

    __auto_type shortcutToActions = [self _shortcutToActionsForKeyEvent:aKeyEvent];
    __auto_type shortcutActions = shortcutToActions[aShortcut];
    NSParameterAssert([shortcutActions containsObject:anAction]);

    [shortcutActions removeObject:anAction];

    if (!shortcutActions.count)
    {
        shortcutToActions[aShortcut] = nil;
        [_shortcuts removeObject:aShortcut];
    }

    if (![_shortcuts countForObject:aShortcut])
        [self didRemoveShortcut:aShortcut];
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(NSObject *)anObject
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)aChange
                       context:(void *)aContext
{
    if (aContext == _SRShortcutMonitorContext)
    {
        SRShortcut *oldShortcut = aChange[NSKeyValueChangeOldKey];
        SRShortcut *newShortcut = aChange[NSKeyValueChangeNewKey];

        @synchronized (_actions)
        {
            [self _actionDidChangeShortcut:(SRShortcutAction *)anObject
                                      from:((id)oldShortcut == NSNull.null) ? nil : oldShortcut
                                        to:((id)newShortcut == NSNull.null) ? nil : newShortcut];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation SRShortcutMonitor (SRShortcutMonitorConveniences)

- (SRShortcutAction *)addAction:(SEL)anAction forKeyEquivalent:(NSString *)aKeyEquivalent tag:(NSInteger)aTag
{
    SRShortcut *shortcut = [SRShortcut shortcutWithKeyEquivalent:aKeyEquivalent];

    if (!shortcut)
        return nil;

    SRShortcutAction *action = [SRShortcutAction shortcutActionWithShortcut:shortcut target:nil action:anAction tag:aTag];
    [self addAction:action forKeyEvent:SRKeyEventTypeDown];
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
    NSMutableDictionary<NSNumber *, SRShortcut *> *_hotKeyIdToShortcut;
    NSMapTable<SRShortcut *, id> *_shortcutToHotKeyRef;
    NSMutableDictionary<SRShortcut *, NSNumber *> *_shortcutToHotKeyId;
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
        _hotKeyIdToShortcut = [NSMutableDictionary new];
        _shortcutToHotKeyRef = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                                                     valueOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality];
        _shortcutToHotKeyId = [NSMutableDictionary new];
        _dispatchQueue = dispatch_get_main_queue();
    }

    return self;
}

- (void)dealloc
{
    for (SRShortcut *shortcut in _shortcuts)
        [self _unregisterHotKeyForShortcutIfNeeded:shortcut];

    [self _removeEventHandlerIfNeeded];
}

#pragma mark Methods

- (void)resume
{
    @synchronized (_actions)
    {
        os_trace_debug("Global Shortcut Monitor counter: %ld -> %ld", _disableCounter, _disableCounter - 1);
        _disableCounter -= 1;

        if (_disableCounter == 0)
        {
            for (SRShortcut *shortcut in _shortcuts)
                [self _registerHotKeyForShortcutIfNeeded:shortcut];
        }

        [self _installEventHandlerIfNeeded];
    }
}

- (void)pause
{
    @synchronized (_actions)
    {
        os_trace_debug("Global Shortcut Monitor counter: %ld -> %ld", _disableCounter, _disableCounter + 1);
        _disableCounter += 1;

        if (_disableCounter == 1)
        {
            for (SRShortcut *shortcut in _shortcuts)
                [self _unregisterHotKeyForShortcutIfNeeded:shortcut];
        }

        [self _removeEventHandlerIfNeeded];
    }
}

- (OSStatus)handleEvent:(EventRef)anEvent
{
    __block OSStatus error = noErr;

    os_activity_initiate("-[SRGlobalShortcutMonitor handleEvent:]", OS_ACTIVITY_FLAG_DETACHED, ^{
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

        @synchronized (self->_actions)
        {
            SRShortcut *shortcut = [self->_hotKeyIdToShortcut objectForKey:@(hotKeyID.id)];

            if (!shortcut)
            {
                os_trace("Unregistered hot key with id %u and signature %u", hotKeyID.id, hotKeyID.signature);
                error = eventNotHandledErr;
                return;
            }

            SRKeyEventType eventType = 0;
            switch (GetEventKind(anEvent))
            {
                case kEventHotKeyPressed:
                    eventType = SRKeyEventTypeDown;
                    break;
                case kEventHotKeyReleased:
                    eventType = SRKeyEventTypeUp;
                    break;
                default:
                    os_trace("#Error Unexpected key event of type %u", GetEventKind(anEvent));
                    error = eventNotHandledErr;
                    return;
            }

            __auto_type actions = [self actionsForShortcut:shortcut keyEvent:eventType];

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

- (void)didAddEventHandler
{
    os_trace_debug("Added Carbon HotKey Event Handler");
}

- (void)didRemoveEventHandler
{
    os_trace_debug("Removed Carbon HotKey Event Handler");
}

#pragma mark Private

- (void)_installEventHandlerIfNeeded
{
    if (_carbonEventHandler)
        return;

    if (_disableCounter > 0 || !_shortcutToHotKeyRef.count)
        return;

    static const EventTypeSpec eventSpec[] = {
        { kEventClassKeyboard, kEventHotKeyPressed },
        { kEventClassKeyboard, kEventHotKeyReleased }
    };
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
    else
        [self didAddEventHandler];
}

- (void)_removeEventHandlerIfNeeded
{
    if (!_carbonEventHandler)
        return;

    // _shortcutToHotKeyRef is checked instead of _shortcuts because the handler is removed after the registrations.
    if (_disableCounter <= 0 && _shortcutToHotKeyRef.count)
        return;

    os_trace("Removing Carbon hot key event handler");
    OSStatus error = RemoveEventHandler(_carbonEventHandler);

    if (error != noErr)
        os_trace_error("#Error Failed to remove event handler: %d", error);

    // Assume that an error to remove the handler is due to the latter being invalid.
    _carbonEventHandler = NULL;
    [self didRemoveEventHandler];
}

- (void)_registerHotKeyForShortcutIfNeeded:(SRShortcut *)aShortcut
{
    EventHotKeyRef hotKey = (__bridge EventHotKeyRef)([_shortcutToHotKeyRef objectForKey:aShortcut]);

    if (hotKey)
        return;

    if (aShortcut.keyCode == SRKeyCodeNone)
    {
        os_trace_error("#Error Shortcut without a key code cannot be registered as Carbon hot key");
        return;
    }

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

- (void)_unregisterHotKeyForShortcutIfNeeded:(SRShortcut *)aShortcut
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

#pragma mark SRShortcutMonitor

- (void)didAddShortcut:(SRShortcut *)aShortcut
{
    [self _registerHotKeyForShortcutIfNeeded:aShortcut];
    [self _installEventHandlerIfNeeded];
}

- (void)didRemoveShortcut:(SRShortcut *)aShortcut
{
    [self _unregisterHotKeyForShortcutIfNeeded:aShortcut];
    [self _removeEventHandlerIfNeeded];
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

    SRKeyEventType eventType = 0;
    switch (anEvent.type)
    {
        case NSEventTypeKeyDown:
            eventType = SRKeyEventTypeDown;
            break;
        case NSEventTypeKeyUp:
            eventType = SRKeyEventTypeUp;
            break;
        case NSEventTypeFlagsChanged:
        {
            __auto_type keyCode = anEvent.keyCode;
            if (keyCode == kVK_Command || keyCode == kVK_RightCommand)
                eventType = anEvent.modifierFlags & NSEventModifierFlagCommand ? SRKeyEventTypeDown : SRKeyEventTypeUp;
            else if (keyCode == kVK_Option || keyCode == kVK_RightOption)
                eventType = anEvent.modifierFlags & NSEventModifierFlagOption ? SRKeyEventTypeDown : SRKeyEventTypeUp;
            else if (keyCode == kVK_Shift || keyCode == kVK_RightShift)
                eventType = anEvent.modifierFlags & NSEventModifierFlagShift ? SRKeyEventTypeDown : SRKeyEventTypeUp;
            else if (keyCode == kVK_Control || keyCode == kVK_RightControl)
                eventType = anEvent.modifierFlags & NSEventModifierFlagControl ? SRKeyEventTypeDown : SRKeyEventTypeUp;
            else
            {
                os_trace("#Error Unexpected key code %hu for the FlagsChanged event", keyCode);
                return NO;
            }
            break;
        }
        default:
            os_trace("#Error Unexpected key event of type %lu", anEvent.type);
            return NO;
    }

    __auto_type actions = [self actionsForShortcut:shortcut keyEvent:eventType];
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

    @synchronized (_actions) {
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
                    // Only remove actions with static shortcuts.
                    __auto_type actions = [self->_shortcutToKeyDownActions objectForKey:shortcut];
                    NSIndexSet *actionsToRemove = [actions indexesOfObjectsPassingTest:^BOOL(SRShortcutAction *obj, NSUInteger idx, BOOL *stop) {
                        return obj.observedObject == nil;
                    }];
                    [actions removeObjectsAtIndexes:actionsToRemove];
                }
                else
                    [self addAction:[SRShortcutAction shortcutActionWithShortcut:shortcut target:nil action:NSSelectorFromString(aValue) tag:0]
                        forKeyEvent:SRKeyEventTypeDown];
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
