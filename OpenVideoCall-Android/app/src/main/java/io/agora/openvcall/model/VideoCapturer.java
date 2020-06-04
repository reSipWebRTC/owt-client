/*
 * Copyright (C) 2018 Intel Corporation
 * SPDX-License-Identifier: Apache-2.0
 */
package io.agora.openvcall.model;

/**
 * Interface for VideoCapturer from which LocalStream gets video frames.
 */
public interface VideoCapturer extends org.webrtc.VideoCapturer {
    /**
     * Width of the video frames generated by the VideoCapturer.
     *
     * @return width
     */
    int getWidth();

    /**
     * Height of the video frames generated by the VideoCapturer.
     *
     * @return height
     */
    int getHeight();

    /**
     * Fps of the video capturer.
     *
     * @return fps
     */
    int getFps();

    Stream.StreamSourceInfo.VideoSourceInfo getVideoSource();
}
