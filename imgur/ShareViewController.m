//
//  ShareViewController.m
//  imgur
//
//  Created by Vitalii Parovishnyk on 3/5/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

@import AudioToolbox;

#import "ShareViewController.h"
#import "Constants.h"
#import "ImgurSession.h"
#import "IGRUserDefaults.h"

@interface ShareViewController () <IMGSessionDelegate>

@property (strong) IMGSession *imgSession;
@property (weak) IBOutlet NSImageView *imageView;

@property (weak) IBOutlet NSButton *actionButton;
@property (weak) IBOutlet NSTextField *warningLabel;
@property (weak) IBOutlet NSTextField *titleField;

@property (nonatomic) IGRUserDefaults *userSettings;

@end

@implementation ShareViewController

- (NSString *)nibName {
    return @"ShareViewController";
}

- (void)loadView {
    [super loadView];
    
    self.warningLabel.stringValue = @"Anonymous upload doesn't support";
    
    // Insert code here to customize the view
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSLog(@"Attachments = %@", item.attachments);
    
    NSString * const kPublicImageKey = @"public.image";
    __weak typeof(self) weak = self;
    NSItemProvider *itemProvider = item.attachments.firstObject;
    if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
            
            NSLog(@"Image path: %@", url.absoluteString);
            dispatch_async(dispatch_get_main_queue(), ^{
                weak.imageView.image = [[NSImage alloc] initWithContentsOfURL:url];
                weak.titleField.stringValue = [url lastPathComponent];
            });
        }];
    }
    else if ([itemProvider hasItemConformingToTypeIdentifier:kPublicImageKey]) {
        [itemProvider loadItemForTypeIdentifier:kPublicImageKey options:nil completionHandler:^(NSImage *img, NSError *error) {
            
            NSLog(@"Image path: %@", img);
            dispatch_async(dispatch_get_main_queue(), ^{
                weak.imageView.image = img;
                weak.titleField.stringValue = kPublicImageKey;
            });
        }];
    }
    
    self.userSettings = [[IGRUserDefaults alloc] init];
    if (self.userSettings.sRefreshToken.length) {
        self.imgSession = [IMGSession authenticatedSessionWithClientID:ClientID
                                                                secret:ClientSecret
                                                              authType:IMGPinAuth
                                                          withDelegate:self];
        [self.imgSession authenticateWithRefreshToken:self.userSettings.sRefreshToken];
    }
    
    self.actionButton.enabled = (self.userSettings.sRefreshToken != nil);
    self.titleField.hidden = (self.userSettings.sRefreshToken == nil);
}

- (IBAction)send:(id)sender {
    [IMGImageRequest uploadImageWithData:[self.imageView.image TIFFRepresentation]
                                   title:self.titleField.stringValue
                                progress:nil
                                 success:^(IMGImage *image) {
        NSLog(@"Image Upload file: %@", image.url);
        [self playSystemSound:@"Glass"];
        
        if (self.userSettings.bCopyLink)
        {
            NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
            [pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [pasteBoard setString:[image.url absoluteString] forType:NSStringPboardType];
        }
        
        NSUInteger options = NSNotificationDeliverImmediately | NSNotificationPostToAllSessions;
        NSDistributedNotificationCenter *distCenter = [NSDistributedNotificationCenter defaultCenter];
        
        [distCenter postNotificationName:IGRNotificationImageUrlKey
                                  object:[image.url absoluteString]
                                userInfo:nil
                                 options:options];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Can't Upload file: %@", error.localizedDescription);
        
        [self playSystemSound:@"Basso"];
    }];
    
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    
    [self.extensionContext cancelRequestWithError:cancelError];
}

- (void)imgurSessionNeedsExternalWebview:(NSURL*)url completion:(void(^)(void))completion
{
}

- (void)imgurSessionUserRefreshed:(IMGAccount *)user {
    __weak typeof(self) weak = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        weak.warningLabel.stringValue = [NSString stringWithFormat:@"User Name: %@", user.username];
    });
}

- (void)playSystemSound:(NSString *)name {
    if (!self.userSettings.bUseSound) {
        return;
    }
    
    NSString *soundFile = [[NSString alloc] initWithFormat:@"/System/Library/Sounds/%@.aiff", name];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:soundFile] == YES) {
        NSURL *filePath = [NSURL fileURLWithPath:soundFile isDirectory: NO];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        AudioServicesPlaySystemSound(soundID);
    }
}

@end
