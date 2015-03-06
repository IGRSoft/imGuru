//
//  IGRUserDefaults.m
//  imGuru
//
//  Created by Vitalii Parovishnyk on 3/6/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

#import "IGRUserDefaults.h"

NSString *kUDCopyLink       = @"CopyLink";
NSString *kUDRefreshToken   = @"refreshToken";

@interface IGRUserDefaults ()

@property (nonatomic, strong) NSUserDefaults *defaults;

@end

@implementation IGRUserDefaults

- (void)initialize
{
    // Create a dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    defaultValues[kUDCopyLink] = @YES;
    
    // Register the dictionary of defaults
    [self.defaults registerDefaults: defaultValues];
    //DBNSLog(@"registered defaults: %@", defaultValues);
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSString *bundleIdentifier = @"com.igrsoft.imGuru.shared";
        
        self.defaults = [[NSUserDefaults alloc] initWithSuiteName:bundleIdentifier];
        [self initialize];
        [self loadUserSettings];
    }
    
    return self;
}

- (void)loadUserSettings
{
    _sRefreshToken = [self.defaults objectForKey:kUDRefreshToken];
    _bCopyLink     = [self.defaults boolForKey:kUDCopyLink];
}

- (void)saveUserSettings
{
    [self.defaults setBool:_bCopyLink forKey:kUDCopyLink];
    
    if (_sRefreshToken)
    {
        [self.defaults setObject:_sRefreshToken forKey:kUDRefreshToken];
    }
    else
    {
        [self.defaults removeObjectForKey:kUDRefreshToken];
    }
    
    [self.defaults synchronize];
}

@end
