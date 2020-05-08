//
//  RoomViewController.h
//  OpenVideoCall
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import <OWT/OWT.h>
#import "Encryption.h"
#import "Settings.h"

@class RoomViewController;
@protocol RoomVCDataSource <NSObject>
//- (AgoraRtcEngineKit *)roomVCNeedAgoraKit;
- (Settings *)roomVCNeedSettings;
@end

@interface RoomViewController : UIViewController
@property (weak, nonatomic) id<RoomVCDataSource> dataSource;

@property (strong, nonatomic) OWTConferenceClient *conferenceClient;
@property (strong, nonatomic) OWTRemoteMixedStream* mixedStream;
@property (strong, nonatomic) OWTRemoteStream* screenStream;
@property (strong, nonatomic) NSString* conferenceId;

@property (strong, nonatomic) NSMutableArray<OWTRemoteStream*>* remoteStreams;

@end
