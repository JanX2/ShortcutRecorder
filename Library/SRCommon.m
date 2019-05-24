//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006-2018 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim
//      Ilya Kulakov

#import "SRCommon.h"


NSBundle *SRBundle()
{
    static dispatch_once_t onceToken;
    static NSBundle *Bundle = nil;
    dispatch_once(&onceToken, ^{
        Bundle = [NSBundle bundleWithIdentifier:@"com.kulakov.ShortcutRecorder"];

        if (!Bundle)
        {
            // Could be a CocoaPods framework with embedded resources bundle.
            // Look up "use_frameworks!" and "resources_bundle" in CocoaPods documentation.
            Bundle = [NSBundle bundleWithIdentifier:@"org.cocoapods.ShortcutRecorder"];

            if (!Bundle)
            {
                Class c = NSClassFromString(@"SRRecorderControl");

                if (c)
                {
                    Bundle = [NSBundle bundleForClass:c];
                }
            }

            if (Bundle)
            {
                Bundle = [NSBundle bundleWithPath:[Bundle pathForResource:@"ShortcutRecorder" ofType:@"bundle"]];
            }
        }
    });

    if (!Bundle)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Unable to find bundle with resources."
                                     userInfo:nil];
    }
    else
    {
        return Bundle;
    }
}


NSString *SRLoc(NSString *aKey)
{
    return NSLocalizedStringFromTableInBundle(aKey, @"ShortcutRecorder", SRBundle(), nil);
}


NSImage *SRImage(NSString *anImageName)
{
    return [SRBundle() imageForResource:anImageName];
}


@implementation NSObject (SRCommon)

- (BOOL)SR_isMostSpecializedEqual:(NSObject *)anObject
{
    if (anObject == self)
        return YES;
    else if (!anObject)
        return NO;

    NSObject *parent = nil;
    NSObject *child = nil;

    if ([self isKindOfClass:anObject.class])
    {
        parent = anObject;
        child = self;
    }
    else if ([anObject isKindOfClass:self.class])
    {
        parent = self;
        child = anObject;
    }
    else
        return NO;

    return [child isEqual:parent];

}

@end
