//
//  VideoSourceObserver.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreMedia

/// `VideoSourceObserver` handles events related to `VideoSource`.
@objc public protocol VideoSink {
    /// Called whenever a new attendee starts sharing the video
    ///
    /// Note: this callback will be called on main thread.
    ///
    /// - Parameters:
    ///   - tileState: video tile state associated with this attendee
    func onVideoFrameReceived(frame: VideoFrame?)
}
