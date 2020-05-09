//
//  RoomViewController.m
//  OpenVideoCall
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <WebRTC/WebRTC.h>
//#import <AgoraRtcCryptoLoader/AgoraRtcCryptoLoader.h>
#import "RoomOptionsViewController.h"
#import "MessageViewController.h"
#import "RoomViewController.h"
#import "VideoViewLayouter.h"
#import "VideoSession.h"
#import "AppDelegate.h"
#import "FileCenter.h"
#import "KeyCenter.h"

@interface RoomViewController () <RoomOptionsVCDelegate, RoomOptionsVCDataSource, OWTConferenceClientDelegate, OWTRemoteMixedStreamDelegate, OWTRemoteStreamDelegate, OWTConferenceParticipantDelegate>
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *messageTableContainerView;

@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *audioMixingButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerPhoneButton;
@property (weak, nonatomic) IBOutlet UIButton *beautyButton;
@property (weak, nonatomic) IBOutlet UIButton *muteVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteAudioButton;

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *backgroundDoubleTap;

@property(strong, nonatomic) OWTRemoteStream* remoteStream;
@property(strong, nonatomic) OWTConferencePublication* publication;
@property(strong, nonatomic) OWTConferenceSubscription* subscription;

//@property (weak, nonatomic) AgoraRtcEngineKit *agoraKit;
//@property (strong, nonatomic) AgoraRtcCryptoLoader *agoraLoader;
//-(void)getTokenFromBasicSample:(NSString *)basicServer onSuccess:(void (^)(NSString *))onSuccess onFailure:(void (^)())onFailure;

@property (assign, nonatomic) BOOL isSwitchCamera;
@property (assign, nonatomic) BOOL isAudioMixing;
@property (assign, nonatomic) BOOL isBeauty;
@property (assign, nonatomic) BOOL isEarPhone;
@property (assign, nonatomic) BOOL isVideoMuted;
@property (assign, nonatomic) BOOL isAudioMuted;
@property (assign, nonatomic) BOOL isDebugMode;

@property (strong, nonatomic) NSMutableArray<VideoSession *> *videoSessions;
@property (strong, nonatomic) VideoSession *doubleClickFullSession;
@property (strong, nonatomic) VideoViewLayouter *videoViewLayouter;

@property (strong, nonatomic) RoomOptions *options;

@property (weak, nonatomic) MessageViewController *messageVC;
@property (weak, nonatomic) RoomOptionsViewController *optionsVC;
@property (weak, nonatomic) Settings *settings;
@end

@implementation RoomViewController {
    RTCVideoSource* _source;
    RTCCameraVideoCapturer* _capturer;
}

#pragma mark - Setter, Getter
- (void)setIsSwitchCamera:(BOOL)isSwitchCamera {
    //[self.agoraKit switchCamera];
}

- (void)setIsAudioMixing:(BOOL)isAudioMixing {
    if (_isAudioMixing == isAudioMixing) {
        return;
    }
    
    _isAudioMixing = isAudioMixing;
    self.audioMixingButton.selected = _isAudioMixing;
    if (_isAudioMixing) {
        // play music file
        /*[self.agoraKit startAudioMixing:[FileCenter audioFilePath]
                               loopback:false
                                replace:false
                                  cycle:1];*/
    } else {
        // stop play
        //[self.agoraKit stopAudioMixing];
    }
}

- (void)setIsBeauty:(BOOL)isBeauty {
    if (_isBeauty == isBeauty) {
        return;
    }
    
    _isBeauty = isBeauty;
    self.beautyButton.selected = _isBeauty;
    /*AgoraBeautyOptions *options = nil;
    if (_isBeauty) {
        options = [[AgoraBeautyOptions alloc] init];
        options.lighteningContrastLevel = AgoraLighteningContrastNormal;
        options.lighteningLevel = 0.7;
        options.smoothnessLevel = 0.5;
        options.rednessLevel = 0.1;
    }
    // improve local render view
    [self.agoraKit setBeautyEffectOptions:_isBeauty options:options];*/
}

- (void)setIsEarPhone:(BOOL)isEarPhone {
    if (_isEarPhone == isEarPhone) {
        return;
    }
    
    _isEarPhone = isEarPhone;
    self.speakerPhoneButton.selected = _isEarPhone;
    // switch playout audio route
    //[self.agoraKit setEnableSpeakerphone:!_isEarPhone];
}

