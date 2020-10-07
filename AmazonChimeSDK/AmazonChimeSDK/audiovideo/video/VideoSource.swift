//
//  VideoSource.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `VideoTile` is a tile that binds video render view to diplay the frame into the view.
@objc public protocol VideoSource {
    /// Subscribe to Video Source events with an `VideoSourceObserver`.
    ///
    /// - Parameter observer: The observer to subscribe to events with
    func addVideoSink(sink: VideoSink)

    /// Unsubscribes from Video Tile events by removing specified `VideoSourceObserver`.
    ///
    /// - Parameter observer: The observer to unsubscribe from events with
    func removeVideoSink(sink: VideoSink)
}
