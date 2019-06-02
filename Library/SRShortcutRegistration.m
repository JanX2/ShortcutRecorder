//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 3.0
//

#import <Carbon/Carbon.h>

#import "SRShortcutRegistration.h"


const OSType SRShortcutRegistrationSignature = 'SRSR';


@interface SRShortcutRegistration ()
@property (nullable) EventHotKeyRef carbonHotKey;
@property EventHotKeyID carbonHotKeyID;
@property (nonnull) SRShortcutAction action;
- (instancetype)initWithShortcut:(nullable SRShortcut *)aShortcut action:(nonnull SRShortcutAction)anAction;
- (void)invoke;
@end;


@interface _SRShortcutRegistrationMonitor : NSObject
@property (class, nonnull, readonly) _SRShortcutRegistrationMonitor *shared;
- (BOOL)provisionRegistration:(nonnull SRShortcutRegistration *)aRegistration error:(NSError * _Nullable *)outError;
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
}

+ (_SRShortcutRegistrationMonitor *)shared
{
    static _SRShortcutRegistrationMonitor *Shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Shared = [self new];
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

- (BOOL)provisionRegistration:(SRShortcutRegistration *)aRegistration error:(NSError * __autoreleasing *)outError
{
    static UInt32 CarbonID = 0;

    @synchronized (self)
    {
        if (CarbonID == UINT32_MAX)
            [NSException raise:NSInternalInconsistencyException
                        format:@"Maximum number of shortcut registrations reached."];

        EventHotKeyRef hotKey = NULL;
        EventHotKeyID hotKeyID = {SRShortcutRegistrationSignature, ++CarbonID};
        OSStatus error = RegisterEventHotKey(aRegistration.shortcut.carbonKeyCode,
                                             aRegistration.shortcut.carbonModifierFlags,
                                             hotKeyID,
                                             GetEventDispatcherTarget(),
                                             0,
                                             &hotKey);

        if (error != noErr)
        {
            if (outError)
                *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:nil];

            return NO;
        }

        if (_registrations.count == 0)
        {
            static const EventTypeSpec eventSpec[1] = { { kEventClassKeyboard, kEventHotKeyPressed } };
            error = InstallEventHandler(GetEventDispatcherTarget(),
                                        (EventHandlerProcPtr)SRCarbonEventHandler,
                                        1,
                                        eventSpec,
                                        (__bridge void *)self,
                                        &_carbonEventHandler);

            if (error != noErr)
            {
                if (outError)
                    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:nil];


                return NO;
            }
        }

        NSAssert(aRegistration.isValid, @"Registration must be valid");
        aRegistration.carbonHotKey = hotKey;
        aRegistration.carbonHotKeyID = hotKeyID;
        [_registrations addObject:aRegistration];

        return YES;
    }
}

- (OSStatus)sendCarbonEvent:(EventRef)anEvent
{
    if (!anEvent)
        return eventNotHandledErr;

    if (GetEventClass(anEvent) != kEventClassKeyboard)
        return eventNotHandledErr;

    EventHotKeyID hotKeyID;
    OSStatus error = GetEventParameter(anEvent,
                                       kEventParamDirectObject,
                                       typeEventHotKeyID,
                                       NULL,
                                       sizeof(hotKeyID),
                                       NULL,
                                       &hotKeyID);

    if (error != noErr)
        return eventNotHandledErr;

    if (hotKeyID.id == 0 || hotKeyID.signature != SRShortcutRegistrationSignature)
        return eventNotHandledErr;

    @synchronized (self)
    {
        NSUInteger i = [_registrations indexOfObjectPassingTest:^(SRShortcutRegistration *obj, NSUInteger idx, BOOL *stop) {
            return (BOOL)(obj.carbonHotKeyID.id == hotKeyID.id);
        }];

        if (i != NSNotFound)
            [_registrations[i] invoke];
    }

    return noErr;
}