- (void)setIsVideoMuted:(BOOL)isVideoMuted {
    if (_isVideoMuted == isVideoMuted) {
        return;
    }
    
    _isVideoMuted = isVideoMuted;
    self.muteVideoButton.selected = _isVideoMuted;
    [self setVideoMuted:_isVideoMuted forUid:0];
    [self updateSelfViewVisiable];
    // mute local video
    //[self.agoraKit muteLocalVideoStream:_isVideoMuted];
}

- (void)setIsAudioMuted:(BOOL)isAudioMuted {
    if (_isAudioMuted == isAudioMuted) {
        return;
    }
    
    _isAudioMuted = isAudioMuted;
    self.muteAudioButton.selected = _isAudioMuted;
    // mute local audio
    //[self.agoraKit muteLocalAudioStream:_isAudioMuted];
}

- (void)setIsDebugMode:(BOOL)isDebugMode {
    if (_isDebugMode == isDebugMode) {
        return;
    }
    
    _isDebugMode = isDebugMode;
    _options.isDebugMode = _isDebugMode;
    self.messageTableContainerView.hidden = !_isDebugMode;
}

- (void)setDoubleClickFullSession:(VideoSession *)doubleClickFullSession {
    _doubleClickFullSession = doubleClickFullSession;
    if (self.videoSessions.count >= 3) {
        [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:YES];
    }
}

/*- (AgoraRtcEngineKit *)agoraKit {
    return [self.dataSource roomVCNeedAgoraKit];
}

- (AgoraRtcCryptoLoader *)agoraLoader {
    if (!_agoraLoader) {
        _agoraLoader = [[AgoraRtcCryptoLoader alloc] init];
    }
    return _agoraLoader;
}*/

// videoViewLayouter and videoSessions manage all render views
- (VideoViewLayouter *)videoViewLayouter {
    if (!_videoViewLayouter) {
        _videoViewLayouter = [[VideoViewLayouter alloc] init];
    }
    return _videoViewLayouter;
}

- (NSMutableArray<VideoSession *> *)videoSessions {
    if (!_videoSessions) {
        _videoSessions = [[NSMutableArray alloc] init];
    }
    return _videoSessions;
}

- (Settings *)settings {
    return [self.dataSource roomVCNeedSettings];
}

- (RoomOptions *)options {
    if (!_options) {
        _options = [[RoomOptions alloc] init];
        _options.isDebugMode = false;
    }
    return _options;
}

#pragma mark - VC Life
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.settings.roomName;
    [self loadAgoraKit];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueId = segue.identifier;
    if (!segueId.length) {
        return;
    }
    
    if ([segueId isEqualToString:@"roomEmbedMessage"]) {
        self.messageVC = segue.destinationViewController;
    } else if ([segueId isEqualToString:@"roomToOptions"]) {
        RoomOptionsViewController *optionsVC = segue.destinationViewController;
        optionsVC.delegate = self;
        optionsVC.dataSource = self;
        self.optionsVC = optionsVC;
    }
}

- (void)dealloc {
    [self leaveChannel];
}

#pragma mark - UI Actions
- (IBAction)doCameraPressed:(UIButton *)sender {
    self.isSwitchCamera = !self.isSwitchCamera;
}

- (IBAction)doBeautyPressed:(UIButton *)sender {
    self.isBeauty = !self.isBeauty;
}

- (IBAction)doAudioMixingPressed:(UIButton *)sender {
    self.isAudioMixing = !self.isAudioMixing;
}

- (IBAction)doSpeakerPhonePressed:(UIButton *)sender {
    self.isEarPhone = !self.isEarPhone;
}

- (IBAction)doMuteVideoPressed:(UIButton *)sender {
    self.isVideoMuted = !self.isVideoMuted;
}

- (IBAction)doMuteAudioPressed:(UIButton *)sender {
    self.isAudioMuted = !self.isAudioMuted;
}

