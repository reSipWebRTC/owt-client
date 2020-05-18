//
//  VideoSession.m
//  OpenVideoCall
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import "VideoSession.h"

@implementation VideoSession
- (void)setIsVideoMuted:(BOOL)isVideoMuted {
    _isVideoMuted = isVideoMuted;
    ((VideoView *)self.hostingView).isVideoMuted = isVideoMuted;
}

+ (instancetype)localSession {
    return [[VideoSession alloc] initWithUid:nil];
}

- (instancetype)initWithUid:(NSString*)streamId {
    if (self = [super init]) {
        self.streamId = streamId;
        
        self.hostingView = [[VideoView alloc] initWithStreamId:streamId];
        self.hostingView.translatesAutoresizingMaskIntoConstraints = NO;
        
        /*self.canvas = [[AgoraRtcVideoCanvas alloc] init];
        self.canvas.uid = uid;
        self.canvas.view = ((VideoView *)self.hostingView).videoView;
        self.canvas.renderMode = AgoraVideoRenderModeHidden;*/
    }
    return self;
}


- (void)updateMediaInfo:(CGSize)resolution fps:(NSInteger)fps {
    MediaInfo *info = [[MediaInfo alloc] initWithDimension:resolution fps:fps];
    [((VideoView *)self.hostingView) updateInfo:info];
}

@end