- (void)removeRegistration:(SRShortcutRegistration *)aRegistration
{
    @synchronized (self)
    {
        NSUInteger i = [_registrations indexOfObject:aRegistration];

        if (i == NSNotFound)
            return;

        NSAssert(aRegistration.isValid, @"Registration must be valid");
        UnregisterEventHotKey(aRegistration.carbonHotKey);
        [_registrations removeObjectAtIndex:i];
        aRegistration.carbonHotKey = NULL;
        aRegistration.carbonHotKeyID = (EventHotKeyID){SRShortcutRegistrationSignature, 0};

        if (!_registrations.count && _carbonEventHandler)
        {
            RemoveEventHandler(_carbonEventHandler);
            _carbonEventHandler = NULL;
        }
    }
}

@end


static void *_SRShortcutRegistrationContext = &_SRShortcutRegistrationContext;


@implementation SRShortcutRegistration
{
    SRShortcutAction _action;
    __weak NSObject *_observedObject;
    NSString *_observedKeyPath;
}

+ (instancetype)registerShortcut:(SRShortcut *)aShortcut
                      withAction:(SRShortcutAction)anAction
                           error:(NSError *__autoreleasing *)outError
{
    SRShortcutRegistration *registration = [[self alloc] initWithShortcut:aShortcut action:anAction];

    if ([_SRShortcutRegistrationMonitor.shared provisionRegistration:registration error:outError])
        return registration;
    else
        return nil;
}

+ (nullable instancetype)registerAutoupdatingShortcutWithKeyPath:(NSString *)aKeyPath
                                                        toObject:(NSObject *)anObject
                                                          action:(SRShortcutAction)anAction
                                                           error:(NSError * _Nullable *)outError
{
    SRShortcutRegistration *registration = [[self alloc] initWithShortcut:nil action:anAction];
    [anObject addObserver:registration
               forKeyPath:aKeyPath
                  options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                  context:_SRShortcutRegistrationContext];
    return registration;
}

- (instancetype)initWithShortcut:(SRShortcut *)aShortcut action:(SRShortcutAction)anAction
{
    self = [super init];

    if (self)
    {
        _action = anAction;
        _shortcut = aShortcut;
        _dispatchQueue = dispatch_get_main_queue();
        _isValid = YES;
    }

    return self;
}

- (void)dealloc
{
    [self invalidate];
}

#pragma mark Methods

- (void)invoke
{
    dispatch_async(_dispatchQueue, dispatch_block_create(DISPATCH_BLOCK_DETACHED, ^{
        if (self.isValid)
            self->_action(self);
    }));
}

- (void)invalidate
{
    @synchronized (self)
    {
        if (_observedObject)
            [_observedObject removeObserver:self
                                 forKeyPath:_observedKeyPath
                                    context:_SRShortcutRegistrationContext];

        _observedObject = nil;

        if (_carbonHotKey)
            [_SRShortcutRegistrationMonitor.shared removeRegistration:self];

        _isValid = NO;
    }
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(NSObject *)anObject
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)aChange
                       context:(void *)aContext
{
    if (aContext == _SRShortcutRegistrationContext)
    {
        SRShortcut *newShortcut = aChange[NSKeyValueChangeNewKey];

        // NSController subclasses are notable for not populating New and Old key of the change dict.
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
            if (!self.isValid)
                return;

            if (newShortcut == self.shortcut || [self.shortcut isEqual:newShortcut])
                return;

            [self willChangeValueForKey:@"shortcut"];
            [_SRShortcutRegistrationMonitor.shared removeRegistration:self];
            _shortcut = newShortcut;
            if (_shortcut)
                [_SRShortcutRegistrationMonitor.shared provisionRegistration:self error:nil];
            [self didChangeValueForKey:@"shortcut"];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation NSEvent (SRShortcutRegistration)

+ (id)SR_addGlobalMonitorForShortcut:(SRShortcut *)aShortcut handler:(void (^)(NSEvent * _Nonnull))aHandler
{
    return [self addGlobalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *anEvent) {
        if (aShortcut.keyCode == anEvent.keyCode && aShortcut.modifierFlags == anEvent.modifierFlags)
            aHandler(anEvent);
    }];
}

+ (id)SR_addLocalMonitorForShortcut:(SRShortcut *)aShortcut handler:(NSEvent * _Nullable (^)(NSEvent * _Nonnull))aHandler
{
    return [self addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *anEvent) {
        if (aShortcut.keyCode == anEvent.keyCode && aShortcut.modifierFlags == anEvent.modifierFlags)
            return aHandler(anEvent);
        else
            return anEvent;
    }];
}

@end
