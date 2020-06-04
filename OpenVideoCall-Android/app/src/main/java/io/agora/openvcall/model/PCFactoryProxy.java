/*
 * Copyright (C) 2018 Intel Corporation
 * SPDX-License-Identifier: Apache-2.0
 */
package io.agora.openvcall.model;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;

import org.webrtc.DefaultVideoDecoderFactory;
import org.webrtc.DefaultVideoEncoderFactory;
import org.webrtc.PeerConnectionFactory;
import org.webrtc.ThreadUtils;
import org.webrtc.VideoDecoderFactory;
import org.webrtc.VideoEncoderFactory;
import org.webrtc.audio.AudioDeviceModule;
import org.webrtc.audio.JavaAudioDeviceModule;

import static io.agora.openvcall.model.ContextInitialization.context;
import static io.agora.openvcall.model.ContextInitialization.localContext;
import static io.agora.openvcall.model.ContextInitialization.remoteContext;

final class PCFactoryProxy {
    private static final String TAG = "PCFactoryProxy";

    static int networkIgnoreMask = 0;
    // Enable H.264 high profile by default.
    static String fieldTrials = "/WebRTC-H264HighProfile/Enabled/";
    private static final ThreadUtils.ThreadChecker mThreadChecker = new ThreadUtils.ThreadChecker();

    static VideoEncoderFactory encoderFactory = null;
    static VideoDecoderFactory decoderFactory = null;
    static AudioDeviceModule adm = null;
    @SuppressLint("StaticFieldLeak")
    private static PeerConnectionFactory peerConnectionFactory;

    static PeerConnectionFactory instance() {
        if (peerConnectionFactory == null) {
            PeerConnectionFactory.InitializationOptions initializationOptions =
                    PeerConnectionFactory.InitializationOptions.builder(context)
                            .setFieldTrials(fieldTrials)
                            .createInitializationOptions();
            PeerConnectionFactory.initialize(initializationOptions);
            PeerConnectionFactory.Options options = new PeerConnectionFactory.Options();
            options.networkIgnoreMask = networkIgnoreMask;
            AudioDeviceModule adm = createJavaAudioDevice(context);
            peerConnectionFactory = PeerConnectionFactory.builder()
                    .setOptions(options)
                    .setAudioDeviceModule(adm)
                    .setVideoEncoderFactory(
                            encoderFactory == null
                                    ? new DefaultVideoEncoderFactory(localContext, true, true)
                                    : encoderFactory)
                    .setVideoDecoderFactory(
                            decoderFactory == null
                                    ? new DefaultVideoDecoderFactory(remoteContext)
                                    : decoderFactory)
                    .createPeerConnectionFactory();
        }
        return peerConnectionFactory;
    }

    private static AudioDeviceModule createJavaAudioDevice(Context appContext) {
        Log.d(TAG, "createJavaAudioDevice()");
        mThreadChecker.checkIsOnValidThread();
        // Enable/disable OpenSL ES playback.
        // Set audio record error callbacks.
        JavaAudioDeviceModule.AudioRecordErrorCallback audioRecordErrorCallback =
                new JavaAudioDeviceModule.AudioRecordErrorCallback() {
                    @Override
                    public void onWebRtcAudioRecordInitError(String errorMessage) {
                        Log.e(TAG, "onWebRtcAudioRecordInitError: " + errorMessage);
                    }

                    @Override
                    public void onWebRtcAudioRecordStartError(
                            JavaAudioDeviceModule.AudioRecordStartErrorCode errorCode, String errorMessage) {
                        Log.e(TAG, "onWebRtcAudioRecordStartError: " + errorCode + ". " + errorMessage);
                    }

                    @Override
                    public void onWebRtcAudioRecordError(String errorMessage) {
                        Log.e(TAG, "onWebRtcAudioRecordError: " + errorMessage);
                    }
                };

        JavaAudioDeviceModule.AudioTrackErrorCallback audioTrackErrorCallback =
                new JavaAudioDeviceModule.AudioTrackErrorCallback() {
                    @Override
                    public void onWebRtcAudioTrackInitError(String errorMessage) {
                        Log.e(TAG, "onWebRtcAudioTrackInitError: " + errorMessage);
                    }

                    @Override
                    public void onWebRtcAudioTrackStartError(
                            JavaAudioDeviceModule.AudioTrackStartErrorCode errorCode, String errorMessage) {
                        Log.e(TAG, "onWebRtcAudioTrackStartError: " + errorCode + ". " + errorMessage);
                    }

                    @Override
                    public void onWebRtcAudioTrackError(String errorMessage) {
                        Log.e(TAG, "onWebRtcAudioTrackError: " + errorMessage);
                    }
                };

        return JavaAudioDeviceModule.builder(appContext)
                .setAudioRecordErrorCallback(audioRecordErrorCallback)
                .setAudioTrackErrorCallback(audioTrackErrorCallback)
                .createAudioDeviceModule();
    }
}
