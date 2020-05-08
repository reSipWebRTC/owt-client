//
//  AppDelegate.h
//  OpenVideoCall
//
//  Created by GongYuhua on 2016/11/17.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OWT/OWT.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) UIInterfaceOrientationMask orientation;

@property (strong, nonatomic) OWTConferenceClient *conferenceClient;
@property (strong, nonatomic) OWTRemoteMixedStream* mixedStream;
@property (strong, nonatomic) OWTRemoteStream* screenStream;
@property (strong, nonatomic) NSString* conferenceId;

@property (strong, nonatomic) NSMutableArray<OWTRemoteStream*>* remoteStreams;
@end