- (IBAction)doBackDoubleTapped:(UITapGestureRecognizer *)sender {
    if (!self.doubleClickFullSession) {
        // full screen display after be double clicked
        NSInteger tappedIndex = [self.videoViewLayouter responseIndexOfLocation:[sender locationInView:self.containerView]];
        if (tappedIndex >= 0 && tappedIndex < self.videoSessions.count) {
            self.doubleClickFullSession = self.videoSessions[tappedIndex];
        }
    } else {
        self.doubleClickFullSession = nil;
    }
}

#pragma mark - OWT
- (void)loadAgoraKit {
    // Step 1, set delegate
    /*self.agoraKit.delegate = self;
    // Step 2, set communication mode
    [self.agoraKit setChannelProfile:AgoraChannelProfileCommunication];
    
    // Step 3, enable the video module
    [self.agoraKit enableVideo];
    // set video configuration
    AgoraVideoEncoderConfiguration *configuration = [[AgoraVideoEncoderConfiguration alloc] initWithSize:self.settings.dimension
                                                                                               frameRate:self.settings.frameRate
                                                                                                 bitrate:AgoraVideoBitrateStandard
                                                                                         orientationMode:AgoraVideoOutputOrientationModeAdaptative];
    [self.agoraKit setVideoEncoderConfiguration:configuration];
    // add local render view and start preview
    [self addLocalSession];
    [self.agoraKit startPreview];
    
    // Step 4, enable encryption mode
    if (self.settings.encryption.type != EncryptionTypeNone && self.settings.encryption.secret.length) {
        [self.agoraKit setEncryptionMode:self.settings.encryption.modeString];
        [self.agoraKit setEncryptionSecret:self.settings.encryption.secret];
    }
    
    // Step 5, join channel and start group chat
    // If join  channel success, agoraKit triggers it's delegate function
    // 'rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed'
    [self.agoraKit joinChannelByToken:nil channelId:self.settings.roomName info:nil uid:0 joinSuccess:nil];*/
     if (_conferenceClient == nil){
        OWTConferenceClientConfiguration* config=[[OWTConferenceClientConfiguration alloc]init];
        //NSArray *ice=[[NSArray alloc]initWithObjects:[[RTCIceServer alloc]initWithURLStrings:[[NSArray alloc]initWithObjects:@"stun:61.152.239.47:3478", nil]], nil];
        config.rtcConfiguration=[[RTCConfiguration alloc] init];
    //    config.rtcConfiguration.iceServers=ice;
        _conferenceClient=[[OWTConferenceClient alloc]initWithConfiguration:config];
        _conferenceClient.delegate = self;
      }
    
    if (self.settings.roomName == nil) {
        NSLog(@"[ZSPDEBUG Function:%s Line:%d] can not read rooms info",__FUNCTION__,__LINE__);
        return;
      }
      NSString * room_id = self.settings.roomName;
      [self getTokenFromBasicSample:@"https://47.113.89.17:3004/" roomId:room_id onSuccess:^(NSString *token) {
        NSData *base64_date = [[NSData alloc] initWithBase64EncodedString:token options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSString *raw_string =[[NSString alloc] initWithData:base64_date encoding:NSUTF8StringEncoding];
        NSLog(@"[ZSPDEBUG Function:%s Line:%d] token:%@", __FUNCTION__,__LINE__,raw_string);
          [self->_conferenceClient joinWithToken:token onSuccess:^(OWTConferenceInfo* info) {
          dispatch_async(dispatch_get_main_queue(), ^{
          //NSLog(@"[ZSPDEBUG Function:%s Line:%d] RemoteStream Count:%lu", __FUNCTION__,__LINE__, (unsigned long)[info.remoteStreams count]);
            if([info.remoteStreams count] > 0){
                self->_conferenceId = info.conferenceId;
                NSLog(@"=======self->_conferenceId=====:%@", self->_conferenceId);
                self->_remoteStreams = [[NSMutableArray alloc] init];
                for(OWTRemoteStream* s in info.remoteStreams) {
                  [self->_remoteStreams addObject:s];
                  s.delegate = self;
                  //s.delegate=appDelegate;
                //if([s isKindOfClass:[OWTRemoteMixedStream class]]){
                  //appDelegate.mixedStream=(OWTRemoteMixedStream*)s;
                //}
              }
            }
            //[self doPublish];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self doPublish];
              });
          });
        } onFailure:^(NSError* err) {
          NSLog(@"Join failed. %@", err);
        }];
      } onFailure:^{
        NSLog(@"Failed to get token from basic server.");
      }];
    [self setIdleTimerActive:NO];
}

