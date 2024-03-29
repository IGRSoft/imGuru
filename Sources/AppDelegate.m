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
#import "IGRUserDefaults.h"

@interface AppDelegate () <IMGSessionDelegate, NSUserNotificationCenterDelegate>

@property (weak) IBOutlet NSWindow    *window;
@property (weak) IBOutlet NSButton    *authButton;
@property (weak) IBOutlet NSButton    *connectButton;
@property (weak) IBOutlet NSTextField *pinTextField;
@property (weak) IBOutlet NSTextField *stateLabel;
@property (weak) IBOutlet NSStackView *historyStackView;
@property (weak) IBOutlet NSStackView *historyListStackView;

@property (nonatomic) IGRUserDefaults *userSettings;

@property (strong         ) IMGSession      *imgSession;
@property (copy           ) void(^continueHandler)(void);
@property (assign         ) BOOL            waitingAuth;
@property (nonatomic, copy) NSString        *refreshToken;

- (IBAction)authorizeTapped:(id)sender;

@end

@implementation AppDelegate

#pragma mark - application

- (instancetype)init {
    if (self = [super init]) {
        self.userSettings = IGRUserDefaults.new;
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.waitingAuth = NO;
    
    self.imgSession = [IMGSession authenticatedSessionWithClientID:ClientID secret:ClientSecret authType:IMGPinAuth withDelegate:self];
    
    _refreshToken = self.userSettings.sRefreshToken;
    if (_refreshToken.length) {
        [self restoreSession];
    }
    
    NSDistributedNotificationCenter *distCenter = [NSDistributedNotificationCenter defaultCenter];
    [distCenter addObserver:self selector:@selector(imageUrlReceived:) name:IGRNotificationImageUrlKey object:nil];
    
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];
    NSUserNotification *urlNotification = aNotification.userInfo[NSApplicationLaunchUserNotificationKey];
    [self userNotificationCenter:center processNotification:urlNotification];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:nil];
    
    NSDistributedNotificationCenter *distCenter = [NSDistributedNotificationCenter defaultCenter];
    [distCenter removeObserver:self name:IGRNotificationImageUrlKey object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    self.userSettings = IGRUserDefaults.new;
    
    if (self.waitingAuth) {
        NSString *pin = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
        if (pin.length == 10) {
            self.pinTextField.stringValue = pin;
            [self connectTapped:nil];
        }
    }
    
    [self.window makeKeyAndOrderFront:self];
    [self.window center];
    
    [self updateHistory];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
    return NSTerminateNow;
}

// split when window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#pragma mark - Buttons Actions

- (IBAction)authorizeTapped:(id)sender {
    if (self.imgSession.accessToken.length == 0 || self.imgSession == nil) {
        
        [self.window makeKeyAndOrderFront:self];
        [self.window center];
        
        self.waitingAuth = YES;
        
        //set your credentials to reset the session to your app
        self.imgSession = [IMGSession authenticatedSessionWithClientID:ClientID secret:ClientSecret authType:IMGPinAuth withDelegate:self];
        [self.imgSession authenticate];
        
    } else {
        self.imgSession = [IMGSession anonymousSessionWithClientID:ClientID withDelegate:self];
        self.refreshToken = nil;
    }
}

- (IBAction)connectTapped:(id)sender {
    self.waitingAuth = NO;
    
    [self.imgSession setAuthenticationInputCode:self.pinTextField.stringValue];
    
    self.continueHandler();
    self.continueHandler = nil;
}

- (IBAction)siteTapped:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://igrsoft.com"]];
}

- (void)updateHistory {
    NSArray<NSString *> *history = self.userSettings.history;
    BOOL hasHistory = history.count > 0;
    
    self.historyStackView.hidden = !hasHistory;
    
    NSArray *list = self.historyListStackView.arrangedSubviews;
    for (NSView *view in list) {
        [self.historyListStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    for (NSString *url in history) {
        NSButton *button = [NSButton buttonWithTitle:url target:self action:@selector(openImageUrl:)];
        button.bezelStyle = NSBezelStyleInline;
        
        [self.historyListStackView addArrangedSubview:button];
    }
    
    [self.historyStackView needsLayout];
}

- (IBAction)openImageUrl:(NSButton *)sender {
    NSURL *url = [NSURL URLWithString:sender.title];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)saveSettings:(id)sender {
    [self.userSettings saveUserSettings];
}

#pragma mark - imgur Seeesion

- (void)restoreSession {
    [self.imgSession authenticateWithRefreshToken:_refreshToken];
}

- (void)setRefreshToken:(NSString *)refreshToken {
    self.userSettings.sRefreshToken = _refreshToken = refreshToken;
    
    [self saveSettings:self];
}

#pragma mark - IMGSessionDelegate

- (void)imgurSessionNeedsExternalWebview:(NSURL*)url completion:(void(^)(void))completion {
    NSLog(@"url - %@", url);
    
    self.continueHandler = [completion copy];
    
    [[NSWorkspace sharedWorkspace] openURL:url];
    
    self.pinTextField.stringValue = @"";
    [self imgurSessionAuthStateChanged:IMGAuthStateAwaitingCodeInput];
}

- (void)imgurSessionAuthStateChanged:(IMGAuthState)state {
    self.authButton.title = NSLocalizedString(@"LogIn", @"");
    self.authButton.image = nil;
    self.authButton.bordered = YES;
    self.stateLabel.hidden = false;
    self.pinTextField.hidden = true;
    self.connectButton.hidden = true;
    
    switch (state) {
        case IMGAuthStateAuthenticated:
            self.authButton.title = NSLocalizedString(@"LogOut", @"");
            break;
        case IMGAuthStateAwaitingCodeInput:
            self.authButton.title = @"";
            self.authButton.image = [NSImage imageNamed:@"NSRefreshFreestandingTemplate"];
            self.authButton.bordered = NO;
            self.stateLabel.hidden = true;
            self.pinTextField.hidden = false;
            self.connectButton.hidden = false;
            break;
        case IMGAuthStateExpired:
            [self restoreSession];
            break;
        case IMGAuthStateBad:
        case IMGAuthStateNone:
        case IMGAuthStateAnon:
        default:
            self.stateLabel.stringValue = NSLocalizedString(@"NotAuthorized", @"");
            break;
    }
}

- (void)imgurSessionUserRefreshed:(IMGAccount *)user {
    self.stateLabel.stringValue = user.username;
    
    [self imgurSessionAuthStateChanged:IMGAuthStateAuthenticated];
}

- (void)imgurSessionTokenRefreshed {
    self.refreshToken = self.imgSession.refreshToken;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center processNotification:(NSUserNotification *)notification {
    if (notification.informativeText.length) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:notification.informativeText]];
        [center removeDeliveredNotification:notification];
    }
}

#pragma mark - NSDistributedNotificationCenter
- (void)imageUrlReceived:(NSNotification *)aNotification {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedString(@"ImageUrl", @"");
    notification.informativeText = aNotification.object;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

#pragma mark - UserNotificationCenter

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    [self userNotificationCenter:center processNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)userNotification {
    return YES;
}

@end
