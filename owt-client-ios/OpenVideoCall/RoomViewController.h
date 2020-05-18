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
<OWTConferencePublicationDelegate, OWTConferenceSubscriptionDelegate>

@property (weak, nonatomic) id<RoomVCDataSource> dataSource;

@property (strong, nonatomic) OWTConferenceClient *conferenceClient;
@property (strong, nonatomic) OWTRemoteMixedStream* mixedStream;
@property (strong, nonatomic) OWTRemoteStream* screenStream;
@property (strong, nonatomic) NSString* conferenceId;
@property (strong, nonatomic) NSMutableArray<OWTRemoteStream*>* remoteStreams;

@property(strong, nonatomic) OWTLocalStream* localStream;
@property(strong, nonatomic) OWTLocalStream* localStream2;

-(void)doPublish;
//-(void)mixToCommonView:(OWTConferencePublication*)publication;
-(void)subscribeForwardStream:(OWTRemoteStream *)remoteStream;

@end
