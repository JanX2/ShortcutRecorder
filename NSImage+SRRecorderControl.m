//
//  Created by Ilya Kulakov on 13.12.12.
//  Copyright 2012. All rights reserved.
//

#import "NSImage+SRRecorderControl.h"
#import "SRRecorderControl.h"


@implementation NSImage (SRRecorderControl)

+ (NSImage *)SR_imageNamed:(NSString *)anImageName
{
    NSBundle *b = [NSBundle bundleForClass:[SRRecorderControl class]];

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        return [[NSImage alloc] initByReferencingURL:[b URLForImageResource:anImageName]];
    else
        return [b imageForResource:anImageName];
}

@end
