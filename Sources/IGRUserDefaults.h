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
@property (nonatomic, strong) NSString *sRefreshToken;

- (void)loadUserSettings;
- (void)saveUserSettings;

@end