-(void)getTokenFromBasicSample:(NSString *)basicServer roomId:(NSString *)roomId onSuccess:(void (^)(NSString *))onSuccess onFailure:(void (^)(void))onFailure{
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  manager.requestSerializer = [AFJSONRequestSerializer serializer];
  [manager.requestSerializer setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  manager.responseSerializer = [AFHTTPResponseSerializer serializer];
  manager.securityPolicy.allowInvalidCertificates=YES;
  manager.securityPolicy.validatesDomainName=NO;
  NSDictionary *params = [[NSDictionary alloc]initWithObjectsAndKeys:roomId, @"room", @"user", @"username", @"presenter", @"role", nil];
  [manager POST:[basicServer stringByAppendingString:@"createToken/"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSData* data=[[NSData alloc]initWithData:responseObject];
    onSuccess([[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
  }];
}

-(void)doPublish{
  if (_localStream == nil) {
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Camera is not supported on simulator");
    OWTStreamConstraints* constraints=[[OWTStreamConstraints alloc]init];
    constraints.audio=YES;
    constraints.video=nil;
#else
    /* Create LocalStream with constraints */
    OWTStreamConstraints* constraints=[[OWTStreamConstraints alloc] init];
    constraints.audio=YES;
    constraints.video=[[OWTVideoTrackConstraints alloc] init];
    constraints.video.frameRate=24;
    constraints.video.resolution=CGSizeMake(640,480);
    constraints.video.devicePosition=AVCaptureDevicePositionFront;
#endif
    RTCMediaStream *localRTCStream = [self createLocalSenderStream:constraints];
    OWTStreamSourceInfo *sourceinfo = [[OWTStreamSourceInfo alloc] init];
    sourceinfo.audio = OWTAudioSourceInfoMic;
    sourceinfo.video = OWTVideoSourceInfoCamera;
    _localStream=[[OWTLocalStream alloc] initWithMediaStream:localRTCStream source:sourceinfo];

#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Stream does not have video track.");
#else
    dispatch_async(dispatch_get_main_queue(), ^{
     // [((SFUStreamView *)self.view).localVideoView setCaptureSession:[self->_capturer captureSession] ];
        [self addLocalSession];
    });
#endif
    OWTPublishOptions* options=[[OWTPublishOptions alloc] init];
    OWTAudioCodecParameters* opusParameters = [[OWTAudioCodecParameters alloc] init];
    opusParameters.name=OWTAudioCodecOpus;
    OWTAudioEncodingParameters *audioParameters = [[OWTAudioEncodingParameters alloc] init];
    audioParameters.codec = opusParameters;
    options.audio=[NSArray arrayWithObjects:audioParameters, nil];
    OWTVideoCodecParameters *h264Parameters = [[OWTVideoCodecParameters alloc] init];
    h264Parameters.name = OWTVideoCodecH264;
    OWTVideoEncodingParameters *videoParameters = [[OWTVideoEncodingParameters alloc]init];
    videoParameters.codec = h264Parameters;
    options.video = [NSArray arrayWithObjects:videoParameters, nil];
    [_conferenceClient publish:_localStream withOptions:options onSuccess:^(OWTConferencePublication* p) {
      NSLog(@"[ZSPDEBUG Function:%s Line:%d] publish success! OWTConferencePublication:%@ id:%@", __FUNCTION__,__LINE__,p,p.publicationId);
      self->_publication = p;
      self->_publication.delegate = self;
      //[self mixToCommonView:p];

    } onFailure:^(NSError* err) {
      NSLog(@"publish failure!");
      //[self showMsg:[err localizedFailureReason]];
    }];
    //_screenStream = appDelegate.screenStream;
    //_remoteStream = appDelegate.mixedStream;
    [self subscribe];
  }
}

- (void)subscribe {
    for (id s in _remoteStreams) {
     if(![s isKindOfClass:[OWTRemoteMixedStream class]])
     {
        [self subscribeForwardStream:s];
     }
   }
}

-(void)subscribeForwardStream:(OWTRemoteStream *)remoteStream{
  OWTConferenceSubscribeOptions* subOption =
      [[OWTConferenceSubscribeOptions alloc] init];
  subOption.video = [[OWTConferenceVideoSubscriptionConstraints alloc]init];
  OWTVideoCodecParameters* h264Codec = [[OWTVideoCodecParameters alloc] init];
  h264Codec.name = OWTVideoCodecH264;
  h264Codec.profile = @"M";
  subOption.video.codecs = [NSArray arrayWithObjects:h264Codec, nil];
  subOption.audio = [[OWTConferenceAudioSubscriptionConstraints alloc]init];

  [[AVAudioSession sharedInstance]
      overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                        error:nil];
  
  //show loading icon
  dispatch_async(dispatch_get_main_queue(), ^(){
    //[self->_streamView.act startAnimating];
  });
  
  [_conferenceClient subscribe:remoteStream
  withOptions:subOption
  onSuccess:^(OWTConferenceSubscription* subscription) {
    self->_subscription=subscription;
    self->_subscription.delegate=self;
    /*self->_getStatsTimer = [NSTimer timerWithTimeInterval:1.0
                                            target:self
                                          selector:@selector(printStats)
                                          userInfo:nil
                                           repeats:YES];*/
//    [[NSRunLoop mainRunLoop] addTimer:_getStatsTimer
//                              forMode:NSDefaultRunLoopMode];
    dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"Subscribe stream success.");
       //UIView<RTCVideoRenderer> *videoView = [[RTCEAGLVideoView alloc]init];
       //[self->_streamView addRemoteRenderer:remoteStream];
       VideoSession *userSession = [self videoSessionOfUid:1];
       [remoteStream attach:((VideoView *)userSession.hostingView).videoView];
       //userSession.size = size;
       //[self.agoraKit setupRemoteVideo:userSession.canvas];
        
      //hide loading icon
      //[self->_streamView.act stopAnimating];
    });
  }
  onFailure:^(NSError* err) {
    NSLog(@"Subscribe stream failed. %@", [err localizedDescription]);
  }];
}

static NSString * const kARDAudioTrackId = @"ARDAMSa0";
static NSString * const kARDVideoTrackId = @"ARDAMSv0";

- (NSString *)createRandomUuid
{
  // Create universally unique identifier (object)
  CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
  // Get the string representation of CFUUID object.
  NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
  CFRelease(uuidObject);
  return uuidStr;
}

- (RTCMediaStream*)createLocalSenderStream:(OWTStreamConstraints*)constraints{
  //init media senders
  RTCPeerConnectionFactory* factory = [RTCPeerConnectionFactory sharedInstance];
  RTCMediaStream* stream = [factory mediaStreamWithStreamId:[self createRandomUuid]];
  
  //add audio track
  RTCAudioSource* audio_source = [factory audioSourceWithConstraints:nil];
  RTCAudioTrack* audio_track =
      [factory audioTrackWithSource:audio_source trackId:[self createRandomUuid]];
  [stream addAudioTrack:audio_track];
  
  //add video track
  // Reference: ARDCaptureController.m.
  RTCVideoSource* video_source = [factory videoSource];
  RTCCameraVideoCapturer* capturer =
      [[RTCCameraVideoCapturer alloc] initWithDelegate:video_source];
  // Configure capturer position.
  NSArray<AVCaptureDevice*>* captureDevices =
      [RTCCameraVideoCapturer captureDevices];
  if (captureDevices == 0) {
    return nil;
  }
  AVCaptureDevice* device = captureDevices[0];
  if (constraints.video.devicePosition) {
    for (AVCaptureDevice* d in captureDevices) {
      if (d.position == constraints.video.devicePosition) {
        device = d;
        break;
      }
    }
  }
  // Configure FPS.
  NSUInteger fps =
      constraints.video.frameRate ? constraints.video.frameRate : 24;
  // Configure resolution.
  NSArray<AVCaptureDeviceFormat*>* formats =
      [RTCCameraVideoCapturer supportedFormatsForDevice:device];
  AVCaptureDeviceFormat* selectedFormat = nil;
  if (constraints.video.resolution.width == 0 &&
      constraints.video.resolution.height == 0) {
    selectedFormat = formats[0];
  } else {
    for (AVCaptureDeviceFormat* format in formats) {
      CMVideoDimensions dimension =
          CMVideoFormatDescriptionGetDimensions(format.formatDescription);
      if (dimension.width == constraints.video.resolution.width &&
          dimension.height == constraints.video.resolution.height) {
        for (AVFrameRateRange* frameRateRange in
             [format videoSupportedFrameRateRanges]) {
          if (frameRateRange.minFrameRate <= fps &&
              fps <= frameRateRange.maxFrameRate) {
            selectedFormat = format;
            break;
          }
        }
      }
      if(selectedFormat){
        break;
      }
    }
  }
  if (selectedFormat == nil) {
    return nil;
  }
  [capturer startCaptureWithDevice:device format:selectedFormat fps:fps];
  RTCVideoTrack* video_track =
      [factory videoTrackWithSource:video_source trackId:[self createRandomUuid]];
  [stream addVideoTrack:video_track];
  _capturer = capturer;
  
  return stream;
}

- (void)addLocalSession {
    VideoSession *localSession = [VideoSession localSession];
    //[localSession updateMediaInfo:self.settings.dimension fps:self.settings.frameRate];
    [self.videoSessions addObject:localSession];
    [((VideoView *)localSession.hostingView).localVideoView setCaptureSession:[self->_capturer captureSession]];
    //[self.agoraKit setupLocalVideo:localSession.canvas];
    [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:YES];
    //[self.agoraKit startPreview];
}

- (void)leaveChannel {
    // Step 1, release local AgoraRtcVideoCanvas instance
    /*[self.agoraKit setupLocalVideo:nil];
    // Step 2, leave channel and end group chat
    [self.agoraKit leaveChannel:nil];
    // Step 3, please attention, stop preview after leave channel
    [self.agoraKit stopPreview];*/
    
    // Step 4, remove all render views
    for (VideoSession *session in self.videoSessions) {
        [session.hostingView removeFromSuperview];
    }
    [self.videoSessions removeAllObjects];
    
    [self setIdleTimerActive:YES];
}

#pragma mark - <AgoraRtcEngineDelegate>

/*///  Occurs when the local user joins a specified channel.
/// @param engine - RTC engine instance
/// @param channel  - Channel name
/// @param uid - User ID of the remote user sending the video stream.
/// @param elapsed - Time elapsed (ms) from the local user calling the joinChannelByToken method until the SDK triggers this callback.
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    [self info:[NSString stringWithFormat:@"Join channel: %@", channel]];
}


/// Occurs when the connection between the SDK and the server is interrupted.
/// The SDK triggers this callback when it loses connection with the server for more than four seconds after a connection is established.
/// After triggering this callback, the SDK tries reconnecting to the server. You can use this callback to implement pop-up reminders.
/// @param engine - RTC engine instance
- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
    [self alert:@"Connection Interrupted"];
}

/// Occurs when the SDK cannot reconnect to Agora’s edge server 10 seconds after its connection to the server is interrupted.
/// @param engine - RTC engine instance
- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
    [self alert:@"Connection Lost"];
}


/// Reports an error during SDK runtime.
/// @param engine - RTC engine instance
/// @param errorCode - see complete list on this page
///         https://docs.agora.io/en/Video/API%20Reference/oc/Constants/AgoraErrorCode.html
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    [self alert:[NSString stringWithFormat:@"Occur error: %ld", errorCode]];
}

/// First remote video frame,Occurs when the first remote video frame is received and decoded.
/// This callback is triggered in either of the following scenarios:
///   * The remote user joins the channel and sends the video stream.
///   * The remote user stops sending the video stream and re-sends it after 15 seconds. Possible reasons include:
///   * The remote user leaves channel.
///   * The remote user drops offline.
///   * The remote user calls muteLocalVideoStream.
///   * The remote user calls disableVideo.
///
/// @param engine - RTC engine instance
/// @param uid - User ID of the remote user sending the video stream.
/// @param size - Size of the first local video frame (width and height).
/// @param elapsed - Time elapsed (ms) from the local user calling the joinChannelByToken method until the SDK triggers this callback.
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size:(CGSize)size elapsed:(NSInteger)elapsed {
    VideoSession *userSession = [self videoSessionOfUid:uid];
    userSession.size = size;
    [self.agoraKit setupRemoteVideo:userSession.canvas];
}

/// First local video frame - occurs when the first local video frame is displayed/rendered on the local video view.
/// @param engine - RTC engine instance
/// @param size - Size of the first local video frame (width and height).
/// @param elapsed - Time elapsed (ms) from the local user calling the joinChannelByToken method until the SDK calls this callback.
///             If the startPreview method is called before the joinChannelByToken method, then elapsed is the time elapsed from
///             calling the startPreview method until the SDK triggers this callback.
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
    if (self.videoSessions.count) {
        VideoSession *selfSession = self.videoSessions.firstObject;
        selfSession.size = size;
        [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:NO];
        [self info:[NSString stringWithFormat:@"local video dimension: %f x %f", size.width, size.height]];
    }
}

/// Occurs when a remote user (Communication)/host (Live Broadcast) leaves a channel.
/// @param engine - RTC engine instance
/// @param uid - User ID of the remote user sending the video stream.
/// @param reason - reason why user went offline, see complete list of the reasons:
///         https://docs.agora.io/en/Video/API%20Reference/oc/Constants/AgoraUserOfflineReason.html
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    VideoSession *deleteSession;
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            deleteSession = session;
            break;
        }
    }
    
    if (deleteSession) {
        [self.videoSessions removeObject:deleteSession];
        [deleteSession.hostingView removeFromSuperview];
        [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:YES];
        
        if (deleteSession == self.doubleClickFullSession) {
            self.doubleClickFullSession = nil;
        }
        
        // release canvas's view
        deleteSession.canvas.view = nil;
    }
}

/// Occurs when a remote user’s video stream playback pauses/resumes.
/// @param engine - RTC engine instance
/// @param muted - true if muted; false otherwise
/// @param uid - User ID of the remote user sending the video stream.
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid {
    [self setVideoMuted:muted forUid:uid];
}

/// Reports the statistics of the video stream from each remote user/host.
/// @param engine - RTC engine instance
/// @param stats - Statistics of the received remote video streams. See complete listing at
///         https://docs.agora.io/en/Video/API%20Reference/oc/Classes/AgoraRtcRemoteVideoStats.html
- (void)rtcEngine:(AgoraRtcEngineKit *)engine remoteVideoStats:(AgoraRtcRemoteVideoStats *)stats {
    VideoSession *session = [self fetchSessionOfUid:stats.uid];
    [session updateMediaInfo:CGSizeMake(stats.width, stats.height) fps:stats.rendererOutputFrameRate];
}

/// Occurs when the audio mixing file playback finishes.
/// @param engine - RTC engine instance
- (void)rtcEngineLocalAudioMixingDidFinish:(AgoraRtcEngineKit *)engine {
    self.isAudioMixing = NO;
}*/

#pragma mark - RoomOptionsVCDelegate, RoomOptionsVCDataSource
- (void)roomOptions:(RoomOptionsViewController *)vc debugModeDidEnable:(BOOL)enable {
    self.isDebugMode = enable;
}

- (RoomOptions *)roomOptionsVCNeedOptions {
    return self.options;
}

#pragma mark - Private
- (void)updateInterfaceWithSessions:(NSArray *)sessions targetSize:(CGSize)targetSize animation:(BOOL)animation {
    if (animation) {
        [UIView animateWithDuration:0.3 animations:^{
            [self updateInterfaceWithSessions:sessions targetSize:targetSize];
            [self.view layoutIfNeeded];
        }];
    } else {
        [self updateInterfaceWithSessions:sessions targetSize:targetSize];
    }
}

- (void)updateInterfaceWithSessions:(NSArray *)sessions targetSize:(CGSize)targetSize {
    if (!sessions.count) {
        return;
    }
    
    VideoSession *selfSession = sessions.firstObject;
    self.videoViewLayouter.selfView = selfSession.hostingView;
    self.videoViewLayouter.selfSize = selfSession.size;
    self.videoViewLayouter.targetSize = targetSize;
    
    NSMutableArray *peerVideoViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 1; i < sessions.count; ++i) {
        VideoSession *session = sessions[i];
        [peerVideoViews addObject:session.hostingView];
    }
    self.videoViewLayouter.videoViews = peerVideoViews;
    self.videoViewLayouter.fullView = self.doubleClickFullSession.hostingView;
    self.videoViewLayouter.containerView = self.containerView;
    
    [self.videoViewLayouter layoutVideoViews];
    [self updateSelfViewVisiable];
    
    // Only three people or more can switch the layout
    if (sessions.count >= 3) {
        self.backgroundDoubleTap.enabled = YES;
    } else {
        self.backgroundDoubleTap.enabled = NO;
        self.doubleClickFullSession = nil;
    }
}

