//
//  PTHotKey+ShortcutRecorder.m
//  ShortcutRecorder
//
//  Created by Ilya Kulakov on 27.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "PTHotKey+ShortcutRecorder.h"
#import <ShortcutRecorder/SRCommon.h>


extern NSString* const SRShortcutCodeKey;
extern NSString* const SRShortcutFlagsKey;

@implementation PTHotKey (ShortcutRecorder)

+ (PTHotKey *)hotKeyWithIdentifier:(id)anIdentifier
                          keyCombo:(NSDictionary *)aKeyCombo
                            target:(id)aTarget
                            action:(SEL)anAction
{
    PTKeyCombo *newKeyCombo = [[PTKeyCombo alloc] initWithKeyCode:[[aKeyCombo objectForKey:SRShortcutCodeKey] integerValue]
                                                        modifiers:SRCocoaToCarbonFlags([[aKeyCombo objectForKey:SRShortcutFlagsKey] unsignedIntegerValue])];
    PTHotKey *newHotKey = [[PTHotKey alloc] initWithIdentifier:anIdentifier keyCombo:newKeyCombo];
    [newHotKey setTarget:aTarget];
    [newHotKey setAction:anAction];
    return newHotKey;
}

@end
