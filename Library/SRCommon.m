//
//  Copyright 2006 ShortcutRecorder Contributors
//  CC BY 3.0
//

#import <objc/runtime.h>

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

- (BOOL)SR_isEqual:(nullable NSObject *)anObject usingSelector:(SEL)aSelector ofCommonAncestor:(Class)anAncestor
{
    typedef BOOL (*IsEqualTo)(id, SEL, id);

    if (anObject == self)
        return YES;
    else if (!anObject)
        return NO;
    else if ([self isKindOfClass:anObject.class])
        return ((IsEqualTo)[self methodForSelector:aSelector])(self, aSelector, anObject);
    else if ([anObject isKindOfClass:self.class])
        return ((IsEqualTo)[anObject methodForSelector:aSelector])(anObject, aSelector, self);
    else if ([anObject isKindOfClass:anAncestor])
    {
        NSAssert([self isKindOfClass:anAncestor], @"Receiver must be an instance of the specified ancestor.");
        IsEqualTo selfImp = (IsEqualTo)[self methodForSelector:aSelector];
        IsEqualTo objectImp = (IsEqualTo)[anObject methodForSelector:aSelector];

        if (selfImp == objectImp)
            return selfImp(self, aSelector, anObject);
    }

    return NO;
}

@end