- (void)setIdleTimerActive:(BOOL)active {
    [UIApplication sharedApplication].idleTimerDisabled = !active;
}

- (VideoSession *)fetchSessionOfUid:(NSUInteger)uid {
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            return session;
        }
    }
    return nil;
}

- (VideoSession *)videoSessionOfUid:(NSUInteger)uid {
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    if (fetchedSession) {
        return fetchedSession;
    } else {
        VideoSession *newSession = [[VideoSession alloc] initWithUid:uid];
        [self.videoSessions addObject:newSession];
        [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:YES];
        return newSession;
    }
}

- (void)setVideoMuted:(BOOL)muted forUid:(NSUInteger)uid {
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    fetchedSession.isVideoMuted = muted;
}

- (void)updateSelfViewVisiable {
    UIView *selfView = self.videoSessions.firstObject.hostingView;
    if (self.videoSessions.count == 2) {
        selfView.hidden = self.isVideoMuted;
    } else {
        selfView.hidden = false;
    }
}

// Log
- (void)info:(NSString *)text {
    if (!text.length) {
        return;
    }
    
    [self.messageVC appendInfo:text];
}

- (void)alert:(NSString *)text {
    if (!text.length) {
        return;
    }
    
    [self.messageVC appendError:text];
}

#pragma mark - Others
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.orientation = UIInterfaceOrientationMaskAll;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.orientation = UIInterfaceOrientationMaskPortrait;
}

