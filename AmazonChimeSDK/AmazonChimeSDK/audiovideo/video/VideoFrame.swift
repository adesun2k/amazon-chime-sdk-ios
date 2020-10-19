//
//  VideoFrame.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `VideoFrame` is a class which contains a `VideoFrameBuffer` and metadata necessary for transmission.
@objcMembers public class VideoFrame: NSObject {
    /// Width of the video frame in pixels.
    public let width: Int

    /// Height of the video frame in pixels.
    public let height: Int

    /// Timestamp in nanoseconds at which the video frame was captured from some system monotonic clock.
    public let timestampNs: Int64

    /// Rotation of the video frame buffer in degrees clockwise from intended viewing horizon.
    public let rotation: VideoRotation

    /// Object containing actual video frame data in some form.
    public let buffer: VideoFrameBuffer

    public init(timestampNs: Int64, rotation: VideoRotation, buffer: VideoFrameBuffer) {
        self.width = buffer.width()
        self.height = buffer.height()
        self.timestampNs = timestampNs
        self.rotation = rotation
        self.buffer = buffer
    }
}
