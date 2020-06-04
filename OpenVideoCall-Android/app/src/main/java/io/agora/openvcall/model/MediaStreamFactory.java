/*
 * Copyright (C) 2018 Intel Corporation
 * SPDX-License-Identifier: Apache-2.0
 */
package io.agora.openvcall.model;


import android.util.Log;

import org.webrtc.AudioSource;
import org.webrtc.MediaStream;
import org.webrtc.SurfaceTextureHelper;
import org.webrtc.VideoSource;
import org.webrtc.VideoTrack;

import java.util.HashMap;
import java.util.UUID;

import static io.agora.openvcall.model.CheckCondition.RCHECK;
import static io.agora.openvcall.model.ContextInitialization.localContext;


final class MediaStreamFactory {

    private static MediaStreamFactory instance;
    private final HashMap<String, VideoSource> unsharedVideoSources = new HashMap<>();
    private AudioSource sharedAudioSource;
    private int audioSourceRef = 0;

    private MediaStreamFactory() {
    }

    synchronized static MediaStreamFactory instance() {
        if (instance == null) {
            instance = new MediaStreamFactory();
        }
        return instance;
    }

    MediaStream createMediaStream(VideoCapturer videoCapturer,
            MediaConstraints.AudioTrackConstraints audioMediaConstraints) {
        RCHECK(videoCapturer != null || audioMediaConstraints != null);

        String label = UUID.randomUUID().toString();
        MediaStream mediaStream = PCFactoryProxy.instance().createLocalMediaStream(label);

        if (videoCapturer != null) {
            VideoSource videoSource = PCFactoryProxy.instance().createVideoSource(
                    videoCapturer.isScreencast());
            SurfaceTextureHelper helper = SurfaceTextureHelper.create("CT", localContext);
            videoCapturer.initialize(helper, ContextInitialization.context,
                    videoSource.getCapturerObserver());
            Log.e("MediaStreamFactory", "=====startCapture==========");
            videoCapturer.startCapture(videoCapturer.getWidth(),
                    videoCapturer.getHeight(),
                    videoCapturer.getFps());
            VideoTrack videoTrack = PCFactoryProxy.instance().createVideoTrack(label + "v0",
                    videoSource);
            videoTrack.setEnabled(true);
            mediaStream.addTrack(videoTrack);
            unsharedVideoSources.put(label, videoSource);
        }

        if (audioMediaConstraints != null) {
            if (sharedAudioSource == null) {
                sharedAudioSource = PCFactoryProxy.instance().createAudioSource(
                        audioMediaConstraints.convertToWebRTCConstraints());
            }
            audioSourceRef++;
            mediaStream.addTrack(
                    PCFactoryProxy.instance().createAudioTrack(label + "a0", sharedAudioSource));
        }

        return mediaStream;
    }

    void onAudioSourceRelease() {
        //DCHECK(audioSourceRef > 0);
        if (--audioSourceRef == 0) {
            sharedAudioSource.dispose();
            sharedAudioSource = null;
        }
    }

    void onVideoSourceRelease(String label) {
        //DCHECK(unsharedVideoSources.containsKey(label));
        VideoSource videoSource = unsharedVideoSources.get(label);
        unsharedVideoSources.remove(label);
        videoSource.dispose();
    }

}
