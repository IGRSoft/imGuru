//
//  AppDelegate.m
//  imGuru
//
//  Created by Vitalii Parovishnyk on 3/4/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

#import "AppDelegate.h"
#import "ImgurSession.h"
#import "Constants.h"

@interface AppDelegate () <IMGSessionDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *authButton;
@property (weak) IBOutlet NSTextField *stateLabel;

@property (strong) IMGSession *imgSession;
@property (copy) void(^continueHandler)();
@property (assign) BOOL waitingAuth;
@property (nonatomic, copy) NSString *refreshToken;

- (IBAction)authorizeTapped:(id)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.waitingAuth = NO;
    
    self.imgSession = [IMGSession authenticatedSessionWithClientID:ClientID
                                                            secret:ClientSecret
                                                          authType:IMGPinAuth
                                                      withDelegate:self];
    
    NSUserDefaults *ud = [[NSUserDefaults alloc] initWithSuiteName:SharedID];
    _refreshToken = [ud objectForKey:@"refreshToken"];
    if (_refreshToken)
    {
        [self restoreSession];
    }
    else
    {
        [self authorizeTapped:self];
    }
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
            
            [self.imgSession setAuthenticationInputCode:pin];
            
            self.continueHandler();
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

- (void)restoreSession
{
    [self.imgSession authenticateWithRefreshToken:_refreshToken];
}

- (void)setRefreshToken:(NSString *)refreshToken
{
    _refreshToken = refreshToken;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSUserDefaults *ud = [[NSUserDefaults alloc] initWithSuiteName:SharedID];
        [ud setObject:refreshToken forKey:@"refreshToken"];
        [ud synchronize];
    });
}

- (void)imgurSessionNeedsExternalWebview:(NSURL*)url completion:(void(^)())completion
{
    NSLog(@"url - %@", url);
    
    self.continueHandler = [completion copy];
    
    //go to safari to login, configure your imgur app to redirect to this app using URL scheme.
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)imgurSessionAuthStateChanged:(IMGAuthState)state;
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
        case IMGAuthStateExpired:
            [self restoreSession];
            break;
        case IMGAuthStateBad:
        case IMGAuthStateNone:
        case IMGAuthStateAnon:
        default:
            self.stateLabel.stringValue = @"Not Authorized";
            break;
    }
    
    self.authButton.enabled = (state == IMGAuthStateAuthenticated || state == IMGAuthStateAnon);
}

- (void)imgurSessionUserRefreshed:(IMGAccount*)user
{
    self.stateLabel.stringValue = user.username;
    
    [self imgurSessionAuthStateChanged:IMGAuthStateAuthenticated];
}

- (void)imgurSessionTokenRefreshed
{
    self.refreshToken = self.imgSession.refreshToken;
}

- (void)completeRequestReturningItems:(NSArray *)items completionHandler:(void(^)(BOOL expired))completionHandler
{
    NSLog(@"");
}

@end
