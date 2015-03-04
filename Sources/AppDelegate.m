//
//  AppDelegate.m
//  imGuru
//
//  Created by Vitalii Parovishnyk on 3/4/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

#import "AppDelegate.h"
#import "ImgurSession.h"

#define ClientID @"bc5111e191dfa20"
#define ClientSecret @"a76a2be0cf75660e2dade7a86a6b2371c4cb9e95"


@interface AppDelegate () <IMGSessionDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *authButton;
@property (weak) IBOutlet NSTextField *stateLabel;

@property (strong) IMGSession *imgSession;
@property (copy) void(^continueHandler)();
@property (assign) BOOL waitingAuth;

- (IBAction)authorizeTapped:(id)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.waitingAuth = NO;
    
    [self authorizeTapped:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    static BOOL skipOnStart = YES;
    
    if (skipOnStart)
    {
        skipOnStart = NO;
        return;
    }
    
    if (self.waitingAuth)
    {
        NSString *pin = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
        
        if (pin.length == 10)
        {
            self.waitingAuth = NO;
            
            [self.imgSession authenticateWithCode:pin];
        }
    }
    
    [self.window makeKeyAndOrderFront:self];
    [self.window center];
}

- (IBAction)authorizeTapped:(id)sender {
    
    if (self.imgSession.isAnonymous || self.imgSession == nil) {
        
        [self.window makeKeyAndOrderFront:self];
        [self.window center];
        
        self.waitingAuth = YES;
        
        //set your credentials to reset the session to your app
        self.imgSession = [IMGSession authenticatedSessionWithClientID:ClientID
                                                                secret:ClientSecret
                                                              authType:IMGPinAuth
                                                          withDelegate:self];
        [self.imgSession authenticate];
        
    } else {
        
        self.imgSession = [IMGSession anonymousSessionWithClientID:ClientID
                                                      withDelegate:self];
    }
}

-(void)imgurSessionNeedsExternalWebview:(NSURL*)url completion:(void(^)())completion
{
    NSLog(@"url - %@", url);
    
    self.continueHandler = [completion copy];
    
    //go to safari to login, configure your imgur app to redirect to this app using URL scheme.
    [[NSWorkspace sharedWorkspace] openURL:url];
}

-(void)imgurSessionAuthStateChanged:(IMGAuthState)state;
{
    self.authButton.title = @"Log In";
    
    switch (state)
    {
        case IMGAuthStateAuthenticated:
            self.authButton.title = @"Log Out";
            break;
        case IMGAuthStateAwaitingCodeInput:
            self.stateLabel.stringValue = @"Logging In";
            break;
        case IMGAuthStateBad:
        case IMGAuthStateNone:
        case IMGAuthStateAnon:
        case IMGAuthStateExpired:
        default:
            self.stateLabel.stringValue = @"Not Authorized";
            break;
    }
    
    self.authButton.enabled = (state != IMGAuthStateAwaitingCodeInput && state != IMGAuthStateNone);
}

-(void)imgurSessionUserRefreshed:(IMGAccount*)user
{
    self.stateLabel.stringValue = user.username;
}

@end
