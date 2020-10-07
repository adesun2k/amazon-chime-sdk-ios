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
    public let timestamp: Int

    /// Width of video stream content
    public let rotation: Int

    /// Height of video stream content
    public let buffer: VideoFrameBuffer

    public init(width: Int, height: Int, timestamp: Int, rotation: Int, buffer: VideoFrameBuffer) {
        self.width = width
        self.height = height
        self.timestamp = timestamp
        self.rotation = rotation
        self.buffer = buffer
    }
}
