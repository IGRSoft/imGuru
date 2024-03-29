//
//  IGRUserDefaults.h
//  imGuru
//
//  Created by Vitalii Parovishnyk on 3/6/15.
//  Copyright (c) 2015 IGR Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IGRUserDefaults : NSObject

@property (nonatomic, assign) BOOL bCopyLink;
@property (nonatomic, assign) BOOL bUseSound;
@property (nonatomic, strong) NSString *sRefreshToken;
@property (nonatomic, strong, readonly) NSArray<NSString *> *history;

- (void)updateHistory:(NSString *)url;

- (void)loadUserSettings;
- (void)saveUserSettings;

@end
