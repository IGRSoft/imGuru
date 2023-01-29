//
//  IGRUserDefaults.m
//  imGuru
//
//  Created by Vitalii Parovishnyk on 3/6/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

#import "IGRUserDefaults.h"

NSString *kUDCopyLink       = @"CopyLink";
NSString *kUDUseSound       = @"UseSound";
NSString *kHistory          = @"History";
NSString *kUDRefreshToken   = @"refreshToken";

@interface IGRUserDefaults ()

@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong, readwrite) NSArray<NSString *> *history;

@end

@implementation IGRUserDefaults

- (void)initialize {
    // Create a dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    defaultValues[kUDCopyLink] = @YES;
    defaultValues[kUDUseSound] = @YES;
    defaultValues[kHistory] = @[];
    
    // Register the dictionary of defaults
    [self.defaults registerDefaults: defaultValues];
    //DBNSLog(@"registered defaults: %@", defaultValues);
}

- (instancetype)init {
    if (self = [super init]) {
        NSString *bundleIdentifier = @"DMP42GVPJ3.imGuru.shared";
        
        self.defaults = [[NSUserDefaults alloc] initWithSuiteName:bundleIdentifier];
        [self initialize];
        [self loadUserSettings];
    }
    
    return self;
}

- (void)updateHistory:(NSString *)url {
    NSArray *history = [_history arrayByAddingObject:url];
    NSRange endRange = NSMakeRange(history.count >= 10 ? history.count - 10 : 0, MIN(history.count, 10));
    _history = [history subarrayWithRange:endRange];
    
    [self saveUserSettings];
}

- (void)loadUserSettings {
    _sRefreshToken = [self.defaults objectForKey:kUDRefreshToken];
    _bCopyLink     = [self.defaults boolForKey:kUDCopyLink];
    _bUseSound     = [self.defaults boolForKey:kUDUseSound];
    
    NSData *data = [self.defaults objectForKey:kHistory];
    if ([data isKindOfClass:NSData.class]) {
        NSArray *history = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[NSArray.class, NSString.class]] fromData:data error:nil];
        _history       = history ?: @[];
    }
}

- (void)saveUserSettings {
    [self.defaults setBool:_bCopyLink forKey:kUDCopyLink];
    [self.defaults setBool:_bUseSound forKey:kUDUseSound];
    
    NSData *history = [NSKeyedArchiver archivedDataWithRootObject:_history requiringSecureCoding:YES error:nil];
    if (history != nil) {
        [self.defaults setObject:history forKey:kHistory];
    }
    
    if (_sRefreshToken) {
        [self.defaults setObject:_sRefreshToken forKey:kUDRefreshToken];
    }
    else {
        [self.defaults removeObjectForKey:kUDRefreshToken];
    }
    
    [self.defaults synchronize];
}

@end
