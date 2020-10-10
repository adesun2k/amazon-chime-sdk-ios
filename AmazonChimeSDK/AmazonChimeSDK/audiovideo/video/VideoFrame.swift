//
//  VideoFrame.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `VideoTileState` encapsulates the state of a `VideoTile`.
@objcMembers public class VideoFrame: NSObject {
    /// Unique Id associated with this tile
    public let width: Int

    /// Id of the user associated with this tile
    public let height: Int

    /// Width of video stream content
    public let timestampNs: Int64

    /// Width of video stream content
    public let rotation: VideoRotation

    /// Height of video stream content
    public let buffer: VideoFrameBuffer

    public init(timestampNs: Int64, rotation: VideoRotation, buffer: VideoFrameBuffer) {
        self.width = buffer.width()
        self.height = buffer.height()
        self.timestampNs = timestampNs
        self.rotation = rotation
        self.buffer = buffer
    }
}
