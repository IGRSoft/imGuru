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

@interface ShareViewController () <IMGSessionDelegate>

@property (strong) IMGSession *imgSession;
@property (copy) NSURL *fileURL;
@property (weak) IBOutlet NSImageView *imageView;

@property (weak) IBOutlet NSButton *actionButton;
@property (weak) IBOutlet NSTextField *warningLabel;

@end

@implementation ShareViewController

- (NSString *)nibName {
    return @"ShareViewController";
}

- (void)loadView {
    [super loadView];
    
    // Insert code here to customize the view
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSLog(@"Attachments = %@", item.attachments);
    
    __weak typeof(self) weakSelf = self;
    if ([item.attachments.firstObject hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
        [item.attachments.firstObject loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
            NSLog(@"Image path: %@", url.absoluteString);
            weakSelf.fileURL = url;
            weakSelf.imageView.image = [[NSImage alloc] initWithContentsOfURL:weakSelf.fileURL];
        }];
    }
    
    NSUserDefaults *ud = [[NSUserDefaults alloc] initWithSuiteName:SharedID];
    NSString *refreshToken = [ud objectForKey:@"refreshToken"];
    if (refreshToken)
    {
        self.imgSession = [IMGSession authenticatedSessionWithClientID:ClientID
                                                                secret:ClientSecret
                                                              authType:IMGPinAuth
                                                          withDelegate:self];
        [self.imgSession authenticateWithRefreshToken:refreshToken];
    }
    
    self.actionButton.enabled = (refreshToken != nil);
    self.warningLabel.hidden = (refreshToken != nil);
}

- (IBAction)send:(id)sender {
    NSExtensionItem *outputItem = [[NSExtensionItem alloc] init];
    outputItem.attachments = @[self.imageView.image];
    // Complete implementation by setting the appropriate value on the output item
    
    NSArray *outputItems = @[outputItem];
    
    [self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
}

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}

- (void)imgurSessionNeedsExternalWebview:(NSURL*)url completion:(void(^)())completion
{
}

@end

