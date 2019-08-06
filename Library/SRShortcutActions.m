//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <os/trace.h>
#import <os/activity.h>

#import "SRShortcutActions.h"


@implementation SRShortcutActions
{
    NSMutableDictionary<SRShortcut *, NSValue *> *_actions;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _actions = [NSMutableDictionary new];
    }

    return self;
}

#pragma mark Methods

- (NSArray<SRShortcut *> *)allShortcuts
{
    return _actions.allKeys;
}

- (NSArray<NSValue *> *)allActions
{
    return _actions.allValues;
}

- (SEL)actionForShortcut:(SRShortcut *)aShortcut
{
    return _actions[aShortcut].pointerValue;
}

- (SEL)actionForKeyEquivalent:(NSString *)aKeyEquivalent
{
    return [self actionForShortcut:[SRShortcut shortcutWithKeyEquivalent:aKeyEquivalent]];
}

- (void)setAction:(SEL)anAction forShortcut:(SRShortcut *)aShortcut
{
    _actions[aShortcut] = [NSValue valueWithPointer:anAction];
}

- (void)setAction:(SEL)anAction forKeyEquivalent:(NSString *)aKeyEquivalent
{
    [self setAction:anAction forShortcut:[SRShortcut shortcutWithKeyEquivalent:aKeyEquivalent]];
}

- (void)removeActionForShortcut:(SRShortcut *)aShortcut
{
    _actions[aShortcut] = nil;
}

- (void)removeActionForKeyEquivalent:(NSString *)aKeyEquivalent
{
    [self removeActionForShortcut:[SRShortcut shortcutWithKeyEquivalent:aKeyEquivalent]];
}

- (BOOL)performShortcut:(SRShortcut *)aShortcut onTarget:(id)aTarget
{
    __block BOOL isPerformed = NO;

    os_activity_initiate("performShortcut:withTarget:", OS_ACTIVITY_FLAG_DEFAULT, ^{
        SEL action = [self actionForShortcut:aShortcut];
        if (!action)
        {
            os_trace_debug_with_payload("#Error no action for the shortcut", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "shortcut", aShortcut.description.UTF8String);
            });
            return;
        }

        NSMethodSignature *sig = [aTarget methodSignatureForSelector:action];
        if (!sig)
        {
            os_trace_debug_with_payload("#Error target does not respond to the action", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "action", NSStringFromSelector(action).UTF8String);
            });
            return;
        }

        if (strcmp(sig.methodReturnType, "v") != 0)
        {
            os_trace_debug_with_payload("#Error target does not respond to the action", ^(xpc_object_t d) {
                xpc_dictionary_set_string(d, "action", NSStringFromSelector(action).UTF8String);
            });
            return;
        }

        IMP actionMethod = [aTarget methodForSelector:action];

        switch (sig.numberOfArguments)
        {
            case 2:
                ((void (*)(id, SEL))actionMethod)(aTarget, action);
                isPerformed = YES;
                break;
            case 3:
                ((void (*)(id, SEL, id))actionMethod)(aTarget, action, self);
                isPerformed = YES;
                break;
            default:
                os_trace_debug_with_payload("#Error too many arguments for the action", ^(xpc_object_t d) {
                    xpc_dictionary_set_string(d, "action", NSStringFromSelector(action).UTF8String);
                });
                break;
        }
    });
    return isPerformed;
}

- (BOOL)performEvent:(NSEvent *)anEvent onTarget:(id)aTarget
{
    return [self performShortcut:[SRShortcut shortcutWithEvent:anEvent] onTarget:aTarget];
}

- (BOOL)performKeyEquivalent:(NSString *)aKeyEquivalent onTarget:(id)aTarget
{
    return [self performShortcut:[SRShortcut shortcutWithKeyEquivalent:aKeyEquivalent] onTarget:aTarget];
}

- (NSValue *)objectForKeyedSubscript:(SRShortcut *)aKey
{
    return _actions[aKey];
}

- (void)setObject:(NSValue *)anObject forKeyedSubscript:(SRShortcut *)aKey
{
    _actions[aKey] = anObject;
}

@end
