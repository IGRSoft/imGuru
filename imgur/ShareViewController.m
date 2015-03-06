//
//  ShareViewController.m
//  imgur
//
//  Created by Vitalii Parovishnyk on 3/5/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

#import "ShareViewController.h"
#import "Constants.h"
#import "ImgurSession.h"
#import "IGRUserDefaults.h"
@import AudioToolbox;

@interface ShareViewController () <IMGSessionDelegate>

@property (strong) IMGSession *imgSession;
@property (copy) NSURL *fileURL;
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
    
    self.warningLabel.stringValue = @"Please login to imgur via imGuru";
    
    // Insert code here to customize the view
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSLog(@"Attachments = %@", item.attachments);
    
    __weak typeof(self) weakSelf = self;
    if ([item.attachments.firstObject hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
        [item.attachments.firstObject loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
            
            NSLog(@"Image path: %@", url.absoluteString);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                weakSelf.fileURL = url;
                weakSelf.imageView.image = [[NSImage alloc] initWithContentsOfURL:weakSelf.fileURL];
                weakSelf.titleField.stringValue = [url lastPathComponent];
            });
        }];
    }
    
    self.userSettings = [[IGRUserDefaults alloc] init];
    if (self.userSettings.sRefreshToken)
    {
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
   
    [IMGImageRequest uploadImageWithFileURL:self.fileURL
                                      title:self.titleField.stringValue
                                description:@""
                          linkToAlbumWithID:nil
                                    success:^(IMGImage *image) {
                                        
                                        NSLog(@"Image Upload file: %@", image.url);
                                        [self playSystemSound:@"Glass"];
                                        
                                        if (self.userSettings.bCopyLink)
                                        {
                                            NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
                                            [pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
                                            [pasteBoard setString:[image.url absoluteString] forType:NSStringPboardType];
                                        }
                                        
                                    } progress:nil
                                    failure:^(NSError *error) {
                                        
                                        NSLog(@"Can't Upload file: %@", error.localizedDescription);
                                        
                                        [self playSystemSound:@"Basso"];
                                    }];
    
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    
    [self.extensionContext cancelRequestWithError:cancelError];
}

- (void)imgurSessionNeedsExternalWebview:(NSURL*)url completion:(void(^)())completion
{
}

- (void)imgurSessionUserRefreshed:(IMGAccount*)user
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        weakSelf.warningLabel.stringValue = [NSString stringWithFormat:@"User Name: %@", user.username];
    });
}

- (void)playSystemSound:(NSString*)name
{
    NSString* soundFile = [[NSString alloc] initWithFormat:@"/System/Library/Sounds/%@.aiff", name];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([ fm fileExistsAtPath:soundFile] == YES)
    {
        NSURL* filePath = [NSURL fileURLWithPath:soundFile isDirectory: NO];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        AudioServicesPlaySystemSound(soundID);
    }
}

@end
