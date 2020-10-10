//
//  VideoFrameBuffer.swift
//  AmazonChimeSDK
//
//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `VideoTile` is a tile that binds video render view to diplay the frame into the view.
@objc public protocol VideoFrameBuffer {
    /// Subscribe to Video Source events with an `VideoSourceObserver`.
    ///
    /// - Parameter observer: The observer to subscribe to events with
    func width() -> Int

    /// Subscribe to Video Source events with an `VideoSourceObserver`.
    ///
    /// - Parameter observer: The observer to subscribe to events with
    func height() -> Int
}