#pragma mark - OWTConferenceClientDelegate
-(void)conferenceClient:(OWTConferenceClient *)client didAddStream:(OWTRemoteStream *)stream{
  NSLog(@"AppDelegate on stream added");
  stream.delegate=self;
  if ([stream isKindOfClass:[OWTRemoteMixedStream class]]) {
    _mixedStream = (OWTRemoteMixedStream *)stream;
    _mixedStream.delegate = self;
  }
  if(stream.source.video == OWTVideoSourceInfoScreenCast){
    _screenStream = stream;
  }
  [self.remoteStreams addObject:stream];
  //[[NSNotificationCenter defaultCenter] postNotificationName:@"OnStreamAdded" object:self userInfo:[NSDictionary dictionaryWithObject:stream forKey:@"stream"]];
}

-(void)conferenceClientDidDisconnect:(OWTConferenceClient *)client{
  NSLog(@"Server disconnected");
  _mixedStream = nil;
}

-(void)conferenceClient:(OWTConferenceClient *)client didReceiveMessage:(NSString *)message from:(NSString *)senderId{
  NSLog(@"AppDelegate received message: %@, from %@", message, senderId);
}

- (void)conferenceClient:(OWTConferenceClient *)client didAddParticipant:(OWTConferenceParticipant *)user{
  user.delegate=self;
  NSLog(@"A new participant joined the meeting.");
}

#pragma mark - OWTRemoteStreamDelegate
- (void)streamDidEnd:(nonnull OWTRemoteStream *)stream {
    
}

- (void)streamDidMute:(nonnull OWTRemoteStream *)stream trackKind:(OWTTrackKind)kind {
    
}

- (void)streamDidUnmute:(nonnull OWTRemoteStream *)stream trackKind:(OWTTrackKind)kind {
    
}

- (void)streamDidUpdate:(nonnull OWTRemoteStream *)stream {
    
}

- (void)streamDidChangeActiveInput:(nonnull NSString *)activeAudioInputStreamId {
    
}

- (void)streamDidChangeVideoLayout:(nonnull OWTRemoteMixedStream *)stream {
    
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    
}

/*- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}

- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
    
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
    
}

- (void)setNeedsFocusUpdate {
    
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    
}

- (void)updateFocusIfNeeded {
    
}*/

@end
