//
//  VideoSinkgit .swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import CoreMedia
import Foundation

/// A `VideoSink` consumes video frames, typically from a `VideoSource`.
@objc public protocol VideoSink {
    /// Receive a video frame from some upstream source.
    ///
    /// - Parameters:
    ///   - frame: New video frame to consume
    func onVideoFrameReceived(frame: VideoFrame)
}
