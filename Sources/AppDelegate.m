//
//  AppDelegate.m
//  imGuru
//
//  Created by Vitalii Parovishnyk on 3/4/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

BOOL doNothingAtStart = NO;

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    static BOOL skipOnStart = YES;
    
    if (skipOnStart)
    {
        skipOnStart = NO;
        return;
    }
    
    [self.window makeKeyAndOrderFront:self];
    [self.window center];
}

@end
